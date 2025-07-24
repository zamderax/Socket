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
@available(Windows 10.0, *)
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
    }
    
    /// Per-socket registration data
    private struct SocketRegistration {
        let socket: SocketDescriptor
        var readContinuation: AsyncStream<Socket.Event>.Continuation?
        var writeContinuation: AsyncStream<Socket.Event>.Continuation?
        var pendingOperations: Set<OperationType> = []
    }
    
    /// IOCP per-I/O data structure
    private class IOData {
        var overlapped: OVERLAPPED = OVERLAPPED()
        let operation: OperationType
        let socket: SocketDescriptor
        var buffer: UnsafeMutablePointer<UInt8>?
        var bufferSize: Int = 0
        
        init(operation: OperationType, socket: SocketDescriptor) {
            self.operation = operation
            self.socket = socket
        }
        
        deinit {
            buffer?.deallocate()
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
            event = .connection
            
        case .connect:
            // Connect completion - connection established
            event = .connection
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
    
    /// Receive message with address
    public func receiveMessage<Address: SocketAddress>(
        _ length: Int,
        fromAddressOf addressType: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (Data, Address) {
        // For now, use synchronous recvfrom in a task
        // Future: Implement true async recvfrom with IOCP (WSARecvFrom)
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let buffer = UnsafeMutableRawBufferPointer.allocate(
                        byteCount: length,
                        alignment: MemoryLayout<UInt8>.alignment
                    )
                    defer { buffer.deallocate() }
                    
                    let (bytesReceived, address) = try fileDescriptor.receive(
                        into: buffer,
                        fromAddressOf: addressType
                    )
                    
                    let data = Data(bytes: buffer.baseAddress!, count: bytesReceived)
                    continuation.resume(returning: (data, address))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Send message
    public func sendMessage(_ data: Data, for fileDescriptor: SocketDescriptor) async throws -> Int {
        // For now, just use write
        return try await write(data, for: fileDescriptor)
    }
    
    /// Send message to address
    public func sendMessage<Address: SocketAddress>(
        _ data: Data,
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int {
        // For now, use synchronous sendto in a task
        // Future: Implement true async sendto with IOCP (WSASendTo)
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let bytesSent = try data.withUnsafeBytes { buffer in
                        try fileDescriptor.send(
                            buffer,
                            to: address
                        )
                    }
                    continuation.resume(returning: bytesSent)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Accept new socket
    public func accept(for fileDescriptor: SocketDescriptor) async throws -> SocketDescriptor {
        // For now, use synchronous accept in a task
        // Future: Implement true async AcceptEx with IOCP
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let (newSocket, _) = try WindowsSocket.accept(fileDescriptor)
                    
                    // Register the new socket with IOCP
                    try await self.register(newSocket)
                    
                    continuation.resume(returning: newSocket)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
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
    
    /// Initiate a connection
    public func connect<Address: SocketAddress>(
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws {
        // For now, use synchronous connect in a task
        // Future: Implement true async ConnectEx with IOCP
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try WindowsSocket.connect(fileDescriptor, address)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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