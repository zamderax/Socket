//
//  WindowsIOCPTests.swift
//  
//
//  Tests for Windows IOCP implementation
//

#if os(Windows)
import Foundation
import Testing
import Socket
import SystemPackage
import WinSDK

/// Tests for Windows IOCP socket implementation
@Suite("Windows IOCP Tests")
struct WindowsIOCPTests {
    
    /// Test basic socket creation on Windows
    @Test("Create Windows Socket")
    func testCreateSocket() throws {
        // Initialize Windows sockets
        let socket = try SocketDescriptor(IPv4Protocol.tcp)
        
        // Verify socket is valid
        #expect(socket.isValid)
        
        // Clean up
        try socket.close()
    }
    
    /// Test Windows socket lifecycle management
    @Test("Windows Socket Lifecycle")
    func testSocketLifecycle() throws {
        // Create socket
        let socket = try SocketDescriptor(IPv4Protocol.tcp)
        #expect(socket.isValid)
        
        // Close socket
        try socket.close()
        
        // After closing, operations should fail
        // Note: We can't check isValid after close as the descriptor might be reused
    }
    
    /// Test socket binding on Windows
    @Test("Windows Socket Bind")
    func testSocketBind() throws {
        let socket = try SocketDescriptor(IPv4Protocol.tcp)
        defer { try? socket.close() }
        
        // Bind to any address with automatic port
        let address = IPv4SocketAddress(address: .any, port: 0)
        try socket.bind(address)
        
        // If we get here, bind succeeded
        #expect(true)
    }
    
    /// Test Windows-specific error handling
    @Test("Windows Socket Errors")
    func testWindowsErrors() {
        // Test creating Errno from Windows error codes
        let error = Errno(rawValue: CInt(WSAECONNREFUSED))
        #expect(error.rawValue == CInt(WSAECONNREFUSED))
    }
    
    /// Test basic async socket operations
    @Test("Basic Async Socket")
    @available(Windows 10.0.22000, *)
    func testBasicAsyncSocket() async throws {
        // Create async socket
        let socket = try await Socket(IPv4Protocol.tcp)
        
        // Bind to local address
        let address = IPv4SocketAddress(address: .loopback, port: 0)
        try socket.fileDescriptor.bind(address)
        
        // If we get here, socket creation and binding worked
        #expect(true)
        
        // Close socket
        await socket.close()
    }
    
    /// Test Windows IOCP configuration
    @Test("Windows IOCP Configuration")
    @available(Windows 10.0.22000, *)
    func testIOCPConfiguration() {
        // Test that we can create the Windows configuration
        let config = WindowsSocketConfiguration(
            log: { message in
                // [IOCP] log message
            },
            workerThreadCount: 2
        )
        
        #expect(config.workerThreadCount == 2)
        #expect(config.log != nil)
    }
    
    /// Test concurrent socket operations
    @Test("Concurrent Windows Sockets")
    @available(Windows 10.0.22000, *)
    func testConcurrentSockets() async throws {
        // Create multiple sockets concurrently
        let sockets = await withTaskGroup(of: Socket?.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try? await Socket(IPv4Protocol.tcp)
                }
            }
            
            var results: [Socket] = []
            for await socket in group {
                if let socket = socket {
                    results.append(socket)
                }
            }
            return results
        }
        
        #expect(sockets.count == 5)
        
        // Close all sockets
        for socket in sockets {
            await socket.close()
        }
    }
}

#endif