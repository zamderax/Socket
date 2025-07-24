//
//  WindowsSocketLifecycle.swift
//  
//
//  Created for Windows socket initialization
//

#if os(Windows)
import CSocket
import Foundation

/// Manages Windows Socket (Winsock) initialization and cleanup
internal final class WindowsSocketLifecycle {
    
    /// Shared instance for socket lifecycle management
    nonisolated(unsafe) static let shared = WindowsSocketLifecycle()
    
    /// Lock for thread-safe access
    private let lock = NSLock()
    
    /// Reference count for nested initialization
    private var initializationCount = 0
    
    /// Whether Winsock has been initialized
    private var isInitialized = false
    
    /// The Winsock version we request (2.2)
    private static let winsockVersion: WORD = MAKEWORD(2, 2)
    
    private init() {
        // Private init for singleton
    }
    
    deinit {
        // Ensure cleanup on deinit
        if isInitialized {
            WSACleanup()
        }
    }
    
    /// Initialize Winsock if not already initialized
    /// Thread-safe and supports nested calls
    @discardableResult
    func initialize() -> Result<Void, Errno> {
        lock.lock()
        defer { lock.unlock() }
        
        initializationCount += 1
        
        if isInitialized {
            return .success(())
        }
        
        var wsaData = WSADATA()
        let result = WSAStartup(Self.winsockVersion, &wsaData)
        
        if result != 0 {
            initializationCount -= 1
            // WSAStartup failed with error: \(result)
            return .failure(mapWSAError(result))
        }
        
        // Verify we got at least version 2.2
        let majorVersion = LOBYTE(wsaData.wVersion)
        let minorVersion = HIBYTE(wsaData.wVersion)
        
        if majorVersion < 2 || (majorVersion == 2 && minorVersion < 2) {
            WSACleanup()
            initializationCount -= 1
            return .failure(.notSupported)
        }
        
        isInitialized = true
        // WSAStartup succeeded - Winsock \(majorVersion).\(minorVersion) initialized
        
        // Register cleanup handler for process exit
        // atexit {
        //     WindowsSocketLifecycle.shared.cleanup()
        // }
        
        return .success(())
    }
    
    /// Decrement reference count and cleanup if needed
    func cleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        guard initializationCount > 0 else { return }
        
        initializationCount -= 1
        
        if initializationCount == 0 && isInitialized {
            WSACleanup()
            isInitialized = false
        }
    }
    
    /// Force cleanup regardless of reference count
    func forceCleanup() {
        lock.lock()
        defer { lock.unlock() }
        
        if isInitialized {
            WSACleanup()
            isInitialized = false
            initializationCount = 0
        }
    }
    
    /// Map WSA error codes to Errno
    private func mapWSAError(_ error: Int32) -> Errno {
        switch error {
        case WSAENETDOWN:
            return .networkDown
        case WSAEAFNOSUPPORT:
            return .addressFamilyNotSupported
        case WSAEINPROGRESS:
            return .nowInProgress
        case WSAEMFILE:
            return .tooManyOpenFiles
        case WSAENOBUFS:
            return .noBufferSpace
        case WSAEPROTONOSUPPORT:
            return .protocolNotSupported
        case WSAEPROTOTYPE:
            return .protocolWrongTypeForSocket
        case WSAESOCKTNOSUPPORT:
            return .socketTypeNotSupported
        default:
            return .invalidArgument
        }
    }
}

/// Initialize Windows sockets automatically when creating a socket
internal func ensureWindowsSocketsInitialized() throws(Errno) {
    try WindowsSocketLifecycle.shared.initialize().get()
}

// Helper to make WORD from two bytes
private func MAKEWORD(_ low: UInt8, _ high: UInt8) -> WORD {
    return WORD(low) | (WORD(high) << 8)
}

// Helper to get low byte
private func LOBYTE(_ word: WORD) -> UInt8 {
    return UInt8(word & 0xFF)
}

// Helper to get high byte  
private func HIBYTE(_ word: WORD) -> UInt8 {
    return UInt8((word >> 8) & 0xFF)
}

#endif