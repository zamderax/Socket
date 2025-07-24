//
//  TestDirectCrash.swift
//  
//
//  Try to replicate the exact crash scenario
//

import Socket

print("Testing direct crash scenario...")

// The crash happens in tests, particularly when multiple tests run concurrently
// Let's try to replicate what the tests are doing

print("\nCreating multiple sockets concurrently...")

// Create a simple async function that creates a socket
func createSocket() async throws {
    let socket = try await Socket(IPv4Protocol.tcp)
    print("Created socket: \(socket.fileDescriptor)")
    await socket.close()
}

// Run multiple socket creations concurrently
print("\nRunning concurrent socket operations...")
await withTaskGroup(of: Void.self) { group in
    for i in 0..<5 {
        group.addTask {
            do {
                try await createSocket()
            } catch {
                print("Error creating socket \(i): \(error)")
            }
        }
    }
}

print("\nAll concurrent operations completed!")

// Now let's try what the failing test does - enumerate network interfaces
print("\nTrying network interface enumeration...")
do {
    let ipv4Interfaces = try NetworkInterface<IPv4SocketAddress>.interfaces
    print("Found \(ipv4Interfaces.count) IPv4 interfaces")
    
    let ipv6Interfaces = try NetworkInterface<IPv6SocketAddress>.interfaces
    print("Found \(ipv6Interfaces.count) IPv6 interfaces")
} catch {
    print("Error enumerating interfaces: \(error)")
}

print("\nTest completed!")