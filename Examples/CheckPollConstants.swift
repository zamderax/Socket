//
//  CheckPollConstants.swift
//  
//
//  Check POLL constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking POLL constants on Windows:")

print("\nValues:")
print("POLLIN: \(POLLIN) (0x\(String(POLLIN, radix: 16)))")
print("POLLPRI: \(POLLPRI) (0x\(String(POLLPRI, radix: 16)))")
print("POLLOUT: \(POLLOUT) (0x\(String(POLLOUT, radix: 16)))")
print("POLLERR: \(POLLERR) (0x\(String(POLLERR, radix: 16)))")
print("POLLHUP: \(POLLHUP) (0x\(String(POLLHUP, radix: 16)))")
print("POLLNVAL: \(POLLNVAL) (0x\(String(POLLNVAL, radix: 16)))")

print("\nChecking if they fit in Int16 (max: \(Int16.max)):")
let pollConstants: [(String, Int32)] = [
    ("POLLIN", POLLIN),
    ("POLLPRI", POLLPRI),
    ("POLLOUT", POLLOUT),
    ("POLLERR", POLLERR),
    ("POLLHUP", POLLHUP),
    ("POLLNVAL", POLLNVAL)
]

for (name, value) in pollConstants {
    if value > Int16.max || value < Int16.min {
        print("ERROR: \(name) = \(value) DOES NOT FIT IN Int16!")
    } else {
        print("\(name) = \(value) ✓ fits in Int16")
    }
}

// Try the actual numericCast that's failing
print("\nTrying numericCast to Int16:")
for (name, value) in pollConstants {
    do {
        let int16Value: Int16 = numericCast(value)
        print("\(name) -> Int16: \(int16Value)")
    } catch {
        print("\(name) -> FAILED TO CAST!")
    }
}

#else
print("This test is for Windows only")
#endif