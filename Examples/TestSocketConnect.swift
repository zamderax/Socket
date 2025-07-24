import Socket
import CSocket

print("Testing socket connect with numericCast...")

// Test creating a socket descriptor
print("\nCreating socket descriptor...")
let fd = socket(AF_INET, SOCK_STREAM, 0)
if fd == INVALID_SOCKET {
    print("Failed to create socket")
} else {
    print("Socket created: \(fd)")
    
    // Create an IPv4 address
    var addr = sockaddr_in()
    addr.sin_family = UInt16(AF_INET)
    addr.sin_port = UInt16(12345).bigEndian
    #if os(Windows)
    addr.sin_addr.S_un.S_addr = inet_addr("127.0.0.1")
    #else
    addr.sin_addr.s_addr = inet_addr("127.0.0.1")
    #endif
    
    print("\nAddress info:")
    print("Size of sockaddr_in: \(MemoryLayout<sockaddr_in>.size)")
    print("Size as UInt32: \(UInt32(MemoryLayout<sockaddr_in>.size))")
    
    // Test the numeric cast that happens in connect
    let sizeAsUInt32 = UInt32(MemoryLayout<sockaddr_in>.size)
    print("\nTrying numericCast from UInt32 to Int...")
    let sizeAsInt: Int = numericCast(sizeAsUInt32)
    print("Success: \(sizeAsUInt32) -> \(sizeAsInt)")
    
    // Now try to connect (this will fail but shouldn't crash)
    print("\nAttempting connect...")
    withUnsafeBytes(of: &addr) { bytes in
        let sockaddrPtr = bytes.bindMemory(to: sockaddr.self).baseAddress!
        let result = connect(fd, sockaddrPtr, Int32(MemoryLayout<sockaddr_in>.size))
        if result == SOCKET_ERROR {
            print("Connect failed (expected): \(WSAGetLastError())")
        } else {
            print("Connect succeeded (unexpected)")
        }
    }
    
    closesocket(fd)
    print("\nSocket closed")
}

// Test with larger values that might overflow
print("\n\nTesting potential overflow scenarios...")

// Test converting various UInt32 values to Int32
let testValues: [UInt32] = [
    0,
    100,
    UInt32(Int32.max),
    UInt32(Int32.max) + 1,
    UInt32.max
]

for value in testValues {
    print("\nTesting UInt32(\(value)) -> Int32:")
    if value <= Int32.max {
        let converted: Int32 = numericCast(value)
        print("  Success: \(converted)")
    } else {
        print("  Would overflow - skipping to avoid crash")
    }
}

// Check what happens with socket address lengths
print("\n\nChecking socket address struct sizes:")
print("sockaddr: \(MemoryLayout<sockaddr>.size)")
print("sockaddr_in: \(MemoryLayout<sockaddr_in>.size)")
print("sockaddr_in6: \(MemoryLayout<sockaddr_in6>.size)")
print("sockaddr_storage: \(MemoryLayout<sockaddr_storage>.size)")

// All of these should be small enough to fit in Int32
print("\nAll sizes fit in Int32? \(MemoryLayout<sockaddr_storage>.size <= Int32.max)")