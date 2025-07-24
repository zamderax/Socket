//
//  TestFileEventCast.swift
//  
//
//  Test if the FileEvent cast is causing the overflow
//

#if os(Windows)
import WinSDK

print("Testing FileEvent cast on Windows")

// Simulate what happens in FileEvent.swift
typealias FileEvent = Int16

// Try the same pattern as FileEvent.swift line 17
func makeFileEvent(_ raw: CInt) -> FileEvent {
    return numericCast(raw)
}

print("\nTesting POLL constants:")
let pollTests: [(String, Int32)] = [
    ("POLLIN", POLLIN),
    ("POLLPRI", POLLPRI),
    ("POLLOUT", POLLOUT),
    ("POLLERR", POLLERR),
    ("POLLHUP", POLLHUP),
    ("POLLNVAL", POLLNVAL)
]

for (name, value) in pollTests {
    print("\n\(name) = \(value) (0x\(String(value, radix: 16)))")
    do {
        let fileEvent = makeFileEvent(CInt(value))
        print("  ✓ Cast to FileEvent (Int16) succeeded: \(fileEvent)")
    } catch {
        print("  ✗ Cast to FileEvent (Int16) FAILED!")
    }
}

#else
print("This test is for Windows only")
#endif