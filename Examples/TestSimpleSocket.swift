//
//  TestSimpleSocket.swift
//  
//
//  Test creating a simple socket to isolate the crash
//

print("Starting simple socket test...")

import Socket

print("Socket module imported successfully")

// Try the exact same pattern as the test
print("\nTrying to create IPv4 TCP socket...")
do {
    let socket = try await Socket(IPv4Protocol.tcp)
    print("✓ Socket created successfully")
    await socket.close()
    print("✓ Socket closed successfully")
} catch {
    print("✗ Error creating socket: \(error)")
}

print("\nTest completed")