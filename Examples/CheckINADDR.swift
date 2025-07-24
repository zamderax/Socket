//
//  CheckINADDR.swift
//  
//
//  Check INADDR constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking INADDR constants:")

print("\nINADDR_ANY:")
print("Value: \(INADDR_ANY)")
print("Type: \(type(of: INADDR_ANY))")
print("Hex: 0x\(String(INADDR_ANY, radix: 16))")

print("\nINADDR_LOOPBACK:")
print("Value: \(INADDR_LOOPBACK)")
print("Type: \(type(of: INADDR_LOOPBACK))")
print("Hex: 0x\(String(INADDR_LOOPBACK, radix: 16))")

// Check if they fit in Int32
print("\nCan convert to Int32:")
print("INADDR_ANY: \(Int32(exactly: INADDR_ANY) != nil)")
print("INADDR_LOOPBACK: \(Int32(exactly: INADDR_LOOPBACK) != nil)")

// Try the conversion
if let anyValue = Int32(exactly: INADDR_ANY) {
    print("INADDR_ANY as Int32: \(anyValue)")
} else {
    print("INADDR_ANY doesn't fit in Int32!")
}

if let loopback = Int32(exactly: INADDR_LOOPBACK) {
    print("INADDR_LOOPBACK as Int32: \(loopback)")
} else {
    print("INADDR_LOOPBACK doesn't fit in Int32!")
}

#else
print("This test is for Windows only")
#endif