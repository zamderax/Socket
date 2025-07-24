//
//  IOCPStressTests.swift
//  
//
//  Stress tests for Windows IOCP implementation
//

#if os(Windows)
import Foundation
import Testing
import Socket
import SystemPackage

@Suite("IOCP Stress Tests")
@available(Windows 10.0.22000, *)
struct IOCPStressTests {
    
    @Test("Rapid Connect/Disconnect")
    func testRapidConnectDisconnect() async throws {
        let manager = try IOCPSocketManager()
        let iterations = 20
        
        // Create server
        let server = try SocketDescriptor(IPv4Protocol.tcp)
        _ = await manager.add(server)
        
        let serverAddress = IPv4SocketAddress(address: .loopback, port: 0)
        try server.bind(serverAddress)
        try await manager.listen(backlog: iterations, for: server)
        
        let boundAddress = try server.address(IPv4SocketAddress.self)
        
        // Server accept loop
        let serverTask = Task {
            var connections: [SocketDescriptor] = []
            for _ in 0..<iterations {
                let conn = try await manager.accept(for: server)
                connections.append(conn)
            }
            
            // Close all connections
            for conn in connections {
                await manager.remove(conn)
                try conn.close()
            }
        }
        
        // Rapid client connections
        for i in 0..<iterations {
            let client = try SocketDescriptor(IPv4Protocol.tcp)
            _ = await manager.add(client)
            
            try await manager.connect(to: boundAddress, for: client)
            
            // Send quick message
            let data = Data("Message \(i)".utf8)
            _ = try await manager.write(data, for: client)
            
            // Close immediately
            await manager.remove(client)
            try client.close()
        }
        
        // Wait for server to finish
        try await serverTask.value
        
        // Cleanup
        await manager.remove(server)
        try server.close()
        await manager.cleanup()
    }
    
    @Test("Concurrent UDP Messages")
    func testConcurrentUDPMessages() async throws {
        let manager = try IOCPSocketManager()
        let messageCount = 50
        
        // Create UDP socket
        let socket = try SocketDescriptor(IPv4Protocol.udp)
        _ = await manager.add(socket)
        
        let address = IPv4SocketAddress(address: .loopback, port: 0)
        try socket.bind(address)
        let boundAddress = try socket.address(IPv4SocketAddress.self)
        
        // Receive task
        let receiveTask = Task {
            var received = 0
            while received < messageCount {
                let (data, _) = try await manager.receiveMessage(
                    256,
                    fromAddressOf: IPv4SocketAddress.self,
                    for: socket
                )
                if data.count > 0 {
                    received += 1
                }
            }
            return received
        }
        
        // Send messages concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<messageCount {
                group.addTask {
                    let message = "UDP Message \(i)"
                    let data = Data(message.utf8)
                    _ = try await manager.sendMessage(data, to: boundAddress, for: socket)
                }
            }
            
            try await group.waitForAll()
        }
        
        // Verify all messages received
        let totalReceived = try await receiveTask.value
        #expect(totalReceived == messageCount)
        
        // Cleanup
        await manager.remove(socket)
        try socket.close()
        await manager.cleanup()
    }
}
#endif