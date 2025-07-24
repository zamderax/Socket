//
//  CheckAF.swift
//  
//
//  Check AF constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking AF constants:")

print("\nAF_NETBIOS:")
print("Value: \(AF_NETBIOS)")
print("Type: \(type(of: AF_NETBIOS))")
print("Can convert to Int32: \(Int32(exactly: AF_NETBIOS) != nil)")

if let value = Int32(exactly: AF_NETBIOS) {
    print("AF_NETBIOS as Int32: \(value)")
} else {
    print("AF_NETBIOS doesn't fit in Int32! Value: \(AF_NETBIOS)")
}

// Check other AF constants
print("\nOther AF constants:")
print("AF_INET: \(AF_INET) (type: \(type(of: AF_INET)))")
print("AF_INET6: \(AF_INET6)")
print("AF_UNIX: \(AF_UNIX)")
print("AF_IRDA: \(AF_IRDA)")  
print("AF_BTH: \(AF_BTH)")

// Check if any are problematic
let afConstants: [(String, Int32)] = [
    ("AF_INET", AF_INET),
    ("AF_INET6", AF_INET6),
    ("AF_UNIX", AF_UNIX),
    ("AF_NETBIOS", AF_NETBIOS),
    ("AF_IRDA", AF_IRDA),
    ("AF_BTH", AF_BTH)
]

print("\nChecking all AF constants:")
for (name, value) in afConstants {
    if value < 0 || value > Int32.max {
        print("PROBLEM: \(name) = \(value)")
    }
}

#else
print("This test is for Windows only")
#endif