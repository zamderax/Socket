//
//  SimpleAsyncTest.swift
//  
//
//  Simple test for async socket functionality
//

import Testing
import Socket
import Foundation
import SystemPackage

@Test("Simple Async Socket")
func testSimpleAsyncSocket() async throws {
    // Create server socket
    let server = try await Socket(IPv4Protocol.tcp)
    let port = UInt16.random(in: 8080 ..< .max)
    let address = IPv4SocketAddress(address: .any, port: port)
    
    // Binding server to port
    try server.fileDescriptor.bind(address)
    
    // Starting to listen...
    try await server.listen()
    
    // Server listening on port
    
    // Create client socket
    let client = try await Socket(IPv4Protocol.tcp)
    
    // Connect in background
    let connectTask = Task {
        // Client connecting to port
        try await client.connect(to: IPv4SocketAddress(address: .loopback, port: port))
        // Client connected!
    }
    
    // Accept connection
    // Server waiting for connection...
    let connection = try await server.accept()
    // Server accepted connection
    
    // Wait for client to finish connecting
    try await connectTask.value
    
    // Send data from client to server
    let testData = Data("Hello from client".utf8)
    // Client sending data...
    let sent = try await client.write(testData)
    // Client sent bytes
    
    // Receive data on server
    // Server reading data...
    let received = try await connection.read(testData.count)
    // Server received data
    
    #expect(received == testData)
    
    // Clean up
    await connection.close()
    await client.close()
    await server.close()
    
    // Test completed successfully!
}