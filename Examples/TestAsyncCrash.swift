//
//  TestAsyncCrash.swift
//  
//
//  Minimal async crash test
//

import Socket

print("Testing async crash...")

// Just try to create a socket - this should trigger AsyncSocketManager.shared
do {
    print("Creating socket...")
    let socket = try await Socket(IPv4Protocol.tcp)
    print("Socket created: \(socket.fileDescriptor)")
    await socket.close()
    print("Socket closed")
} catch {
    print("Error: \(error)")
}

print("Test completed!")