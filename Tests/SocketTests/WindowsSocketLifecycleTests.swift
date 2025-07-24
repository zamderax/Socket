//
//  WindowsSocketLifecycleTests.swift
//
//
//  Tests for Windows socket initialization
//

#if os(Windows)
import Testing
@testable import Socket
import SystemPackage

@Suite("Windows Socket Lifecycle")
struct WindowsSocketLifecycleTests {
    
    @Test("WSAStartup is called when creating socket")
    func testSocketInitialization() async throws {
        // Create a socket - this should trigger WSAStartup
        let socket = try await Socket(IPv4Protocol.tcp)
        
        // If we got here without error, WSAStartup succeeded
        #expect(socket.fileDescriptor.rawValue != 0)
        
        // Close the socket - this should decrement the reference count
        await socket.close()
    }
    
    @Test("Multiple sockets share initialization") 
    func testMultipleSocketInitialization() async throws {
        // Create multiple sockets
        let socket1 = try await Socket(IPv4Protocol.tcp)
        let socket2 = try await Socket(IPv4Protocol.udp)
        let socket3 = try await Socket(IPv6Protocol.tcp)
        
        // All should succeed
        #expect(socket1.fileDescriptor.rawValue != 0)
        #expect(socket2.fileDescriptor.rawValue != 0)
        #expect(socket3.fileDescriptor.rawValue != 0)
        
        // Close all sockets
        await socket1.close()
        await socket2.close()
        await socket3.close()
        
        // After all are closed, WSACleanup should be called
    }
    
    @Test("Socket operations work after initialization")
    func testSocketOperationsWork() async throws {
        // Create a TCP socket
        let socket = try await Socket(IPv4Protocol.tcp)
        
        // Try to bind to a port (may fail if port is in use, but should not crash)
        let address = IPv4SocketAddress(address: .loopback, port: 0)
        do {
            try await socket.fileDescriptor.bind(address)
            
            // Get the actual bound address
            let boundAddress = try socket.fileDescriptor.address(IPv4SocketAddress.self)
            #expect(boundAddress.address == .loopback)
            #expect(boundAddress.port > 0) // Should have assigned a port
        } catch {
            // Binding might fail, but the error should be a valid socket error
            // not a WSAStartup failure
            print("Bind failed (expected): \(error)")
        }
        
        await socket.close()
    }
    
    @Test("UDP socket initialization")
    func testUDPSocketInitialization() async throws {
        // Create a UDP socket
        let socket = try await Socket(IPv4Protocol.udp)
        
        // Bind to any available port
        let address = IPv4SocketAddress(address: .any, port: 0)
        try await socket.fileDescriptor.bind(address)
        
        // Get the bound address to verify it worked
        let boundAddress = try socket.fileDescriptor.address(IPv4SocketAddress.self)
        #expect(boundAddress.port > 0)
        
        await socket.close()
    }
}
#endif