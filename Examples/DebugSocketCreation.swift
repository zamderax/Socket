//
//  DebugSocketCreation.swift
//  
//
//  Debug Socket creation to find overflow
//

import Foundation
import Socket
import SystemPackage

print("Debugging Socket creation...")

do {
    print("\n1. Creating IPv4SocketAddress...")
    let port = UInt16(27139) // Same port from the test log
    print("Port: \(port)")
    
    let address = IPv4SocketAddress(address: .any, port: port)
    print("Address created successfully")
    
    print("\n2. Creating Socket...")
    let socket = try Socket(
        IPv4Protocol.tcp,
        bind: address
    )
    print("Socket created successfully: \(socket.fileDescriptor)")
    
    socket.close()
    print("Socket closed")
    
} catch {
    print("Error: \(error)")
}

print("\nDebug complete.")