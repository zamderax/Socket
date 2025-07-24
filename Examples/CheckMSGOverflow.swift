#if os(Windows)
import WinSDK

print("Checking for MSG constant overflow on Windows...")

// Check each MSG constant to see if it might overflow when cast to CInt
let msgConstants: [(String, Int32)] = [
    ("MSG_OOB", MSG_OOB),
    ("MSG_PEEK", MSG_PEEK),
    ("MSG_DONTROUTE", MSG_DONTROUTE),
    ("MSG_WAITALL", MSG_WAITALL),
    ("MSG_PARTIAL", MSG_PARTIAL),
    ("MSG_INTERRUPT", MSG_INTERRUPT),
    ("MSG_MAXIOVLEN", MSG_MAXIOVLEN)
]

print("\nChecking MSG constants:")
for (name, value) in msgConstants {
    print("\(name): \(value) (0x\(String(format: "%08X", UInt32(bitPattern: value))))")
    
    // Check if this would overflow when used with numericCast
    if value < 0 {
        print("  WARNING: \(name) is negative!")
        // Check if it's exactly Int32.min which would cause issues
        if value == Int32.min {
            print("  CRITICAL: \(name) equals Int32.min - this will crash numericCast!")
        }
    }
}

// MSG_PARTIAL on Windows is defined as 0x8000, which when interpreted as Int32 
// could be problematic if it's being treated as unsigned somewhere
print("\n\nDirect check of MSG_PARTIAL:")
let partial = MSG_PARTIAL
print("MSG_PARTIAL = \(partial)")
print("MSG_PARTIAL as UInt32 = \(UInt32(bitPattern: partial))")

// The issue might be that MSG_PARTIAL (0x8000) is being used somewhere
// and when cast from UInt to Int, it overflows

#else
print("This test is for Windows only")
#endif