//
//  IOCPIntegrationTests.swift
//  
//
//  Integration tests for Windows IOCP implementation
//

#if os(Windows)
import Foundation
import Testing
import Socket
import SystemPackage

@Suite("IOCP Integration Tests")
struct IOCPIntegrationTests {
    
    @Test("Large Data Transfer")
    @available(Windows 10.0.22000, *)
    func testLargeDataTransfer() async throws {
        
        let manager = try IOCPSocketManager()
        
        // Create server
        let server = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        try await manager.listen(backlog: 5, for: server)
        
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Create client
        let client = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(client)
        
        // Accept task
        let acceptTask = Task {
            try await manager.accept(for: server)
        }
        
        // Connect
        try await manager.connect(to: boundAddress, for: client)
        let connection = try await acceptTask.value
        _ = await manager.add(connection)
        
        // Create large data (1MB)
        let largeData = Data(repeating: 0xAB, count: 1024 * 1024)
        
        // Send in chunks
        let chunkSize = 64 * 1024 // 64KB chunks
        var totalSent = 0
        
        for offset in stride(from: 0, to: largeData.count, by: chunkSize) {
            let end = min(offset + chunkSize, largeData.count)
            let chunk = largeData[offset..<end]
            let sent = try await manager.write(Data(chunk), for: client)
            totalSent += sent
        }
        
        #expect(totalSent == largeData.count)
        
        // Receive and verify
        var received = Data()
        while received.count < largeData.count {
            let chunk = try await manager.read(chunkSize, for: connection)
            received.append(chunk)
        }
        
        #expect(received == largeData)
        
        // Cleanup
        await manager.remove(connection)
        try connection.close()
        await manager.remove(client)
        try client.close()
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
    
    @Test("Multiple Concurrent Connections")
    @available(Windows 10.0.22000, *)
    func testMultipleConcurrentConnections() async throws {
        
        let manager = try IOCPSocketManager()
        let connectionCount = 10
        
        // Create server
        let server = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        try await manager.listen(backlog: connectionCount, for: server)
        
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Accept connections task
        let acceptTask = Task {
            var connections: [SocketDescriptor] = []
            for _ in 0..<connectionCount {
                let conn = try await manager.accept(for: server)
                _ = await manager.add(conn)
                connections.append(conn)
            }
            return connections
        }
        
        // Create multiple clients
        var clients: [SocketDescriptor] = []
        for _ in 0..<connectionCount {
            let client = try SocketDescriptor(IPv4Protocol.tcp)
            _ = await manager.add(client)
            clients.append(client)
        }
        
        // Connect all clients concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, client) in clients.enumerated() {
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(index) * 1_000_000) // Small delay
                    try await manager.connect(to: boundAddress, for: client)
                }
            }
            
            try await group.waitForAll()
        }
        
        // Get server connections
        let connections = try await acceptTask.value
        #expect(connections.count == connectionCount)
        
        // Send unique data from each client
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, client) in clients.enumerated() {
                group.addTask {
                    let message = "Hello from client \(index)"
                    let data = Data(message.utf8)
                    let sent = try await manager.write(data, for: client)
                    #expect(sent == data.count)
                }
            }
            
            try await group.waitForAll()
        }
        
        // Read from all connections
        var receivedMessages = Set<String>()
        try await withThrowingTaskGroup(of: String.self) { group in
            for conn in connections {
                group.addTask {
                    let data = try await manager.read(100, for: conn)
                    return String(data: data, encoding: .utf8) ?? ""
                }
            }
            
            for try await message in group {
                receivedMessages.insert(message)
            }
        }
        
        // Verify we received all unique messages
        #expect(receivedMessages.count == connectionCount)
        for i in 0..<connectionCount {
            #expect(receivedMessages.contains("Hello from client \(i)"))
        }
        
        // Cleanup
        for conn in connections {
            await manager.remove(conn)
            try conn.close()
        }
        for client in clients {
            await manager.remove(client)
            try client.close()
        }
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
    
    @Test("UDP Broadcast")
    @available(Windows 10.0.22000, *)
    func testUDPBroadcast() async throws {
        
        let manager = try IOCPSocketManager()
        
        // Create receivers
        var receivers: [(socket: SocketDescriptor, address: IPv4SocketAddress)] = []
        for i in 0..<3 {
            let receiver = try SocketDescriptor(IPv4Protocol.udp)
            _ = await manager.add(receiver)
            
            // Enable SO_REUSEADDR
            
            let address = IPv4SocketAddress(address: .loopback, port: 0)
            try receiver.bind(address)
            let boundAddress = try receiver.address(IPv4SocketAddress.self)
            receivers.append((receiver, boundAddress))
        }
        
        // Create sender
        let sender = try SocketDescriptor(IPv4Protocol.udp)
        _ = await manager.add(sender)
        
        // Send to each receiver
        let message = "Broadcast message"
        let data = Data(message.utf8)
        
        for (_, address) in receivers {
            let sent = try await manager.sendMessage(data, to: address, for: sender)
            #expect(sent == data.count)
        }
        
        // Receive on all receivers
        var receivedCount = 0
        for (receiver, _) in receivers {
            let (receivedData, senderAddress) = try await manager.receiveMessage(
                100,
                fromAddressOf: IPv4SocketAddress.self,
                for: receiver
            )
            
            if let receivedMessage = String(data: receivedData, encoding: .utf8) {
                #expect(receivedMessage == message)
                receivedCount += 1
            }
        }
        
        #expect(receivedCount == 3)
        
        // Cleanup
        for (receiver, _) in receivers {
            await manager.remove(receiver)
            try receiver.close()
        }
        await manager.remove(sender)
        try sender.close()
        await manager.cleanup()
    }
    
    @Test("Echo Server Stress Test")
    @available(Windows 10.0.22000, *)
    func testEchoServerStress() async throws {
        
        let manager = try IOCPSocketManager()
        let messageCount = 100
        
        // Create echo server
        let server = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        try await manager.listen(backlog: 5, for: server)
        
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Echo server task
        let serverTask = Task {
            let connection = try await manager.accept(for: server)
            _ = await manager.add(connection)
            
            // Echo loop
            for _ in 0..<messageCount {
                let data = try await manager.read(256, for: connection)
                let sent = try await manager.write(data, for: connection)
                #expect(sent == data.count)
            }
            
            await manager.remove(connection)
            try connection.close()
        }
        
        // Create client
        let client = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(client)
        
        // Connect
        try await manager.connect(to: boundAddress, for: client)
        
        // Send and receive messages
        for i in 0..<messageCount {
            let message = "Message \(i) with some padding to make it longer"
            let sendData = Data(message.utf8)
            
            let sent = try await manager.write(sendData, for: client)
            #expect(sent == sendData.count)
            
            let received = try await manager.read(sendData.count, for: client)
            #expect(received == sendData)
        }
        
        // Wait for server to complete
        try await serverTask.value
        
        // Cleanup
        await manager.remove(client)
        try client.close()
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
    
    @Test("Mixed TCP and UDP Operations")
    @available(Windows 10.0.22000, *)
    func testMixedTCPAndUDP() async throws {
        
        let manager = try IOCPSocketManager()
        
        // Create TCP server
        let tcpServer = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(tcpServer)
        try tcpServer.bind(IPv4SocketAddress(address: .loopback, port: 0))
        try await manager.listen(backlog: 1, for: tcpServer)
        let tcpAddress = try tcpServer.address(IPv4SocketAddress.self)
        
        // Create UDP socket
        let udpSocket = try SocketDescriptor(IPv4Protocol.udp)
        _ = await manager.add(udpSocket)
        try udpSocket.bind(IPv4SocketAddress(address: .loopback, port: 0))
        let udpAddress = try udpSocket.address(IPv4SocketAddress.self)
        
        // TCP accept task
        let tcpAcceptTask = Task {
            try await manager.accept(for: tcpServer)
        }
        
        // Create TCP client
        let tcpClient = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(tcpClient)
        
        // Connect TCP
        try await manager.connect(to: tcpAddress, for: tcpClient)
        let tcpConnection = try await tcpAcceptTask.value
        _ = await manager.add(tcpConnection)
        
        // Send data via TCP
        let tcpData = Data("TCP Message".utf8)
        let tcpSent = try await manager.write(tcpData, for: tcpClient)
        #expect(tcpSent == tcpData.count)
        
        // Send data via UDP
        let udpData = Data("UDP Message".utf8)
        let udpSent = try await manager.sendMessage(udpData, to: udpAddress, for: udpSocket)
        #expect(udpSent == udpData.count)
        
        // Receive TCP data
        let tcpReceived = try await manager.read(tcpData.count, for: tcpConnection)
        #expect(tcpReceived == tcpData)
        
        // Receive UDP data
        let (udpReceived, _) = try await manager.receiveMessage(
            100,
            fromAddressOf: IPv4SocketAddress.self,
            for: udpSocket
        )
        #expect(udpReceived == udpData)
        
        // Cleanup
        await manager.remove(tcpConnection)
        try tcpConnection.close()
        await manager.remove(tcpClient)
        try tcpClient.close()
        await manager.remove(tcpServer)
        try tcpServer.close()
        await manager.remove(udpSocket)
        try udpSocket.close()
        await manager.cleanup()
    }
}
#endif