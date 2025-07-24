//
//  CheckWSAPOLLFD.swift
//  
//
//  Check WSAPOLLFD structure on Windows
//

#if os(Windows)
import WinSDK

print("Checking WSAPOLLFD structure on Windows:")

// Create a WSAPOLLFD
var pollfd = WSAPOLLFD()
pollfd.fd = INVALID_SOCKET
pollfd.events = Int16(POLLIN)
pollfd.revents = 0

print("\nWSAPOLLFD fields:")
print("fd type: \(type(of: pollfd.fd))")
print("events type: \(type(of: pollfd.events))")
print("revents type: \(type(of: pollfd.revents))")

print("\nField sizes:")
print("events is Int16: \(type(of: pollfd.events) == Int16.self)")
print("revents is Int16: \(type(of: pollfd.revents) == Int16.self)")

print("\nTesting assignments:")
pollfd.events = Int16(POLLIN)
print("Can assign POLLIN to events: ✓")

pollfd.events = Int16(POLLOUT)
print("Can assign POLLOUT to events: ✓")

// Test bitwise operations
pollfd.events = Int16(POLLIN) | Int16(POLLOUT)
print("Can combine POLLIN | POLLOUT: ✓")

#else
print("This test is for Windows only")
#endif