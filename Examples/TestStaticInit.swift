//
//  TestStaticInit.swift
//  
//
//  Test static initialization of CInternetAddress
//

print("Starting static init test...")

// First check raw constants before importing Socket
#if os(Windows)
import WinSDK

print("\nRaw constants before Socket import:")
print("INET_ADDRSTRLEN: \(INET_ADDRSTRLEN) (type: \(type(of: INET_ADDRSTRLEN)))")
print("INET6_ADDRSTRLEN: \(INET6_ADDRSTRLEN) (type: \(type(of: INET6_ADDRSTRLEN)))")

// Check if these are actually CInt
let inetAsInt32: Int32 = INET_ADDRSTRLEN
let inet6AsInt32: Int32 = INET6_ADDRSTRLEN
print("As Int32: \(inetAsInt32), \(inet6AsInt32)")

#endif

print("\nImporting Socket...")
import Socket
print("✓ Import succeeded")

// Try to access the static properties that use numericCast
print("\nAccessing CInterop.IPv4Address.stringLength...")
let v4len = CInterop.IPv4Address.stringLength
print("✓ IPv4Address.stringLength = \(v4len)")

print("\nAccessing CInterop.IPv6Address.stringLength...")
let v6len = CInterop.IPv6Address.stringLength
print("✓ IPv6Address.stringLength = \(v6len)")

print("\nAll tests passed!")