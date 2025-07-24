//
//  WindowsProtocolTests.swift
//  
//
//  Tests for UDP, IPv6, and protocol-specific functionality on Windows
//

#if os(Windows)
import Foundation
import Testing
import Socket
import SystemPackage
import WinSDK

/// Tests for Windows protocol support
@Suite("Windows Protocol Tests")
struct WindowsProtocolTests {
    
    // MARK: - UDP Tests
    
    /// Test UDP socket creation and basic operations
    @Test("UDP Socket Basic Operations")
    @available(Windows 10.0, *)
    func testUDPBasicOperations() async throws {
        // Create UDP socket
        let socket = try await Socket(IPv4Protocol.udp)
        defer { Task { await socket.close() } }
        
        // Bind to any port
        let address = IPv4SocketAddress(address: .any, port: 0)
        try socket.fileDescriptor.bind(address)
        
        // Get actual bound address
        let boundAddress = try socket.fileDescriptor.address(IPv4SocketAddress.self)
        #expect(boundAddress.port != 0)
    }
    
    /// Test UDP send and receive
    @Test("UDP Send/Receive")
    @available(Windows 10.0, *)
    func testUDPSendReceive() async throws {
        // Create server socket
        let server = try await Socket(IPv4Protocol.udp)
        defer { Task { await server.close() } }
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.fileDescriptor.bind(serverAddress)
        let boundAddress = try server.fileDescriptor.address(IPv4SocketAddress.self)
        
        // Create client socket
        let client = try await Socket(IPv4Protocol.udp)
        defer { Task { await client.close() } }
        
        // Send data from client to server
        let testData = "Hello UDP on Windows!".data(using: .utf8)!
        try await client.sendMessage(testData, to: boundAddress)
        
        // Receive data on server
        let (receivedData, senderAddress) = try await server.receiveMessage(testData.count, fromAddressOf: IPv4SocketAddress.self)
        
        #expect(receivedData == testData)
        #expect(senderAddress is IPv4SocketAddress)
    }
    
    // MARK: - IPv6 Tests
    
    /// Test IPv6 socket creation
    @Test("IPv6 Socket Creation")
    @available(Windows 10.0, *)
    func testIPv6SocketCreation() async throws {
        // Create IPv6 TCP socket
        let tcpSocket = try await Socket(IPv6Protocol.tcp)
        defer { Task { await tcpSocket.close() } }
        
        #expect(tcpSocket.fileDescriptor.isValid)
        
        // Create IPv6 UDP socket
        let udpSocket = try await Socket(IPv6Protocol.udp)
        defer { Task { await udpSocket.close() } }
        
        #expect(udpSocket.fileDescriptor.isValid)
    }
    
    /// Test IPv6 address binding
    @Test("IPv6 Socket Bind")
    @available(Windows 10.0, *)
    func testIPv6Bind() async throws {
        let socket = try await Socket(IPv6Protocol.tcp)
        defer { Task { await socket.close() } }
        
        // Bind to IPv6 any address
        let address = IPv6SocketAddress(address: .any, port: 0)
        try socket.fileDescriptor.bind(address)
        
        // Verify bound address is IPv6
        let boundAddress = try socket.fileDescriptor.address(IPv6SocketAddress.self)
        #expect(boundAddress.port != 0)
    }
    
    /// Test IPv6 TCP communication
    @Test("IPv6 TCP Echo")
    @available(Windows 10.0, *)
    func testIPv6TCPEcho() async throws {
        // Create server
        let server = try await Socket(IPv6Protocol.tcp)
        defer { Task { await server.close() } }
        
        let serverAddress = IPv6SocketAddress(address: .loopback, port: 0)
        try server.fileDescriptor.bind(serverAddress)
        try await server.listen(backlog: 5)
        
        let boundAddress = try server.fileDescriptor.address(IPv6SocketAddress.self)
        
        // Create client and connect
        let client = try await Socket(IPv6Protocol.tcp)
        defer { Task { await client.close() } }
        
        try await client.connect(to: boundAddress)
        
        // Accept connection
        Task {
            let connection = try await server.accept()
            
            // Echo received data
            let data = try await connection.read(5) // Read "Hello"
            try await connection.write(data)
        }
        
        // Send and receive data
        let testData = Data([72, 101, 108, 108, 111]) // "Hello"
        try await client.write(testData)
        
        let received = try await client.read(testData.count)
        
        #expect(received == testData)
    }
    
