//
//  IOCPSocketManager.swift
//  
//
//  Created for Windows IOCP implementation
//

#if os(Windows)
import Foundation
import SystemPackage
import WinSDK

/// Socket manager implementation using Windows I/O Completion Ports (IOCP)
///
/// This implementation provides high-performance asynchronous I/O operations
/// on Windows by leveraging IOCP instead of the polling-based approach used
/// on POSIX systems.
///
/// ## Overview
/// 
/// I/O Completion Ports (IOCP) is Windows' high-performance I/O model that uses
/// a thread pool to handle asynchronous I/O completions. This provides better
/// scalability than traditional select/poll mechanisms.
///
/// ## Usage
///
/// ```swift
/// let manager = try IOCPSocketManager(workerThreadCount: 0)
/// let socket = try await Socket(.tcp4, manager: manager)
/// ```
///
/// ## Performance
///
/// IOCP offers several performance advantages:
/// - Efficient thread pool management
/// - Zero-copy operations where possible  
/// - Scales to thousands of concurrent connections
/// - Low CPU overhead compared to polling
///
/// - Note: This is an experimental implementation. Some features like
///   AcceptEx and ConnectEx are not yet fully implemented.
@available(Windows 10.0.22000, *)
public actor IOCPSocketManager: SocketManager {
    
    /// The I/O Completion Port handle
    private let completionPort: HANDLE
    
    /// Active socket registrations
    private var sockets: [SocketDescriptor: SocketRegistration] = [:]
    
    /// Worker task that processes IOCP completions
    private var workerTask: Task<Void, Never>?
    
    /// Event continuation for delivering socket events
    public let events: AsyncStream<Socket.Event>
    private let eventContinuation: AsyncStream<Socket.Event>.Continuation
    
    /// Number of worker threads for IOCP
    private let workerThreadCount: Int
    
    /// Logger for debugging
    public var log: (@Sendable (String) -> ())?
    
    /// IOCP operation types
    private enum OperationType: UInt32 {
        case read = 0
        case write = 1
        case accept = 2
        case connect = 3
        case sendTo = 4
        case recvFrom = 5
    }
    
    /// Per-socket registration data
    private struct SocketRegistration {
        let socket: SocketDescriptor
        var readContinuation: AsyncStream<Socket.Event>.Continuation?
        var writeContinuation: AsyncStream<Socket.Event>.Continuation?
        var pendingOperations: Set<OperationType> = []
        
        // Accept operation continuations
        var acceptContinuation: CheckedContinuation<SocketDescriptor, Error>?
        var acceptAddressContinuation: CheckedContinuation<(SocketDescriptor, any SocketAddress), Error>?
        
        // Connect operation continuation
        var connectContinuation: CheckedContinuation<Void, Error>?
        
        // UDP operation continuations
        var sendToContinuation: CheckedContinuation<Int, Error>?
        var recvFromContinuation: CheckedContinuation<(Data, any SocketAddress), Error>?
        var recvFromAddressType: Any.Type?
    }
    
    /// IOCP per-I/O data structure
    private class IOData {
        var overlapped: OVERLAPPED = OVERLAPPED()
        let operation: OperationType
        let socket: SocketDescriptor
        var buffer: UnsafeMutablePointer<UInt8>?
        var bufferSize: Int = 0
        
        // Accept-specific data
        var acceptSocket: SocketDescriptor?
        var acceptAddressType: Any.Type?
        
        // UDP operation data
        var udpAddress: (any SocketAddress)?
        var udpAddressBuffer: UnsafeMutableRawPointer?
        var udpAddressLength: UInt32 = 0
        
        init(operation: OperationType, socket: SocketDescriptor) {
            self.operation = operation
            self.socket = socket
        }
        
        deinit {
            buffer?.deallocate()
            udpAddressBuffer?.deallocate()
        }
    }
    
    /// Initialize the IOCP socket manager
    ///
    /// Creates a new I/O Completion Port and starts the worker task for processing
    /// completion notifications.
    ///
    /// - Parameter workerThreadCount: Number of worker threads for the completion
    ///   port. Pass 0 to use the number of CPUs (recommended). Higher values may
    ///   be useful for I/O-bound workloads.
    /// - Throws: `Errno` if the completion port cannot be created or if Windows
    ///   sockets cannot be initialized.
    ///
    /// - Important: Only one IOCP manager should be created per process for
    ///   optimal performance.
    public init(
        workerThreadCount: Int = 0,
        log: (@Sendable (String) -> ())? = nil
    ) throws {
        self.workerThreadCount = workerThreadCount
        self.log = log
        
        // Initialize Windows sockets
        try ensureWindowsSocketsInitialized()
        
        // Create I/O Completion Port
        let port = CreateIoCompletionPort(INVALID_HANDLE_VALUE, nil, 0, DWORD(workerThreadCount))
        guard port != nil else {
            throw Errno.fromLastError()
        }
        self.completionPort = port!
        
        // Create event stream
        (self.events, self.eventContinuation) = AsyncStream<Socket.Event>.makeStream()
        
        // Start worker task later to avoid accessing stored properties before initialization is complete
        Task { [weak self] in
            guard let self = self else { return }
            await self.startWorker()
        }
    }
    
    deinit {
        workerTask?.cancel()
        eventContinuation.finish()
        // Note: CloseHandle must be called from an async context
        // The caller is responsible for calling cleanup() before releasing the manager
    }
    
    /// Cleanup method to be called before releasing the manager
    public func cleanup() {
        workerTask?.cancel()
        CloseHandle(completionPort)
    }
    
    /// Start the worker task
    private func startWorker() {
        self.workerTask = Task {
            await self.runWorker()
        }
    }
    
    /// Register a socket for event monitoring
    ///
    /// Associates the socket with the I/O Completion Port to enable asynchronous
    /// operations. After registration, the socket can be used for async I/O.
    ///
    /// - Parameter socket: The socket descriptor to register
    /// - Throws: `Errno` if the socket cannot be associated with the completion port
    public func register(_ socket: SocketDescriptor) async throws {
        // Associate socket with completion port
        let result = CreateIoCompletionPort(
            HANDLE(bitPattern: Int(socket.rawValue))!,
            completionPort,
            ULONG_PTR(socket.rawValue),
            0
        )
        
        guard result != nil else {
            throw Errno.fromLastError()
        }
        
        // Add to our tracking
        sockets[socket] = SocketRegistration(socket: socket)
    }
    
    /// Unregister a socket from event monitoring  
    ///
    /// Removes the socket from tracking and cancels any pending I/O operations.
    /// This is automatically called when a socket is closed.
    ///
    /// - Parameter socket: The socket descriptor to unregister
    /// - Throws: `Errno` if there are errors during cleanup
    public func unregister(_ socket: SocketDescriptor) async throws {
        // Remove from tracking
        if let registration = sockets.removeValue(forKey: socket) {
            // Cancel any pending operations
            cancelPendingOperations(for: socket)
            
            // Close continuations
            registration.readContinuation?.finish()
            registration.writeContinuation?.finish()
        }
    }
    
    /// Submit a read operation for a socket
    public func submitRead(for socket: SocketDescriptor, buffer: UnsafeMutableRawBufferPointer) async throws {
        guard var registration = sockets[socket] else {
            throw Errno.badFileDescriptor
        }
        
        // Create IOCP data for this operation
        let ioData = IOData(operation: .read, socket: socket)
        ioData.buffer = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
        ioData.bufferSize = buffer.count
        
        // Create WSABUF
        var wsaBuf = WSABUF()
        wsaBuf.len = ULONG(buffer.count)
        wsaBuf.buf = buffer.baseAddress!.assumingMemoryBound(to: CChar.self)
        
        var flags: DWORD = 0
        var bytesReceived: DWORD = 0
        
        // Submit the read operation
        let result = withUnsafePointer(to: &ioData.overlapped) { overlappedPtr in
            WSARecv(
                socket.rawValue,
                &wsaBuf,
                1,
                &bytesReceived,
                &flags,
                UnsafeMutablePointer(mutating: overlappedPtr),
                nil
            )
        }
        
        if result == SOCKET_ERROR {
            let error = WSAGetLastError()
            if error != WSA_IO_PENDING {
                throw Errno(rawValue: error)
            }
        }
        
        // Track pending operation
        registration.pendingOperations.insert(.read)
        sockets[socket] = registration
    }
    
    /// Submit a write operation for a socket
    public func submitWrite(for socket: SocketDescriptor, buffer: UnsafeRawBufferPointer) async throws {
        guard var registration = sockets[socket] else {
            throw Errno.badFileDescriptor
        }
        
        // Create IOCP data for this operation
        let ioData = IOData(operation: .write, socket: socket)
        
        // Create WSABUF
        var wsaBuf = WSABUF()
        wsaBuf.len = ULONG(buffer.count)
        wsaBuf.buf = UnsafeMutablePointer(mutating: buffer.baseAddress!.assumingMemoryBound(to: CChar.self))
        
        var bytesSent: DWORD = 0
        
        // Submit the write operation
        let result = withUnsafePointer(to: &ioData.overlapped) { overlappedPtr in
            WSASend(
                socket.rawValue,
                &wsaBuf,
                1,
                &bytesSent,
                0,
                UnsafeMutablePointer(mutating: overlappedPtr),
                nil
            )
        }
        
        if result == SOCKET_ERROR {
            let error = WSAGetLastError()
            if error != WSA_IO_PENDING {
                throw Errno(rawValue: error)
            }
        }
        
        // Track pending operation
        registration.pendingOperations.insert(.write)
        sockets[socket] = registration
    }
    
    /// Worker function that processes IOCP completions
    private func runWorker() async {
        while !Task.isCancelled {
            var bytesTransferred: DWORD = 0
            var completionKey: ULONG_PTR = 0
            var overlapped: LPOVERLAPPED? = nil
            
            // Wait for completion
            let result = GetQueuedCompletionStatus(
                completionPort,
                &bytesTransferred,
                &completionKey,
                &overlapped,
                INFINITE
            )
            
            guard result != false, let overlappedPtr = overlapped else {
                if GetLastError() == ERROR_ABANDONED_WAIT_0 {
                    // Completion port is closing
                    break
                }
                continue
            }
            
            // Get our IO data
            let ioData = Unmanaged<IOData>.fromOpaque(UnsafeRawPointer(overlappedPtr)).takeRetainedValue()
            
            // Process completion
            await processCompletion(
                ioData: ioData,
                bytesTransferred: Int(bytesTransferred),
                completionKey: SocketDescriptor(rawValue: SOCKET(completionKey))
            )
        }
    }
    
    /// Process a completed I/O operation
    private func processCompletion(ioData: IOData, bytesTransferred: Int, completionKey: SocketDescriptor) async {
        guard var registration = sockets[completionKey] else {
            return
        }
        
        // Remove from pending operations
        registration.pendingOperations.remove(ioData.operation)
        
        // Create event based on operation type
        let event: Socket.Event
        switch ioData.operation {
        case .read:
            if bytesTransferred == 0 {
                event = .error(Errno.connectionReset)
            } else {
                event = .didRead(bytesTransferred)
            }
            
        case .write:
            if bytesTransferred > 0 {
                event = .didWrite(bytesTransferred)
            } else {
                event = .error(Errno.connectionReset)
            }
            
        case .accept:
            // Accept completion - connection accepted
            if let acceptContinuation = registration.acceptContinuation {
                // Complete the accept operation
                if bytesTransferred >= 0, let acceptSocket = ioData.acceptSocket {
                    // Update SO_UPDATE_ACCEPT_CONTEXT (Windows-specific)
                    // This allows the accepted socket to inherit properties from the listening socket
                    #if os(Windows)
                    var listenSocket = completionKey.rawValue
                    let result = setsockopt(
                        acceptSocket.rawValue,
                        SOL_SOCKET,
                        SO_UPDATE_ACCEPT_CONTEXT,
                        &listenSocket,
                        CInt(MemoryLayout<SOCKET>.size)
                    )
                    if result == 0 {
                        acceptContinuation.resume(returning: acceptSocket)
                    } else {
                        acceptContinuation.resume(throwing: Errno.windowsCurrent)
                    }
                    #else
                    acceptContinuation.resume(returning: acceptSocket)
                    #endif
                } else {
                    acceptContinuation.resume(throwing: Errno.connectionReset)
                }
                registration.acceptContinuation = nil
                sockets[completionKey] = registration
                return // Don't send event for accept completions
            }
            event = .connection
            
        case .connect:
            // Connect completion - connection established
            if let connectContinuation = registration.connectContinuation {
                // Complete the connect operation
                if bytesTransferred >= 0 {
                    connectContinuation.resume()
                } else {
                    connectContinuation.resume(throwing: Errno.connectionRefused)
                }
                registration.connectContinuation = nil
                sockets[completionKey] = registration
                return // Don't send event for connect completions
            }
            event = .connection
            
        case .sendTo:
            // SendTo completion
            if let sendToContinuation = registration.sendToContinuation {
                if bytesTransferred > 0 {
                    sendToContinuation.resume(returning: bytesTransferred)
                } else {
                    sendToContinuation.resume(throwing: Errno.noBufferSpace)
                }
                registration.sendToContinuation = nil
                sockets[completionKey] = registration
                return // Don't send event for sendTo completions
            }
            event = .didWrite(bytesTransferred)
            
        case .recvFrom:
            // RecvFrom completion
            if let recvFromContinuation = registration.recvFromContinuation {
                if bytesTransferred > 0, let addressBuffer = ioData.udpAddressBuffer {
                    // Parse the address based on family
                    let sockaddrPtr = addressBuffer.assumingMemoryBound(to: sockaddr.self)
                    let family = Int32(sockaddrPtr.pointee.sa_family)
                    
                    let address: any SocketAddress
                    switch family {
                    case AF_INET:
                        let sockaddr_in = addressBuffer.assumingMemoryBound(to: CInterop.IPv4SocketAddress.self)
                        address = IPv4SocketAddress(sockaddr_in.pointee)
                    case AF_INET6:
                        let sockaddr_in6 = addressBuffer.assumingMemoryBound(to: CInterop.IPv6SocketAddress.self)
                        address = IPv6SocketAddress(sockaddr_in6.pointee)
                    default:
                        recvFromContinuation.resume(throwing: Errno.addressFamilyNotSupported)
                        registration.recvFromContinuation = nil
                        sockets[completionKey] = registration
                        return
                    }
                    
                    // Create data from buffer
                    let data = Data(bytes: ioData.buffer!, count: bytesTransferred)
                    recvFromContinuation.resume(returning: (data, address))
                } else {
                    recvFromContinuation.resume(throwing: Errno.noBufferSpace)
                }
                registration.recvFromContinuation = nil
                sockets[completionKey] = registration
                return // Don't send event for recvFrom completions
            }
            event = .didRead(bytesTransferred)
        }
        
        // Send event
        eventContinuation.yield(event)
        
        // Update registration
        sockets[completionKey] = registration
    }
    
    /// Cancel pending operations for a socket
    private func cancelPendingOperations(for socket: SocketDescriptor) {
        // CancelIoEx requires a file handle
        let handle = HANDLE(bitPattern: Int(socket.rawValue))!
        CancelIoEx(handle, nil)
    }
    
    // MARK: - SocketManager Protocol Implementation
    
    /// Add file descriptor
    public func add(_ fileDescriptor: SocketDescriptor) async -> Socket.Event.Stream {
        do {
            try await register(fileDescriptor)
        } catch {
            // Create a failing stream
            return AsyncStream<Socket.Event> { continuation in
                continuation.yield(.error(error))
                continuation.finish()
            }
        }
        
        // Create event stream for this socket
        return AsyncStream<Socket.Event> { continuation in
            Task {
                self.addEventContinuation(fileDescriptor, continuation)
            }
        }
    }
    
    /// Add event continuation for a socket
    private func addEventContinuation(_ socket: SocketDescriptor, _ continuation: AsyncStream<Socket.Event>.Continuation) {
        if var registration = sockets[socket] {
            registration.readContinuation = continuation
            registration.writeContinuation = continuation
            sockets[socket] = registration
        }
    }
    
    /// Remove file descriptor
    public func remove(_ fileDescriptor: SocketDescriptor) async {
        do {
            try await unregister(fileDescriptor)
        } catch {
            // Ignore errors during removal
        }
    }
    
    /// Write data to managed file descriptor
    public func write(_ data: Data, for fileDescriptor: SocketDescriptor) async throws -> Int {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
            data.withUnsafeBytes { buffer in
                _ = Task<Void, Error> {
                    do {
                        try await submitWrite(for: fileDescriptor, buffer: buffer)
                        continuation.resume(returning: data.count)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Read managed file descriptor
    public func read(_ length: Int, for fileDescriptor: SocketDescriptor) async throws -> Data {
        var buffer = Data(count: length)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            buffer.withUnsafeMutableBytes { bufferPtr in
                _ = Task<Void, Error> {
                    do {
                        try await submitRead(for: fileDescriptor, buffer: bufferPtr)
                        continuation.resume(returning: buffer)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Receive message
    public func receiveMessage(_ length: Int, for fileDescriptor: SocketDescriptor) async throws -> Data {
        // For now, just use read
        return try await read(length, for: fileDescriptor)
    }
    
    /// Receive message with address using WSARecvFrom for true async operation
    public func receiveMessage<Address: SocketAddress>(
        _ length: Int,
        fromAddressOf addressType: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (Data, Address) {
        // First perform the async recvfrom operation returning generic address
        let (data, genericAddress) = try await _receiveMessageGeneric(length, for: fileDescriptor)
        
        // Cast to specific address type
        guard let typedAddress = genericAddress as? Address else {
            throw Errno.addressFamilyNotSupported
        }
        
        return (data, typedAddress)
    }
    
    /// Internal generic receive implementation
    private func _receiveMessageGeneric(
        _ length: Int,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (Data, any SocketAddress) {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard var registration = self.sockets[fileDescriptor] else {
                    continuation.resume(throwing: Errno.badFileDescriptor)
                    return
                }
                
                // Create IOCP data for this operation
                let ioData = IOData(operation: .recvFrom, socket: fileDescriptor)
                ioData.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
                ioData.bufferSize = length
                
                // Allocate space for the address
                let addressSize = WindowsSocketExtensions.maxAddressSize()
                ioData.udpAddressBuffer = UnsafeMutableRawPointer.allocate(
                    byteCount: addressSize,
                    alignment: MemoryLayout<sockaddr>.alignment
                )
                ioData.udpAddressLength = UInt32(addressSize)
                
                // Store continuation
                registration.recvFromContinuation = continuation
                self.sockets[fileDescriptor] = registration
                
                // Create WSABUF
                var wsaBuf = WSABUF()
                wsaBuf.len = ULONG(length)
                wsaBuf.buf = ioData.buffer!.withMemoryRebound(to: CChar.self, capacity: length) { $0 }
                
                var flags: DWORD = 0
                var bytesReceived: DWORD = 0
                
                // Submit the receive operation
                let result = withUnsafeMutablePointer(to: &ioData.overlapped) { overlappedPtr in
                    WSARecvFrom(
                        fileDescriptor.rawValue,
                        &wsaBuf,
                        1,
                        &bytesReceived,
                        &flags,
                        ioData.udpAddressBuffer!.assumingMemoryBound(to: sockaddr.self),
                        &ioData.udpAddressLength,
                        overlappedPtr,
                        nil
                    )
                }
                
                if result == SOCKET_ERROR {
                    let error = WSAGetLastError()
                    if error != WSA_IO_PENDING {
                        registration.recvFromContinuation = nil
                        self.sockets[fileDescriptor] = registration
                        continuation.resume(throwing: Errno(rawValue: error))
                        return
                    }
                    // If WSA_IO_PENDING, the operation will complete asynchronously
                }
                
                // Keep IOData alive
                _ = Unmanaged.passRetained(ioData)
            }
        }
    }
    
    /// Send message
    public func sendMessage(_ data: Data, for fileDescriptor: SocketDescriptor) async throws -> Int {
        // For now, just use write
        return try await write(data, for: fileDescriptor)
    }
    
    /// Send message to address using WSASendTo for true async operation
    public func sendMessage<Address: SocketAddress>(
        _ data: Data,
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard var registration = self.sockets[fileDescriptor] else {
                    continuation.resume(throwing: Errno.badFileDescriptor)
                    return
                }
                
                // Create IOCP data for this operation
                let ioData = IOData(operation: .sendTo, socket: fileDescriptor)
                ioData.udpAddress = address
                
                // Create WSABUF
                var wsaBuf = WSABUF()
                wsaBuf.len = ULONG(data.count)
                
                // Keep data alive during the operation
                let dataHolder = data
                dataHolder.withUnsafeBytes { bytes in
                    wsaBuf.buf = UnsafeMutablePointer(mutating: bytes.baseAddress!.assumingMemoryBound(to: CChar.self))
                }
                
                // Store continuation
                registration.sendToContinuation = continuation
                self.sockets[fileDescriptor] = registration
                
                var bytesSent: DWORD = 0
                
                // Submit the send operation
                let result = address.withUnsafePointer { addressPtr, addressLen in
                    withUnsafeMutablePointer(to: &ioData.overlapped) { overlappedPtr in
                        WSASendTo(
                            fileDescriptor.rawValue,
                            &wsaBuf,
                            1,
                            &bytesSent,
                            0,
                            addressPtr,
                            Int32(addressLen),
                            overlappedPtr,
                            nil
                        )
                    }
                }
                
                if result == SOCKET_ERROR {
                    let error = WSAGetLastError()
                    if error != WSA_IO_PENDING {
                        registration.sendToContinuation = nil
                        self.sockets[fileDescriptor] = registration
                        continuation.resume(throwing: Errno(rawValue: error))
                        return
                    }
                    // If WSA_IO_PENDING, the operation will complete asynchronously
                }
                
                // Keep IOData and data alive
                _ = Unmanaged.passRetained(ioData)
                withExtendedLifetime(dataHolder) {}
            }
        }
    }
    
    /// Accept new socket using AcceptEx for true async operation
    public func accept(for fileDescriptor: SocketDescriptor) async throws -> SocketDescriptor {
        // Create accept socket
        let acceptSocket = try WindowsSocket.socket(AF_INET, SOCK_STREAM, 0)
        
        do {
            // Register the accept socket with IOCP
            try await register(acceptSocket)
            
            // Load AcceptEx function
            let acceptEx = try await WindowsSocketExtensions.shared.getAcceptEx(socket: fileDescriptor.rawValue)
            
            // Set up continuation
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    guard var registration = self.sockets[fileDescriptor] else {
                        continuation.resume(throwing: Errno.badFileDescriptor)
                        return
                    }
                    
                    // Allocate buffer for AcceptEx inside the Task
                    let bufferSize = WindowsSocketExtensions.acceptExBufferSize(addressFamily: .ipv4)
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                    
                    // Create IOData for this operation
                    let ioData = IOData(operation: .accept, socket: fileDescriptor)
                    ioData.buffer = buffer
                    ioData.bufferSize = bufferSize
                    ioData.acceptSocket = acceptSocket
                    
                    registration.acceptContinuation = continuation
                    self.sockets[fileDescriptor] = registration
                    
                    // Prepare overlapped structure
                    let overlappedPtr = withUnsafeMutablePointer(to: &ioData.overlapped) { $0 }
                    
                    // Call AcceptEx
                    var bytesReceived: DWORD = 0
                    let result = acceptEx(
                        fileDescriptor.rawValue,
                        acceptSocket.rawValue,
                        buffer,
                        0, // No initial data
                        DWORD(MemoryLayout<sockaddr_in>.size + 16),
                        DWORD(MemoryLayout<sockaddr_in>.size + 16),
                        &bytesReceived,
                        overlappedPtr
                    )
                    
                    if result == false {
                        let error = GetLastError()
                        if error != ERROR_IO_PENDING {
                            registration.acceptContinuation = nil
                            self.sockets[fileDescriptor] = registration
                            continuation.resume(throwing: Errno(rawValue: CInt(error)))
                        }
                            // If ERROR_IO_PENDING, the operation will complete asynchronously
                        // Keep IOData alive
                        _ = Unmanaged.passRetained(ioData)
                    } else {
                        // Immediate success - keep IOData alive
                        _ = Unmanaged.passRetained(ioData)
                    }
                }
            }
        } catch {
            try? acceptSocket.close()
            throw error
        }
    }
    
    /// Accept a connection with address
    public func accept<Address: SocketAddress>(
        _ address: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (fileDescriptor: SocketDescriptor, address: Address) {
        // For now, use synchronous accept in a task
        // Future: Implement true async AcceptEx with IOCP
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let (newSocket, remoteAddress) = try WindowsSocket.accept(fileDescriptor)
                    
                    // Register the new socket with IOCP
                    try await self.register(newSocket)
                    
                    // Cast address to requested type
                    guard let typedAddress = remoteAddress as? Address else {
                        throw Errno.addressFamilyNotSupported
                    }
                    
                    continuation.resume(returning: (newSocket, typedAddress))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Initiate a connection using ConnectEx for true async operation
    public func connect<Address: SocketAddress>(
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws {
        // Bind the socket to any local address (required for ConnectEx)
        // Check if already bound
        if (try? fileDescriptor.address(type(of: address).self)) == nil {
            // Not bound, bind to any address
            if address is IPv4SocketAddress {
                try fileDescriptor.bind(IPv4SocketAddress(address: .any, port: 0))
            } else if address is IPv6SocketAddress {
                try fileDescriptor.bind(IPv6SocketAddress(address: .any, port: 0))
            }
        }
        
        // Load ConnectEx function
        let connectEx = try await WindowsSocketExtensions.shared.getConnectEx(socket: fileDescriptor.rawValue)
        
        // Create IOData for this operation
        let ioData = IOData(operation: .connect, socket: fileDescriptor)
        
        // Set up continuation
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                guard var registration = self.sockets[fileDescriptor] else {
                    continuation.resume(throwing: Errno.badFileDescriptor)
                    return
                }
                
                registration.connectContinuation = continuation
                self.sockets[fileDescriptor] = registration
                
                // Prepare overlapped structure
                let overlappedPtr = withUnsafeMutablePointer(to: &ioData.overlapped) { $0 }
                
                // Call ConnectEx
                let result = address.withUnsafePointer { addressPtr, addressLen in
                    var bytesSent: DWORD = 0
                    return connectEx(
                        fileDescriptor.rawValue,
                        addressPtr,
                        CInt(addressLen),
                        nil, // No initial data
                        0,
                        &bytesSent,
                        overlappedPtr
                    )
                }
                
                if result == false {
                    let error = GetLastError()
                    if error != ERROR_IO_PENDING {
                        registration.connectContinuation = nil
                        self.sockets[fileDescriptor] = registration
                        continuation.resume(throwing: Errno(rawValue: CInt(error)))
                        return
                    }
                    // If ERROR_IO_PENDING, the operation will complete asynchronously
                }
                
                // Keep IOData alive
                _ = Unmanaged.passRetained(ioData)
            }
        }
        
        // Update SO_UPDATE_CONNECT_CONTEXT after successful connection
        #if os(Windows)
        var val: CInt = 1
        _ = setsockopt(
            fileDescriptor.rawValue,
            SOL_SOCKET,
            SO_UPDATE_CONNECT_CONTEXT,
            &val,
            CInt(MemoryLayout<CInt>.size)
        )
        #endif
    }
    
    /// Listen for incoming connections
    public func listen(backlog: Int, for fileDescriptor: SocketDescriptor) async throws {
        // Listen is synchronous on Windows
        try WindowsSocket.listen(fileDescriptor, CInt(backlog))
    }
}

// MARK: - Errno Extensions for Windows

extension Errno {
    /// Create Errno from last Windows error
    static func fromLastError() -> Errno {
        return Errno(rawValue: CInt(GetLastError()))
    }
}

#endif