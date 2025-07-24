//
//  IOCPManagerTests.swift
//  
//
//  Tests for IOCPSocketManager implementation
//

#if os(Windows)
import Foundation
import Testing
import Socket
import SystemPackage

@Suite("IOCP Manager Tests")
struct IOCPManagerTests {
    
    @Test("Create IOCP Manager")
    func testCreateManager() async throws {
        guard #available(Windows 10.0.22000, *) else {
            return // Skip test on older Windows
        }
        
        let manager = try IOCPSocketManager()
        
        // Manager should be created successfully
        #expect(true)
        
        await manager.cleanup()
    }
    
    @Test("IOCP Socket Direct Operations")
    func testIOCPDirectOperations() async throws {
        guard #available(Windows 10.0.22000, *) else {
            return // Skip test on older Windows
        }
        
        let manager = try IOCPSocketManager()
        
        // Create socket descriptor directly
        let descriptor = try SocketDescriptor(IPv4Protocol.tcp)
        
        // Register with manager
        _ = await manager.add(descriptor)
        
        // Bind to loopback
        let address = IPv4SocketAddress(address: .loopback, port: 0)
        try descriptor.bind(address)
        
        // Get bound address
        let boundAddress = try descriptor.address(IPv4SocketAddress.self)
        #expect(boundAddress.address == IPv4Address.loopback)
        #expect(boundAddress.port > 0)
        
        // Remove from manager and close
        await manager.remove(descriptor)
        try descriptor.close()
        await manager.cleanup()
    }
    
    @Test("IOCP Accept and Connect")
    func testIOCPAcceptConnect() async throws {
        guard #available(Windows 10.0.22000, *) else {
            return // Skip test on older Windows
        }
        
        let manager = try IOCPSocketManager()
        
        // Create server socket
        let server = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        try await manager.listen(backlog: 5, for: server)
        
        // Get actual server address
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Create client socket
        let client = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(client)
        
        // Start accepting in background
        let acceptTask = Task {
            try await manager.accept(for: server)
        }
        
        // Give accept time to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Connect to server
        try await manager.connect(to: boundAddress, for: client)
        
        // Wait for accept to complete
        let newConnection = try await acceptTask.value
        
        // Verify connection
        #expect(newConnection.isValid)
        
        // Cleanup
        await manager.remove(newConnection)
        try newConnection.close()
        await manager.remove(client)
        try client.close()
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
    
    @Test("IOCP Read Write") 
    func testIOCPReadWrite() async throws {
        guard #available(Windows 10.0.22000, *) else {
            return // Skip test on older Windows
        }
        
        let manager = try IOCPSocketManager()
        
        // Create server socket
        let server = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        try await manager.listen(backlog: 5, for: server)
        
        // Get actual server address
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Create client socket
        let client = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(client)
        
        // Start accepting in background
        let acceptTask = Task {
            try await manager.accept(for: server)
        }
        
        // Give accept time to start
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Connect to server
        try await manager.connect(to: boundAddress, for: client)
        
        // Wait for accept to complete
        let connection = try await acceptTask.value
        _ = await manager.add(connection)
        
        // Give connection time to establish
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Send data from client
        let testData = Data("Hello IOCP!".utf8)
        let bytesSent = try await manager.write(testData, for: client)
        #expect(bytesSent == testData.count)
        
        // Read data on server connection
        let receivedData = try await manager.read(testData.count, for: connection)
        #expect(receivedData == testData)
        
        // Send response from server
        let responseData = Data("Hello Client!".utf8)
        let responseSent = try await manager.write(responseData, for: connection)
        #expect(responseSent == responseData.count)
        
        // Read response on client
        let clientReceived = try await manager.read(responseData.count, for: client)
        #expect(clientReceived == responseData)
        
        // Cleanup
        await manager.remove(connection)
        try connection.close()
        await manager.remove(client)
        try client.close()
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
    
    @Test("IOCP UDP SendTo RecvFrom")
    func testIOCPUDPSendRecv() async throws {
        guard #available(Windows 10.0.22000, *) else {
            return // Skip test on older Windows
        }
        
        let manager = try IOCPSocketManager()
        
        // Create UDP sockets
        let server = try SocketDescriptor(IPv4Protocol.udp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        
        // Get actual server address
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Create client UDP socket
        let client = try SocketDescriptor(IPv4Protocol.udp)
        _ = await manager.add(client)
        
        // Send data from client to server
        let testData = Data("Hello UDP IOCP!".utf8)
        let bytesSent = try await manager.sendMessage(testData, to: boundAddress, for: client)
        #expect(bytesSent == testData.count)
        
        // Receive data on server
        let (receivedData, senderAddress) = try await manager.receiveMessage(
            testData.count + 100, // Extra space for safety
            fromAddressOf: IPv4SocketAddress.self,
            for: server
        )
        #expect(receivedData == testData)
        #expect(senderAddress.address == IPv4Address.loopback)
        
        // Send response from server to client
        let responseData = Data("Hello UDP Client!".utf8)
        let responseSent = try await manager.sendMessage(responseData, to: senderAddress, for: server)
        #expect(responseSent == responseData.count)
        
        // Bind client to receive (optional, but ensures we have a port)
        let clientBindAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try client.bind(clientBindAddress)
        let clientBoundAddress = try client.address(IPv4SocketAddress.self)
        
        // Receive response on client
        let (clientReceived, serverResponseAddress) = try await manager.receiveMessage(
            responseData.count + 100,
            fromAddressOf: IPv4SocketAddress.self,
            for: client
        )
        #expect(clientReceived == responseData)
        #expect(serverResponseAddress.port == boundAddress.port)
        
        // Cleanup
        await manager.remove(client)
        try client.close()
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
}
#endif