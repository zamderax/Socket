//
//  CheckIOControlID.swift
//  
//
//  Check IOControlID type on Windows
//

#if os(Windows)
import WinSDK

print("Checking IOControlID on Windows:")

// Check CUnsignedLong
print("\nCUnsignedLong type: \(String(describing: CUnsignedLong.self))")
print("CUnsignedLong size: \(MemoryLayout<CUnsignedLong>.size) bytes")

// Check the FIONBIO value
let fionbio: CUnsignedLong = 0x8004667e
print("\nFIONBIO value: 0x\(String(fionbio, radix: 16))")
print("FIONBIO as decimal: \(fionbio)")

// Check if it's negative when interpreted as signed
if let signedValue = Int32(exactly: fionbio) {
    print("FIONBIO fits in Int32: \(signedValue)")
} else {
    print("FIONBIO does NOT fit in Int32!")
    // This is likely the issue
    print("FIONBIO is too large for Int32: \(fionbio) > \(Int32.max)")
}

// The actual FIONBIO constant
print("\nActual FIONBIO constant: 0x\(String(FIONBIO, radix: 16))")
print("Type of FIONBIO: \(type(of: FIONBIO))")

#else
print("This test is for Windows only")
#endif