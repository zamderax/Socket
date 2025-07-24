//
//  WindowsSocketExtensions.swift
//  
//
//  Windows-specific socket extension functions (AcceptEx, ConnectEx)
//

#if os(Windows)
import WinSDK
import SystemPackage

/// Windows socket extension function GUIDs
internal struct WindowsSocketExtensionGUIDs {
    /// GUID for AcceptEx function {B5367DF1-CBAC-11CF-95CA-00805F48A192}
    static let acceptEx = GUID(
        Data1: 0xb5367df1,
        Data2: 0xcbac,
        Data3: 0x11cf,
        Data4: (0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92)
    )
    
    /// GUID for ConnectEx function {25A207B9-DDF3-4660-8EE9-76E58C74063E}
    static let connectEx = GUID(
        Data1: 0x25a207b9,
        Data2: 0xddf3,
        Data3: 0x4660,
        Data4: (0x8e, 0xe9, 0x76, 0xe5, 0x8c, 0x74, 0x06, 0x3e)
    )
    
    /// GUID for GetAcceptExSockaddrs function {B5367DF2-CBAC-11CF-95CA-00805F48A192}
    static let getAcceptExSockaddrs = GUID(
        Data1: 0xb5367df2,
        Data2: 0xcbac,
        Data3: 0x11cf,
        Data4: (0x95, 0xca, 0x00, 0x80, 0x5f, 0x48, 0xa1, 0x92)
    )
    
    /// GUID for WSASendTo function (not required - WSASendTo is a direct export)
    // WSASendTo is available as a direct export from ws2_32.dll
    
    /// GUID for WSARecvFrom function (not required - WSARecvFrom is a direct export)
    // WSARecvFrom is available as a direct export from ws2_32.dll
}

/// Windows socket IO control codes
internal struct WindowsSocketIOControl {
    /// Get extension function pointer
    static let getExtensionFunctionPointer: DWORD = IOC_OUT | IOC_WS2 | 6
    
    private static let IOC_WS2: DWORD = 0x08000000
    private static let IOC_OUT: DWORD = 0x40000000
}

/// Type definitions for Windows socket extension functions
internal typealias LPFN_ACCEPTEX = @convention(c) (
    SOCKET,                    // sListenSocket
    SOCKET,                    // sAcceptSocket
    PVOID?,                    // lpOutputBuffer
    DWORD,                     // dwReceiveDataLength
    DWORD,                     // dwLocalAddressLength
    DWORD,                     // dwRemoteAddressLength
    UnsafeMutablePointer<DWORD>?, // lpdwBytesReceived
    LPOVERLAPPED?              // lpOverlapped
) -> WindowsBool

internal typealias LPFN_CONNECTEX = @convention(c) (
    SOCKET,                    // s
    UnsafePointer<sockaddr>?,  // name
    CInt,                      // namelen
    PVOID?,                    // lpSendBuffer
    DWORD,                     // dwSendDataLength
    UnsafeMutablePointer<DWORD>?, // lpdwBytesSent
    LPOVERLAPPED?              // lpOverlapped
) -> WindowsBool

internal typealias LPFN_GETACCEPTEXSOCKADDRS = @convention(c) (
    PVOID?,                    // lpOutputBuffer
    DWORD,                     // dwReceiveDataLength
    DWORD,                     // dwLocalAddressLength
    DWORD,                     // dwRemoteAddressLength
    UnsafeMutablePointer<UnsafeMutablePointer<sockaddr>?>?, // LocalSockaddr
    UnsafeMutablePointer<CInt>?, // LocalSockaddrLength
    UnsafeMutablePointer<UnsafeMutablePointer<sockaddr>?>?, // RemoteSockaddr
    UnsafeMutablePointer<CInt>?  // RemoteSockaddrLength
) -> Void

/// Note: WSASendTo and WSARecvFrom are direct exports from ws2_32.dll and don't need
/// to be loaded via WSAIoctl. They can be called directly from WinSDK.

