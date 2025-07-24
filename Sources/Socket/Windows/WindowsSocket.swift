//
//  WindowsSocket.swift
//  
//
//  Windows-specific socket operations
//

#if os(Windows)
import SystemPackage
import WinSDK

/// Windows-specific socket operations
///
/// This type provides low-level Windows socket operations that directly use
/// Winsock2 APIs without POSIX emulation. All operations handle Windows-specific
/// error codes and lifecycle requirements.
///
/// ## Topics
///
/// ### Creating Sockets
/// - ``socket(_:_:_:)``
/// - ``close(_:)``
///
/// ### Socket Configuration  
/// - ``bind(_:_:)``
/// - ``listen(_:_:)``
/// - ``setNonBlocking(_:)``
///
/// ### Socket Options
/// - ``setSocketOption(_:level:option:value:)``
/// - ``getSocketOption(_:level:option:type:)``
///
/// ### Connection Management
/// - ``connect(_:_:)``
/// - ``accept(_:)``
/// - ``shutdown(_:_:)``
///
/// ### Socket Information
/// - ``getsockname(_:)``
/// - ``getpeername(_:)``
internal enum WindowsSocket {
    
    /// Create a new socket
    ///
    /// Creates an endpoint for communication using Windows Sockets 2 (Winsock2).
    /// This function automatically initializes Winsock if needed.
    ///
    /// - Parameters:
    ///   - domain: The address family specification:
    ///     - `AF_INET` for IPv4
    ///     - `AF_INET6` for IPv6  
    ///     - `AF_BTH` for Bluetooth (Windows-specific)
    ///   - type: The socket type specification:
    ///     - `SOCK_STREAM` for TCP
    ///     - `SOCK_DGRAM` for UDP
    ///     - `SOCK_RAW` for raw sockets (requires admin)
    ///   - protocol: The protocol to use, or 0 for default based on type
    /// - Returns: A valid socket descriptor
    /// - Throws: `Errno` with Windows-specific error codes:
    ///   - `.addressFamilyNotSupported` if the address family is not available
    ///   - `.protocolNotSupported` if the protocol is not available
    ///   - `.tooManyOpenFiles` if the socket limit is reached
    ///
    /// - Note: On Windows, socket descriptors are `SOCKET` (UInt64) handles,
    ///   not POSIX file descriptors.
    static func socket(
        _ domain: CInt,
        _ type: CInt,
        _ protocol: CInt
    ) throws -> SocketDescriptor {
        // Ensure Windows sockets are initialized
        try ensureWindowsSocketsInitialized()
        
        let result = windowsSocketResult(
            WinSDK.socket(domain, type, `protocol`)
        )
        
        guard result != INVALID_SOCKET else {
            throw Errno.windowsCurrent
        }
        
        return SocketDescriptor(rawValue: result)
    }
    
    /// Close a socket
    ///
    /// - Parameter socket: The socket to close
    /// - Throws: Errno on failure
    static func close(_ socket: SocketDescriptor) throws {
        let result = windowsSocketResult(
            closesocket(socket.rawValue)
        )
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
    }
    
    /// Bind a socket to an address
    ///
    /// - Parameters:
    ///   - socket: The socket to bind
    ///   - address: The address to bind to
    /// - Throws: Errno on failure
    static func bind(
        _ socket: SocketDescriptor,
        _ address: any SocketAddress
    ) throws {
        try address.withUnsafePointer { addressPtr, addressLen in
            let result = windowsSocketResult(
                WinSDK.bind(
                    socket.rawValue,
                    addressPtr,
                    CInt(addressLen)
                )
            )
            
            guard result == 0 else {
                throw Errno.windowsCurrent
            }
        }
    }
    
    /// Listen for connections on a socket
    ///
    /// - Parameters:
    ///   - socket: The socket to listen on
    ///   - backlog: The maximum length of the pending connections queue
    /// - Throws: Errno on failure
    static func listen(
        _ socket: SocketDescriptor,
        _ backlog: CInt
    ) throws {
        let result = windowsSocketResult(
            WinSDK.listen(socket.rawValue, backlog)
        )
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
    }
    
