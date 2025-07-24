//
//  TestNumericCast.swift
//  
//
//  Test numericCast to find the issue
//

#if os(Windows)
import WinSDK

print("Testing numericCast on Windows constants...")

// Test MSG constants
print("\nMSG constants:")
print("MSG_OOB: \(MSG_OOB) (type: \(type(of: MSG_OOB)))")
print("MSG_PEEK: \(MSG_PEEK)")
print("MSG_DONTROUTE: \(MSG_DONTROUTE)")
print("MSG_WAITALL: \(MSG_WAITALL)")
print("MSG_TRUNC: \(MSG_TRUNC)")
print("MSG_CTRUNC: \(MSG_CTRUNC)")

// Try numericCast on each
print("\nTrying numericCast to CInt:")
do {
    print("MSG_OOB -> CInt: \(numericCast(MSG_OOB) as CInt)")
    print("MSG_PEEK -> CInt: \(numericCast(MSG_PEEK) as CInt)")  
    print("MSG_DONTROUTE -> CInt: \(numericCast(MSG_DONTROUTE) as CInt)")
    print("MSG_WAITALL -> CInt: \(numericCast(MSG_WAITALL) as CInt)")
    print("MSG_TRUNC -> CInt: \(numericCast(MSG_TRUNC) as CInt)")
    print("MSG_CTRUNC -> CInt: \(numericCast(MSG_CTRUNC) as CInt)")
} catch {
    print("Error during numericCast!")
}

// Check if any are negative or too large
let msgConstants: [(String, Int32)] = [
    ("MSG_OOB", MSG_OOB),
    ("MSG_PEEK", MSG_PEEK),
    ("MSG_DONTROUTE", MSG_DONTROUTE),
    ("MSG_WAITALL", MSG_WAITALL),
    ("MSG_TRUNC", MSG_TRUNC),
    ("MSG_CTRUNC", MSG_CTRUNC)
]

print("\nChecking for problematic values:")
for (name, value) in msgConstants {
    if value < 0 {
        print("WARNING: \(name) is negative: \(value)")
    }
    if value > Int32.max / 2 {
        print("WARNING: \(name) is very large: \(value) (0x\(String(value, radix: 16)))")
    }
}

#else
print("This test is for Windows only")
#endif