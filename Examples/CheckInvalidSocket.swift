//
//  CheckInvalidSocket.swift
//  
//
//  Check INVALID_SOCKET value
//

#if os(Windows)
import CSocket

print("INVALID_SOCKET type: \(type(of: INVALID_SOCKET))")
print("INVALID_SOCKET value: \(INVALID_SOCKET)")
print("INVALID_SOCKET hex: 0x\(String(INVALID_SOCKET, radix: 16))")

// Try creating SocketDescriptor with it
// This is what happens in the static initializer
print("\nTrying to create SocketDescriptor with INVALID_SOCKET...")

// Don't actually create it since that might crash
// Just check the types
print("SocketDescriptor.RawValue type: \(SocketDescriptor.RawValue.self)")

#else
print("This test is for Windows only")
#endif