    /// Accept a connection on a socket
    ///
    /// - Parameter socket: The listening socket
    /// - Returns: A tuple of the new socket and the client address
    /// - Throws: Errno on failure
    static func accept(
        _ socket: SocketDescriptor
    ) throws -> (SocketDescriptor, any SocketAddress) {
        var addressStorage = sockaddr_storage()
        var addressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
        
        let result = withUnsafeMutablePointer(to: &addressStorage) { storagePtr in
            storagePtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { addressPtr in
                windowsSocketResult(
                    WinSDK.accept(
                        socket.rawValue,
                        addressPtr,
                        &addressLength
                    )
                )
            }
        }
        
        guard result != INVALID_SOCKET else {
            throw Errno.windowsCurrent
        }
        
        let newSocket = SocketDescriptor(rawValue: result)
        // Convert sockaddr_storage to appropriate SocketAddress type
        let address: any SocketAddress = try withUnsafePointer(to: &addressStorage) { storagePtr in
            let socketPtr = UnsafeMutableRawPointer(mutating: storagePtr).assumingMemoryBound(to: CInterop.SocketAddress.self)
            
            // Determine address family and create appropriate type
            switch socketPtr.pointee.sa_family {
            case ADDRESS_FAMILY(AF_INET):
                return IPv4SocketAddress.withUnsafePointer(socketPtr)
            case ADDRESS_FAMILY(AF_INET6):
                return IPv6SocketAddress.withUnsafePointer(socketPtr)
            default:
                throw Errno.addressFamilyNotSupported
            }
        }
        
        return (newSocket, address)
    }
    
    /// Connect a socket to an address
    ///
    /// - Parameters:
    ///   - socket: The socket to connect
    ///   - address: The address to connect to
    /// - Throws: Errno on failure
    static func connect(
        _ socket: SocketDescriptor,
        _ address: any SocketAddress
    ) throws {
        try address.withUnsafePointer { addressPtr, addressLen in
            let result = windowsSocketResult(
                WinSDK.connect(
                    socket.rawValue,
                    addressPtr,
                    CInt(addressLen)
                )
            )
            
            guard result == 0 else {
                throw Errno.windowsCurrent
            }
        }
    }
    
    /// Set socket to non-blocking mode
    ///
    /// Uses Windows `ioctlsocket` with `FIONBIO` to enable non-blocking I/O.
    /// This is the Windows equivalent of `fcntl(fd, F_SETFL, O_NONBLOCK)`.
    ///
    /// - Parameter socket: The socket to modify
    /// - Throws: `Errno` if the operation fails
    ///
    /// - Important: Once set to non-blocking, socket operations may return
    ///   `WSAEWOULDBLOCK` which maps to `Errno.wouldBlock`.
    static func setNonBlocking(_ socket: SocketDescriptor) throws {
        var mode: u_long = 1
        let result = ioctlsocket(socket.rawValue, FIONBIO, &mode)
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
    }
    
