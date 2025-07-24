import Socket

print("Simple crash test...")

// Test 1: Access constants that might trigger the issue
print("\n1. IPv4Address constants:")
print("IPv4Address.any: \(IPv4Address.any)")
print("IPv4Address.loopback: \(IPv4Address.loopback)")

// Test 2: Create socket addresses
print("\n2. Socket addresses:")
let addr4 = IPv4SocketAddress(address: .loopback, port: 12345)
print("IPv4: \(addr4.address):\(addr4.port)")

let addr6 = IPv6SocketAddress(address: .loopback, port: 12345)
print("IPv6: \(addr6.address):\(addr6.port)")

// Test 3: Test address length calculation
print("\n3. Address sizes:")
addr4.withUnsafePointer { ptr, length in
    print("IPv4 address length: \(length)")
    return ()
}

addr6.withUnsafePointer { ptr, length in
    print("IPv6 address length: \(length)")
    return ()
}

print("\nTest completed!")