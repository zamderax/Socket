//
//  CheckINETConstants.swift
//  
//
//  Check INET_ADDRSTRLEN constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking INET constants on Windows:")

print("\nINET_ADDRSTRLEN:")
print("  Type: \(type(of: INET_ADDRSTRLEN))")
print("  Value: \(INET_ADDRSTRLEN)")

print("\nINET6_ADDRSTRLEN:")
print("  Type: \(type(of: INET6_ADDRSTRLEN))")
print("  Value: \(INET6_ADDRSTRLEN)")

// Check if they fit in different types
print("\nChecking type conversions:")
print("Can INET_ADDRSTRLEN fit in Int? \(INET_ADDRSTRLEN <= Int.max)")
print("Can INET6_ADDRSTRLEN fit in Int? \(INET6_ADDRSTRLEN <= Int.max)")

// Check what _INET_ADDRSTRLEN is
print("\n_INET_ADDRSTRLEN (from Constants.swift):")
// We need to import Socket to get this
// But that might crash, so let's just check the raw value

// Try casting
print("\nTrying casts:")
let addrStrLen: Int = numericCast(INET_ADDRSTRLEN)
print("INET_ADDRSTRLEN -> Int: \(addrStrLen)")

let addr6StrLen: Int = numericCast(INET6_ADDRSTRLEN)
print("INET6_ADDRSTRLEN -> Int: \(addr6StrLen)")

#else
print("This test is for Windows only")
#endif