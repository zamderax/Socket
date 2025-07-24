//
//  SocketDescriptorConversion.swift
//  
//
//  Conversion utilities for socket descriptors on different platforms
//

import SystemPackage
#if os(Windows)
import WinSDK
#endif

// MARK: - Platform-specific conversions

internal extension SocketDescriptor {
    
    /// Convert to platform-specific socket type for syscalls
    var cValue: CInterop.SocketDescriptor {
        #if os(Windows)
        return rawValue
        #else
        return CInt(rawValue)
        #endif
    }
    
    /// Create from platform-specific socket type
    init(cValue: CInterop.SocketDescriptor) {
        #if os(Windows)
        self.init(rawValue: cValue)
        #else
        self.init(rawValue: SocketDescriptor.RawValue(cValue))
        #endif
    }
}

// MARK: - Invalid socket value

internal extension CInterop {
    
    /// Invalid socket value for the platform
    static var invalidSocket: CInterop.SocketDescriptor {
        #if os(Windows)
        return INVALID_SOCKET
        #else
        return -1
        #endif
    }
}