    /// Set socket option
    ///
    /// - Parameters:
    ///   - socket: The socket
    ///   - level: The protocol level
    ///   - option: The option name
    ///   - value: The option value
    /// - Throws: Errno on failure
    static func setSocketOption<T>(
        _ socket: SocketDescriptor,
        level: CInt,
        option: CInt,
        value: T
    ) throws {
        var optionValue = value
        let result = withUnsafePointer(to: &optionValue) { ptr in
            windowsSocketResult(
                setsockopt(
                    socket.rawValue,
                    level,
                    option,
                    ptr.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<T>.size) { $0 },
                    CInt(MemoryLayout<T>.size)
                )
            )
        }
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
    }
    
    /// Get socket option
    ///
    /// - Parameters:
    ///   - socket: The socket
    ///   - level: The protocol level
    ///   - option: The option name
    ///   - type: The expected value type
    /// - Returns: The option value
    /// - Throws: Errno on failure
    static func getSocketOption<T>(
        _ socket: SocketDescriptor,
        level: CInt,
        option: CInt,
        type: T.Type
    ) throws -> T {
        let value = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer { value.deallocate() }
        
        var size = CInt(MemoryLayout<T>.size)
        
        let result = windowsSocketResult(
            getsockopt(
                socket.rawValue,
                level,
                option,
                value.withMemoryRebound(to: CChar.self, capacity: 1) { $0 },
                &size
            )
        )
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
        
        return value.pointee
    }
    
    /// Get socket name (local address)
    ///
    /// - Parameter socket: The socket
    /// - Returns: The local address
    /// - Throws: Errno on failure
    static func getsockname(_ socket: SocketDescriptor) throws -> any SocketAddress {
        var addressStorage = sockaddr_storage()
        var addressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
        
        let result = withUnsafeMutablePointer(to: &addressStorage) { storagePtr in
            storagePtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { addressPtr in
                windowsSocketResult(
                    WinSDK.getsockname(
                        socket.rawValue,
                        addressPtr,
                        &addressLength
                    )
                )
            }
        }
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
        
        // Convert sockaddr_storage to appropriate SocketAddress type
        return try withUnsafePointer(to: &addressStorage) { storagePtr in
            let socketPtr = UnsafeMutableRawPointer(mutating: storagePtr).assumingMemoryBound(to: CInterop.SocketAddress.self)
            
            // Determine address family and create appropriate type
            switch socketPtr.pointee.sa_family {
            case ADDRESS_FAMILY(AF_INET):
                return IPv4SocketAddress.withUnsafePointer(socketPtr)
            case ADDRESS_FAMILY(AF_INET6):
                return IPv6SocketAddress.withUnsafePointer(socketPtr)
            default:
                throw Errno.addressFamilyNotSupported
            }
        }
    }
    
    /// Get peer name (remote address)
    ///
    /// - Parameter socket: The socket
    /// - Returns: The remote address
    /// - Throws: Errno on failure
    static func getpeername(_ socket: SocketDescriptor) throws -> any SocketAddress {
        var addressStorage = sockaddr_storage()
        var addressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
        
        let result = withUnsafeMutablePointer(to: &addressStorage) { storagePtr in
            storagePtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { addressPtr in
                windowsSocketResult(
                    WinSDK.getpeername(
                        socket.rawValue,
                        addressPtr,
                        &addressLength
                    )
                )
            }
        }
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
        
        // Convert sockaddr_storage to appropriate SocketAddress type
        return try withUnsafePointer(to: &addressStorage) { storagePtr in
            let socketPtr = UnsafeMutableRawPointer(mutating: storagePtr).assumingMemoryBound(to: CInterop.SocketAddress.self)
            
            // Determine address family and create appropriate type
            switch socketPtr.pointee.sa_family {
            case ADDRESS_FAMILY(AF_INET):
                return IPv4SocketAddress.withUnsafePointer(socketPtr)
            case ADDRESS_FAMILY(AF_INET6):
                return IPv6SocketAddress.withUnsafePointer(socketPtr)
            default:
                throw Errno.addressFamilyNotSupported
            }
        }
    }
    
    /// Shutdown socket operations
    ///
    /// - Parameters:
    ///   - socket: The socket
    ///   - how: Which operations to shutdown (SD_RECEIVE, SD_SEND, SD_BOTH)
    /// - Throws: Errno on failure
    static func shutdown(_ socket: SocketDescriptor, _ how: CInt) throws {
        let result = windowsSocketResult(
            WinSDK.shutdown(socket.rawValue, how)
        )
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
    }
}

// MARK: - Windows Socket Constants

extension WindowsSocket {
    /// Shutdown receive operations
    static let SD_RECEIVE: CInt = 0
    
    /// Shutdown send operations
    static let SD_SEND: CInt = 1
    
    /// Shutdown both send and receive operations
    static let SD_BOTH: CInt = 2
}

#endif