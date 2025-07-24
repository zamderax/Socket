#if os(Windows)
import WinSDK

print("Checking MSG constant values on Windows...")

let msgConstants: [(String, Any)] = [
    ("MSG_OOB", MSG_OOB),
    ("MSG_PEEK", MSG_PEEK),
    ("MSG_DONTROUTE", MSG_DONTROUTE),
    ("MSG_WAITALL", MSG_WAITALL),
    ("MSG_PARTIAL", MSG_PARTIAL),
    ("MSG_INTERRUPT", MSG_INTERRUPT),
    ("MSG_MAXIOVLEN", MSG_MAXIOVLEN)
]

print("\nRaw values:")
for (name, value) in msgConstants {
    print("\(name): \(value) (type: \(type(of: value)))")
}

// Check if any might overflow when cast to Int32
print("\n\nChecking for potential overflow:")
print("Int32.max = \(Int32.max) (0x\(String(Int32.max, radix: 16)))")

// MSG_PARTIAL is known to be problematic on Windows
if let msgPartial = MSG_PARTIAL as? Int32 {
    print("MSG_PARTIAL as Int32: \(msgPartial) (0x\(String(msgPartial, radix: 16)))")
    if msgPartial < 0 {
        print("WARNING: MSG_PARTIAL is negative!")
    }
}

// Check if MSG_PARTIAL might be the issue
print("\nDirect check of MSG_PARTIAL:")
print("MSG_PARTIAL = \(MSG_PARTIAL)")
print("MSG_PARTIAL hex = 0x\(String(MSG_PARTIAL, radix: 16))")

// Check if it's negative (high bit set)
if MSG_PARTIAL == -2147483648 {  // This is 0x80000000
    print("WARNING: MSG_PARTIAL equals Int32.min!")
}

// Try to reproduce the crash
print("\nTrying to cast MSG_PARTIAL to CInt...")
let partialAsCInt: CInt = numericCast(MSG_PARTIAL)
print("Success: MSG_PARTIAL -> CInt = \(partialAsCInt)")

#else
print("This test is for Windows only")
#endif