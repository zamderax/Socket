import Socket
import CSocket

print("Testing numericCast issue...")

// Test 1: Check socket address sizes
print("\nSocket address sizes:")
print("IPv4SocketAddress: \(MemoryLayout<CInterop.IPv4SocketAddress>.size)")
print("IPv6SocketAddress: \(MemoryLayout<CInterop.IPv6SocketAddress>.size)")

// Test 2: Check if sizes fit in Int32
print("\nChecking if sizes fit in Int32:")
print("Int32.max = \(Int32.max)")
print("IPv4 size fits? \(MemoryLayout<CInterop.IPv4SocketAddress>.size <= Int32.max)")
print("IPv6 size fits? \(MemoryLayout<CInterop.IPv6SocketAddress>.size <= Int32.max)")

// Test 3: Try the actual numericCast that fails
print("\nTrying numericCast:")
let ipv4Size = UInt32(MemoryLayout<CInterop.IPv4SocketAddress>.size)
let ipv4SizeAsInt: Int = numericCast(ipv4Size)
print("IPv4 size cast: \(ipv4Size) -> \(ipv4SizeAsInt)")

let ipv6Size = UInt32(MemoryLayout<CInterop.IPv6SocketAddress>.size)
let ipv6SizeAsInt: Int = numericCast(ipv6Size)
print("IPv6 size cast: \(ipv6Size) -> \(ipv6SizeAsInt)")

// Test 4: Check Int type on Windows
print("\nInt info:")
print("Type: \(type(of: Int.self))")
print("Size: \(MemoryLayout<Int>.size)")
print("Min: \(Int.min)")
print("Max: \(Int.max)")

// Test 5: Check Int32 type (what socklen_t is on Windows)
print("\nInt32 info:")
print("Type: \(type(of: Int32.self))")
print("Size: \(MemoryLayout<Int32>.size)")
print("Min: \(Int32.min)")
print("Max: \(Int32.max)")

// Test 6: Try some problematic conversions
print("\nTrying problematic conversions:")

// This should work - small positive value
let smallValue: UInt32 = 100
let smallInt: Int32 = numericCast(smallValue)
print("Small value: \(smallValue) -> \(smallInt)")

// This should fail if value > Int32.max
let largeValue: UInt32 = UInt32(Int32.max) + 1
print("Large value: \(largeValue) (0x\(String(largeValue, radix: 16)))")
print("Attempting to cast to Int32...")
// This line should crash if uncommented:
// let largeInt: Int32 = numericCast(largeValue)

// Test 7: Check specific INADDR values
print("\nChecking INADDR constants:")
print("IPv4Address.any: \(IPv4Address.any)")
print("IPv4Address.loopback: \(IPv4Address.loopback)")