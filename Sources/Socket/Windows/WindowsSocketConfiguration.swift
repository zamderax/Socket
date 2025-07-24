//
//  WindowsSocketConfiguration.swift
//  
//
//  Windows-specific socket configuration using IOCP
//

#if os(Windows)
import Foundation

/// Configuration for Windows sockets using IOCP
///
/// This configuration uses I/O Completion Ports (IOCP) for high-performance
/// asynchronous I/O operations on Windows instead of the polling-based approach.
@available(Windows 10.0.22000, *)
public struct WindowsSocketConfiguration: Sendable {
    
    /// Log handler for debugging
    public var log: (@Sendable (String) -> ())?
    
    /// Number of worker threads for IOCP (0 = number of CPUs)
    public var workerThreadCount: Int
    
    /// Whether to fall back to AsyncSocketManager if IOCP fails
    public var fallbackOnError: Bool
    
    /// Custom manager instance (for testing)
    internal var customManager: IOCPSocketManager?
    
    public init(
        log: (@Sendable (String) -> ())? = nil,
        workerThreadCount: Int = 0,
        fallbackOnError: Bool = true
    ) {
        self.log = log
        self.workerThreadCount = workerThreadCount
        self.fallbackOnError = fallbackOnError
        self.customManager = nil
    }
    
    /// Initialize with a custom IOCP manager (for testing)
    internal init(manager: IOCPSocketManager) {
        self.log = nil
        self.workerThreadCount = 0
        self.fallbackOnError = false
        self.customManager = manager
    }
}

@available(Windows 10.0.22000, *)
extension WindowsSocketConfiguration: SocketManagerConfiguration {
    
    /// Type-erased socket manager wrapper
    private final class AnySocketManager: SocketManager {
        private let _add: @Sendable (SocketDescriptor) async -> Socket.Event.Stream
        private let _remove: @Sendable (SocketDescriptor) async -> Void
        private let _write: @Sendable (Data, SocketDescriptor) async throws -> Int
        private let _read: @Sendable (Int, SocketDescriptor) async throws -> Data
        private let _receiveMessage: @Sendable (Int, SocketDescriptor) async throws -> Data
        private let _receiveMessageWithAddress: @Sendable (Int, Any.Type, SocketDescriptor) async throws -> (Data, Any)
        private let _sendMessage: @Sendable (Data, SocketDescriptor) async throws -> Int
        private let _sendMessageToAddress: @Sendable (Data, Any, SocketDescriptor) async throws -> Int
        private let _accept: @Sendable (SocketDescriptor) async throws -> SocketDescriptor
        private let _acceptWithAddress: @Sendable (Any.Type, SocketDescriptor) async throws -> (SocketDescriptor, Any)
        private let _connect: @Sendable (Any, SocketDescriptor) async throws -> Void
        private let _listen: @Sendable (Int, SocketDescriptor) async throws -> Void
        
        init<T: SocketManager>(_ manager: T) {
            self._add = { await manager.add($0) }
            self._remove = { await manager.remove($0) }
            self._write = { try await manager.write($0, for: $1) }
            self._read = { try await manager.read($0, for: $1) }
            self._receiveMessage = { try await manager.receiveMessage($0, for: $1) }
            self._receiveMessageWithAddress = { length, addressType, socket in
                fatalError("Type-erased receiveMessage not implemented")
            }
            self._sendMessage = { try await manager.sendMessage($0, for: $1) }
            self._sendMessageToAddress = { data, address, socket in
                fatalError("Type-erased sendMessage not implemented")
            }
            self._accept = { try await manager.accept(for: $0) }
            self._acceptWithAddress = { addressType, socket in
                fatalError("Type-erased accept not implemented")
            }
            self._connect = { address, socket in
                fatalError("Type-erased connect not implemented")
            }
            self._listen = { try await manager.listen(backlog: $0, for: $1) }
        }
        
        func add(_ fileDescriptor: SocketDescriptor) async -> Socket.Event.Stream {
            await _add(fileDescriptor)
        }
        
        func remove(_ fileDescriptor: SocketDescriptor) async {
            await _remove(fileDescriptor)
        }
        
