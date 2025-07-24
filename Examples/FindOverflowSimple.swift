//
//  FindOverflowSimple.swift
//  
//
//  Simple test to find the overflow
//

// Test 1: Just import without using anything
print("Test 1: Importing Socket...")
import Socket
print("✓ Import succeeded")

// Test 2: Access a simple constant
print("\nTest 2: Accessing simple constant...")
let family = SocketAddressFamily.ipv4
print("✓ Got family: \(family)")

// Test 3: Access IPv4Protocol
print("\nTest 3: Accessing IPv4Protocol.tcp...")
let proto = IPv4Protocol.tcp
print("✓ Got protocol: \(proto)")

// Test 4: Try creating socket type
print("\nTest 4: Getting socket type...")
let sockType = proto.type
print("✓ Got type: \(sockType)")

// Test 5: Access raw values
print("\nTest 5: Getting raw values...")
print("Family raw: \(family.rawValue)")
print("Type raw: \(sockType.rawValue)")
print("Protocol raw: \(proto.rawValue)")

print("\nAll basic tests passed!")