//
//  TestFileEventsInit.swift
//  
//
//  Test FileEvents initialization
//

print("Starting FileEvents init test...")

// Check raw POLL constants first
#if os(Windows)
import WinSDK

print("\nRaw POLL constants:")
print("POLLIN: \(POLLIN) (type: \(type(of: POLLIN)))")
print("POLLOUT: \(POLLOUT) (type: \(type(of: POLLOUT)))")
print("POLLERR: \(POLLERR) (type: \(type(of: POLLERR)))")
print("POLLHUP: \(POLLHUP) (type: \(type(of: POLLHUP)))")
print("POLLNVAL: \(POLLNVAL) (type: \(type(of: POLLNVAL)))")
print("POLLPRI: \(POLLPRI) (type: \(type(of: POLLPRI)))")

// Check Windows-specific ones that might be larger
print("\nWindows-specific POLL constants:")
print("POLLRDNORM: \(POLLRDNORM) (type: \(type(of: POLLRDNORM)))")
print("POLLRDBAND: \(POLLRDBAND) (type: \(type(of: POLLRDBAND)))")
print("POLLWRNORM: \(POLLWRNORM) (type: \(type(of: POLLWRNORM)))")
print("POLLWRBAND: \(POLLWRBAND) (type: \(type(of: POLLWRBAND)))")

// Check if any don't fit in Int16
print("\nChecking Int16 compatibility:")
let pollConstants: [(String, Int32)] = [
    ("POLLIN", POLLIN),
    ("POLLPRI", POLLPRI),
    ("POLLOUT", POLLOUT),
    ("POLLERR", POLLERR),
    ("POLLHUP", POLLHUP),
    ("POLLNVAL", POLLNVAL),
    ("POLLRDNORM", POLLRDNORM),
    ("POLLRDBAND", POLLRDBAND),
    ("POLLWRNORM", POLLWRNORM),
    ("POLLWRBAND", POLLWRBAND)
]

for (name, value) in pollConstants {
    if value > Int16.max || value < Int16.min {
        print("✗ \(name) = \(value) DOES NOT FIT IN Int16!")
    } else {
        print("✓ \(name) = \(value) fits in Int16")
    }
}

#endif

print("\nImporting Socket...")
import Socket
print("✓ Import succeeded")

// Try to access FileEvents static properties
print("\nAccessing FileEvents static properties...")
print("FileEvents.read.rawValue: \(FileEvents.read.rawValue)")
print("FileEvents.write.rawValue: \(FileEvents.write.rawValue)")
print("FileEvents.error.rawValue: \(FileEvents.error.rawValue)")

print("\nAll tests passed!")