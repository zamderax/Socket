//
//  SocketDescriptor.swift
//  
//
//  Created by Alsey Coleman Miller on 4/26/22.
//

import SystemPackage
#if os(Windows)
import WinSDK
#endif

/// Native Socket handle.
///
/// Same as ``FileDescriptor`` on POSIX and opaque type on Windows.
public struct SocketDescriptor: RawRepresentable, Equatable, Hashable, Sendable {
    
    #if os(Windows)
    /// Native Windows Socket handle
    ///
    /// https://docs.microsoft.com/en-us/windows/win32/api/winsock2/
    public typealias RawValue = SOCKET
    #else
    /// Native POSIX Socket handle
    public typealias RawValue = FileDescriptor.RawValue
    #endif
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public let rawValue: RawValue
}

#if os(Windows)
extension SocketDescriptor {
    
    /// Invalid socket descriptor
    public static var invalid: SocketDescriptor {
        return SocketDescriptor(rawValue: INVALID_SOCKET)
    }
    
    /// Check if the socket descriptor is valid
    public var isValid: Bool {
        return rawValue != INVALID_SOCKET
    }
}
#else
extension SocketDescriptor {
    
    /// Invalid socket descriptor
    public static var invalid: SocketDescriptor {
        return SocketDescriptor(rawValue: -1)
    }
    
    /// Check if the socket descriptor is valid
    public var isValid: Bool {
        return rawValue >= 0
    }
}
#endif

// MARK: - Close Operation

// Close is already defined in SocketOperations.swift
