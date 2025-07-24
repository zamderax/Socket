//
//  MinimalRepro.swift
//  
//
//  Minimal reproduction of the overflow crash
//

print("Starting minimal repro...")

// Import Socket module - this might trigger the crash during initialization
print("Importing Socket...")
import Socket
print("✓ Import succeeded")

// Try accessing constants that use numericCast
print("\nAccessing constants...")

// Test IPPROTO constants
print("IPPROTO_TCP: \(IPv4Protocol.tcp.rawValue)")
print("IPPROTO_UDP: \(IPv4Protocol.udp.rawValue)")

// Test socket types
print("SOCK_STREAM: \(SocketType.stream.rawValue)")
print("SOCK_DGRAM: \(SocketType.datagram.rawValue)")

// Test FileEvents
print("POLLIN: \(FileEvents.read.rawValue)")
print("POLLOUT: \(FileEvents.write.rawValue)")

print("\nAll tests passed!")