/// Windows socket extension functions cache
internal actor WindowsSocketExtensions {
    
    /// Cached AcceptEx function pointer
    private var acceptExFunc: LPFN_ACCEPTEX?
    
    /// Cached ConnectEx function pointer
    private var connectExFunc: LPFN_CONNECTEX?
    
    /// Cached GetAcceptExSockaddrs function pointer
    private var getAcceptExSockaddrsFunc: LPFN_GETACCEPTEXSOCKADDRS?
    
    /// Shared instance
    static let shared = WindowsSocketExtensions()
    
    /// Load a Windows socket extension function
    private func loadExtensionFunction<T>(
        socket: SOCKET,
        guid: GUID,
        functionType: T.Type
    ) throws -> T {
        var guidVar = guid
        var functionPointer: T?
        var bytesReturned: DWORD = 0
        
        let result = withUnsafeMutablePointer(to: &functionPointer) { ptr in
            WSAIoctl(
                socket,
                WindowsSocketIOControl.getExtensionFunctionPointer,
                &guidVar,
                DWORD(MemoryLayout<GUID>.size),
                ptr,
                DWORD(MemoryLayout<T>.size),
                &bytesReturned,
                nil,
                nil
            )
        }
        
        guard result == 0 else {
            throw Errno.windowsCurrent
        }
        
        guard let function = functionPointer else {
            throw Errno.notSupported
        }
        
        return function
    }
    
    /// Get AcceptEx function
    func getAcceptEx(socket: SOCKET) throws -> LPFN_ACCEPTEX {
        if let cached = acceptExFunc {
            return cached
        }
        
        let function = try loadExtensionFunction(
            socket: socket,
            guid: WindowsSocketExtensionGUIDs.acceptEx,
            functionType: LPFN_ACCEPTEX.self
        )
        
        acceptExFunc = function
        return function
    }
    
    /// Get ConnectEx function
    func getConnectEx(socket: SOCKET) throws -> LPFN_CONNECTEX {
        if let cached = connectExFunc {
            return cached
        }
        
        let function = try loadExtensionFunction(
            socket: socket,
            guid: WindowsSocketExtensionGUIDs.connectEx,
            functionType: LPFN_CONNECTEX.self
        )
        
        connectExFunc = function
        return function
    }
    
    /// Get GetAcceptExSockaddrs function
    func getGetAcceptExSockaddrs(socket: SOCKET) throws -> LPFN_GETACCEPTEXSOCKADDRS {
        if let cached = getAcceptExSockaddrsFunc {
            return cached
        }
        
        let function = try loadExtensionFunction(
            socket: socket,
            guid: WindowsSocketExtensionGUIDs.getAcceptExSockaddrs,
            functionType: LPFN_GETACCEPTEXSOCKADDRS.self
        )
        
        getAcceptExSockaddrsFunc = function
        return function
    }
}

/// Extension for AcceptEx buffer size calculations
internal extension WindowsSocketExtensions {
    /// Calculate the required buffer size for AcceptEx
    /// The buffer must be large enough for local and remote addresses plus 16 bytes each
    static func acceptExBufferSize(
        receiveDataLength: Int = 0,
        addressFamily: SocketAddressFamily = .ipv4
    ) -> Int {
        let addressLength = addressFamily == .ipv6 ? 
            MemoryLayout<sockaddr_in6>.size : 
            MemoryLayout<sockaddr_in>.size
        
        // AcceptEx requires address length + 16 bytes for each address
        let localAddressLength = addressLength + 16
        let remoteAddressLength = addressLength + 16
        
        return receiveDataLength + localAddressLength + remoteAddressLength
    }
    
    /// Get the maximum address size for UDP operations
    static func maxAddressSize() -> Int {
        // Maximum of IPv4 and IPv6 sockaddr sizes
        return max(MemoryLayout<sockaddr_in>.size, MemoryLayout<sockaddr_in6>.size)
    }
}

#endif