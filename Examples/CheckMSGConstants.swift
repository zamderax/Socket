#if os(Windows)
import WinSDK

print("Checking MSG constants on Windows...")

// Check the raw values
let msgConstants: [(String, Any)] = [
    ("MSG_OOB", MSG_OOB),
    ("MSG_PEEK", MSG_PEEK),
    ("MSG_DONTROUTE", MSG_DONTROUTE),
    ("MSG_WAITALL", MSG_WAITALL),
    ("MSG_TRUNC", MSG_TRUNC),
    ("MSG_CTRUNC", MSG_CTRUNC)
]

for (name, value) in msgConstants {
    print("\n\(name):")
    print("  Type: \(type(of: value))")
    if let intValue = value as? Int32 {
        print("  Value: \(intValue) (0x\(String(intValue, radix: 16)))")
        print("  Can fit in CInt? \(intValue >= CInt.min && intValue <= CInt.max)")
    } else if let uintValue = value as? UInt32 {
        print("  Value: \(uintValue) (0x\(String(uintValue, radix: 16)))")
        print("  Can fit in CInt? \(uintValue <= CInt.max)")
        if uintValue > CInt.max {
            print("  WARNING: Value exceeds CInt.max!")
        }
    } else {
        print("  Unknown type!")
    }
}

// Check specific problem values
print("\n\nChecking for overflow issues:")
print("CInt.max = \(CInt.max) (0x\(String(CInt.max, radix: 16)))")
print("Int32.max = \(Int32.max) (0x\(String(Int32.max, radix: 16)))")

#else
print("This test is for Windows only")
#endif