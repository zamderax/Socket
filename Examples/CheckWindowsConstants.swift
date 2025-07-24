#if os(Windows)
import WinSDK

print("Checking Windows socket constants that might overflow...")

// Check known problematic constants
print("\nMSG_PARTIAL: \(MSG_PARTIAL) (0x\(String(MSG_PARTIAL, radix: 16)))")

// Check if we can find which constant might be causing the issue
// The crash happens with numericCast, so let's check all MSG constants

let msgNames = [
    "MSG_OOB", "MSG_PEEK", "MSG_DONTROUTE", "MSG_WAITALL",
    "MSG_PARTIAL", "MSG_INTERRUPT", "MSG_MAXIOVLEN"
]

let msgValues = [
    MSG_OOB, MSG_PEEK, MSG_DONTROUTE, MSG_WAITALL,
    MSG_PARTIAL, MSG_INTERRUPT, MSG_MAXIOVLEN
]

print("\nAll MSG constants:")
for (name, value) in zip(msgNames, msgValues) {
    print("\(name): \(value) (0x\(String(value, radix: 16)))")
}

// The issue might be with INADDR constants
print("\n\nChecking INADDR constants:")
print("INADDR_ANY type: \(type(of: INADDR_ANY))")
print("INADDR_LOOPBACK type: \(type(of: INADDR_LOOPBACK))")

// Try to check their values
print("INADDR_ANY: \(INADDR_ANY)")
print("INADDR_LOOPBACK: \(INADDR_LOOPBACK)")

// Check if INADDR_LOOPBACK might be the issue
if INADDR_LOOPBACK > Int32.max {
    print("WARNING: INADDR_LOOPBACK > Int32.max!")
}

#else
print("This test is for Windows only")
#endif