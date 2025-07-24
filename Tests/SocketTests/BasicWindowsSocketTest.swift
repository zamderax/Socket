//
//  BasicWindowsSocketTest.swift
//  
//
//  Basic test for Windows socket functionality
//

import Testing
import Socket
import Foundation
import SystemPackage

@Test("Basic Windows Socket")
func testBasicWindowsSocket() async throws {
    // Create a simple TCP socket
    let socket = try await Socket(IPv4Protocol.tcp)
    print("Created socket: \(socket.fileDescriptor)")
    
    // Bind to any available port
    let address = IPv4SocketAddress(address: .any, port: 0)
    try socket.fileDescriptor.bind(address)
    
    // Get the actual bound address
    let boundAddress = try socket.fileDescriptor.address(IPv4SocketAddress.self)
    print("Bound to: \(boundAddress)")
    
    // Close the socket
    await socket.close()
    print("Socket closed successfully")
    
    #expect(true)
}

