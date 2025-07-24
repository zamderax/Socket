//
//  MinimalTest.swift
//  
//
//  Minimal test to isolate crash
//

print("1. Starting MinimalTest")

// Test importing just the module
import Socket

print("2. Module imported")

// Test using a simple constant
print("3. Testing AF_INET constant")
let family = SocketAddressFamily.ipv4
print("4. Family: \(family)")

// Test protocol
print("5. Testing protocol constant")
let proto = IPv4Protocol.tcp.rawValue
print("6. Protocol raw value: \(proto)")

print("7. Done - no crash!")