    /// Test IPv6 UDP communication
    @Test("IPv6 UDP Datagram")
    @available(Windows 10.0, *)
    func testIPv6UDPDatagram() async throws {
        // Create server socket
        let server = try await Socket(IPv6Protocol.udp)
        defer { Task { await server.close() } }
        
        let serverAddress = IPv6SocketAddress(address: .loopback, port: 0)
        try server.fileDescriptor.bind(serverAddress)
        let boundAddress = try server.fileDescriptor.address(IPv6SocketAddress.self)
        
        // Create client socket
        let client = try await Socket(IPv6Protocol.udp)
        defer { Task { await client.close() } }
        
        // Send IPv6 datagram
        let testData = "IPv6 UDP Test".data(using: .utf8)!
        try await client.sendMessage(testData, to: boundAddress)
        
        // Receive datagram
        let (receivedData, senderAddress) = try await server.receiveMessage(testData.count, fromAddressOf: IPv6SocketAddress.self)
        
        #expect(receivedData == testData)
        let ipv6Address = senderAddress as? IPv6SocketAddress
        #expect(ipv6Address != nil)
    }
    
    // MARK: - Protocol Interoperability Tests
    
    /// Test socket option setting on Windows
    @Test("Windows Socket Options")
    @available(Windows 10.0, *)
    func testWindowsSocketOptions() async throws {
        // Test TCP_NODELAY
        let tcpSocket = try await Socket(IPv4Protocol.tcp)
        defer { Task { await tcpSocket.close() } }
        
        // Set TCP_NODELAY using the Socket API
        let nodelay = TCPSocketOption.NoDelay(true)
        try tcpSocket.setOption(nodelay)
        
        // Get TCP_NODELAY
        let retrievedOption = try tcpSocket[TCPSocketOption.NoDelay.self]
        #expect(retrievedOption.boolValue == true)
        
        // Test disabling TCP_NODELAY
        let disableNodelay = TCPSocketOption.NoDelay(false)
        try tcpSocket.setOption(disableNodelay)
        
        let retrievedDisabled = try tcpSocket[TCPSocketOption.NoDelay.self]
        #expect(retrievedDisabled.boolValue == false)
    }
    
    /// Test non-blocking socket operations
    @Test("Non-blocking Sockets")
    @available(Windows 10.0, *)
    func testNonBlockingSockets() async throws {
        let socket = try await Socket(IPv4Protocol.tcp)
        defer { Task { await socket.close() } }
        
        // Socket should already be non-blocking for async operations
        // Try a non-blocking operation
        let address = IPv4SocketAddress(address: .any, port: 0)
        try socket.fileDescriptor.bind(address)
        try await socket.listen(backlog: 1)
        
        // Accept should not block indefinitely
        do {
            _ = try await socket.accept()
            Issue.record("Accept should have failed or returned immediately")
        } catch {
            // Expected - no pending connections
            #expect(error is Errno)
        }
    }
}

// MARK: - Multicast Tests (Future Implementation)

extension WindowsProtocolTests {
    
    /// Placeholder for multicast support tests
    @Test("Multicast Support Check", .disabled("Multicast not yet implemented"))
    func testMulticastSupport() throws {
        // TODO: Test multicast when implemented
        // - IP_ADD_MEMBERSHIP
        // - IP_DROP_MEMBERSHIP
        // - IP_MULTICAST_TTL
        // - IP_MULTICAST_LOOP
        // - IPV6_JOIN_GROUP
        // - IPV6_LEAVE_GROUP
        throw Errno.notSupported
    }
}

#endif