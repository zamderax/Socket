//
//  CheckINADDRConstants.swift
//  
//
//  Check INADDR constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking INADDR constants on Windows:")

print("\nINADDR_ANY:")
print("  Type: \(type(of: INADDR_ANY))")
print("  Value: \(INADDR_ANY) (0x\(String(INADDR_ANY, radix: 16)))")

print("\nINADDR_LOOPBACK:")
print("  Type: \(type(of: INADDR_LOOPBACK))")
print("  Value: \(INADDR_LOOPBACK) (0x\(String(INADDR_LOOPBACK, radix: 16)))")

print("\nINADDR_BROADCAST:")
print("  Type: \(type(of: INADDR_BROADCAST))")
print("  Value: \(INADDR_BROADCAST) (0x\(String(INADDR_BROADCAST, radix: 16)))")

print("\nINADDR_NONE:")
print("  Type: \(type(of: INADDR_NONE))")
print("  Value: \(INADDR_NONE) (0x\(String(INADDR_NONE, radix: 16)))")

// Check if they fit in different types
print("\nChecking type conversions:")
print("Can INADDR_ANY fit in UInt32? \(INADDR_ANY <= UInt32.max)")
print("Can INADDR_LOOPBACK fit in UInt32? \(INADDR_LOOPBACK <= UInt32.max)")
print("Can INADDR_BROADCAST fit in UInt32? \(INADDR_BROADCAST <= UInt32.max)")
print("Can INADDR_NONE fit in UInt32? \(INADDR_NONE <= UInt32.max)")

// Try casting
print("\nTrying casts:")
do {
    let anyAddr: UInt32 = numericCast(INADDR_ANY)
    print("INADDR_ANY -> UInt32: \(anyAddr)")
} catch {
    print("INADDR_ANY -> UInt32: FAILED")
}

do {
    let loopback: UInt32 = numericCast(INADDR_LOOPBACK)
    print("INADDR_LOOPBACK -> UInt32: \(loopback)")
} catch {
    print("INADDR_LOOPBACK -> UInt32: FAILED")
}

#else
print("This test is for Windows only")
#endif