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
    
    print("Binding server to port \(port)...")
    try server.fileDescriptor.bind(address)
    
    print("Starting to listen...")
    try await server.listen()
    
    print("Server listening on port \(port)")
    
    // Create client socket
    let client = try await Socket(IPv4Protocol.tcp)
    
    // Connect in background
    let connectTask = Task {
        print("Client connecting to port \(port)...")
        try await client.connect(to: IPv4SocketAddress(address: .loopback, port: port))
        print("Client connected!")
    }
    
    // Accept connection
    print("Server waiting for connection...")
    let connection = try await server.accept()
    print("Server accepted connection: \(connection.fileDescriptor)")
    
    // Wait for client to finish connecting
    try await connectTask.value
    
    // Send data from client to server
    let testData = Data("Hello from client".utf8)
    print("Client sending data...")
    let sent = try await client.write(testData)
    print("Client sent \(sent) bytes")
    
    // Receive data on server
    print("Server reading data...")
    let received = try await connection.read(testData.count)
    print("Server received: \(String(data: received, encoding: .utf8) ?? "?")")
    
    #expect(received == testData)
    
    // Clean up
    await connection.close()
    await client.close()
    await server.close()
    
    print("Test completed successfully!")
}