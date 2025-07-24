import Socket
import Foundation

print("Attempting to reproduce the numericCast crash...")

// Test 1: Direct access to constants
print("\n1. Testing IPv4Address constants...")
print("IPv4Address.any: \(IPv4Address.any)")
print("IPv4Address.loopback: \(IPv4Address.loopback)")

// Create a semaphore to wait for async operations
let semaphore = DispatchSemaphore(value: 0)

// Test 2: Create a socket (this might trigger the issue)
print("\n2. Creating IPv4 TCP socket...")
Task {
    do {
        let socket = try await Socket(IPv4Protocol.tcp)
        print("✓ Socket created successfully")
        await socket.close()
        print("✓ Socket closed")
    } catch {
        print("✗ Socket creation failed: \(error)")
    }
    semaphore.signal()
}

// Wait for async task to complete
semaphore.wait()

// Test 3: Try creating socket addresses
print("\n3. Creating socket addresses...")
let addr4 = IPv4SocketAddress(address: .loopback, port: 12345)
print("IPv4 address created: \(addr4.address):\(addr4.port)")

let addr6 = IPv6SocketAddress(address: .loopback, port: 12345)
print("IPv6 address created: \(addr6.address):\(addr6.port)")

// Test 4: Try the connect operation directly
print("\n4. Testing connect operation...")
Task {
    do {
        let socket = try await Socket(IPv4Protocol.tcp)
        let address = IPv4SocketAddress(address: .loopback, port: 54321)
        
        // This is where the crash might happen
        print("Attempting to connect...")
        do {
            try await socket.connect(to: address)
            print("✓ Connected (unexpected!)")
        } catch {
            print("✗ Connection failed (expected): \(error)")
        }
        
        await socket.close()
    } catch {
        print("✗ Socket operation failed: \(error)")
    }
    semaphore.signal()
}

// Wait for async task to complete
semaphore.wait()

print("\nTest completed without crash!")