        func write(_ data: Data, for fileDescriptor: SocketDescriptor) async throws -> Int {
            try await _write(data, fileDescriptor)
        }
        
        func read(_ length: Int, for fileDescriptor: SocketDescriptor) async throws -> Data {
            try await _read(length, fileDescriptor)
        }
        
        func receiveMessage(_ length: Int, for fileDescriptor: SocketDescriptor) async throws -> Data {
            try await _receiveMessage(length, fileDescriptor)
        }
        
        func receiveMessage<Address: SocketAddress>(_ length: Int, fromAddressOf addressType: Address.Type, for fileDescriptor: SocketDescriptor) async throws -> (Data, Address) {
            let result = try await _receiveMessageWithAddress(length, addressType, fileDescriptor)
            return (result.0, result.1 as! Address)
        }
        
        func sendMessage(_ data: Data, for fileDescriptor: SocketDescriptor) async throws -> Int {
            try await _sendMessage(data, fileDescriptor)
        }
        
        func sendMessage<Address: SocketAddress>(_ data: Data, to address: Address, for fileDescriptor: SocketDescriptor) async throws -> Int {
            try await _sendMessageToAddress(data, address, fileDescriptor)
        }
        
        func accept(for fileDescriptor: SocketDescriptor) async throws -> SocketDescriptor {
            try await _accept(fileDescriptor)
        }
        
        func accept<Address: SocketAddress>(_ address: Address.Type, for fileDescriptor: SocketDescriptor) async throws -> (fileDescriptor: SocketDescriptor, address: Address) {
            let result = try await _acceptWithAddress(address, fileDescriptor)
            return (result.0, result.1 as! Address)
        }
        
        func connect<Address: SocketAddress>(to address: Address, for fileDescriptor: SocketDescriptor) async throws {
            try await _connect(address, fileDescriptor)
        }
        
        func listen(backlog: Int, for fileDescriptor: SocketDescriptor) async throws {
            try await _listen(backlog, fileDescriptor)
        }
    }
    
    /// Current logger instance
    nonisolated(unsafe) fileprivate static var currentLogger: (@Sendable (String) -> ())? = nil
    
    /// Thread-local storage for custom managers
    nonisolated(unsafe) private static var customManagers: [ObjectIdentifier: AnySocketManager] = [:]
    
    /// Shared IOCP manager instance
    private static let sharedManager: AnySocketManager = {
        do {
            let iocpManager = try IOCPSocketManager(log: currentLogger)
            return AnySocketManager(iocpManager)
        } catch {
            // Log error using predefined logger
            currentLogger?("Failed to initialize IOCP manager: \(error), falling back to AsyncSocketManager")
            return AnySocketManager(AsyncSocketManager.shared)
        }
    }()
    
    public nonisolated var manager: some SocketManager {
        // Check if we have a custom manager for this configuration
        if let customManager = customManager {
            let id = ObjectIdentifier(customManager)
            if let existing = Self.customManagers[id] {
                return existing
            } else {
                let wrapped = AnySocketManager(customManager)
                Self.customManagers[id] = wrapped
                return wrapped
            }
        }
        return Self.sharedManager
    }
    
    public static var manager: some SocketManager {
        return sharedManager
    }
    
    public func configureManager() {
        // Update logger if changed
        Self.currentLogger = log
        
        // Note: IOCP logger cannot be updated at runtime due to actor isolation
        // Logger is set at initialization time
    }
}

/// Convenience extension to configure Windows IOCP logging
@available(Windows 10.0.22000, *)
public extension Socket {
    
    /// Configure debug logging for Windows IOCP operations
    ///
    /// Note: IOCP is automatically used on Windows 11+. This method only
    /// configures debug logging to help diagnose IOCP-related issues.
    ///
    /// Example:
    /// ```swift
    /// Socket.configureWindowsLogging { message in
    ///     print("[IOCP] \(message)")
    /// }
    /// let socket = try await Socket(.tcp4)
    /// ```
    static func configureWindowsLogging(
        log: (@Sendable (String) -> ())? = nil,
        workerThreadCount: Int = 0
    ) {
        // Set the logger for runtime configuration
        if let log = log {
            WindowsSocketConfiguration.currentLogger = log
        }
    }
}

#endif