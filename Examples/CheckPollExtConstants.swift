//
//  CheckPollExtConstants.swift
//  
//
//  Check extended POLL constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking extended POLL constants on Windows:")

let pollConstants: [(String, Int32)] = [
    ("POLLRDNORM", POLLRDNORM),
    ("POLLWRNORM", POLLWRNORM),
    ("POLLRDBAND", POLLRDBAND),
    ("POLLWRBAND", POLLWRBAND)
]

print("\nValues:")
for (name, value) in pollConstants {
    print("\(name): \(value) (0x\(String(UInt32(bitPattern: value), radix: 16)))")
    
    // Check if it fits in Int16
    if value > Int16.max || value < Int16.min {
        print("  ERROR: DOES NOT FIT IN Int16!")
        // Check if the upper bits are set
        if (UInt32(bitPattern: value) & 0xFFFF0000) != 0 {
            let upperBits = (UInt32(bitPattern: value) >> 16)
            print("  Upper 16 bits are set: 0x\(String(upperBits, radix: 16))")
        }
    } else {
        print("  ✓ fits in Int16")
    }
}

// Try numericCast
print("\nTrying numericCast to Int16:")
for (name, value) in pollConstants {
    if value <= Int16.max && value >= Int16.min {
        let int16Value: Int16 = Int16(value)
        print("\(name) -> Int16: \(int16Value)")
    } else {
        print("\(name) -> WOULD OVERFLOW!")
    }
}

#else
print("This test is for Windows only")
#endif