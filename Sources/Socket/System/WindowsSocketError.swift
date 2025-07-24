//
//  WindowsSocketError.swift
//  
//
//  Windows-specific socket error handling
//

#if os(Windows)
import SystemPackage
import WinSDK

/// Extension to support Windows socket errors in Errno
extension Errno {
    /// Get the current Windows socket error as an Errno
    internal static var windowsCurrent: Errno {
        let wsaError = WSAGetLastError()
        // If it's a standard errno value (< 10000), use it directly
        if wsaError < 10000 {
            return Errno(rawValue: wsaError)
        }
        // Otherwise, use the Windows socket error code directly
        // This allows us to preserve the exact error without lossy mapping
        return Errno(rawValue: wsaError)
    }
    
    /// Set errno from a Windows socket error
    internal static func setWindowsError(_ wsaError: Int32) {
        system_errno = wsaError
    }
}

/// Helper to check if a Windows socket function failed and set errno appropriately
internal func windowsSocketResult<T: BinaryInteger>(_ result: T, invalidValue: T) -> T {
    if result == invalidValue {
        Errno.setWindowsError(WSAGetLastError())
    }
    return result
}

/// Helper for functions that return SOCKET_ERROR on failure
internal func windowsSocketResult(_ result: CInt) -> CInt {
    if result == SOCKET_ERROR {
        Errno.setWindowsError(WSAGetLastError())
    }
    return result
}

/// Helper for functions that return INVALID_SOCKET on failure
internal func windowsSocketResult(_ result: SOCKET) -> SOCKET {
    if result == INVALID_SOCKET {
        Errno.setWindowsError(WSAGetLastError())
    }
    return result
}
#endif