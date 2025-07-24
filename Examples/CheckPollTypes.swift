//
//  CheckPollTypes.swift
//  
//
//  Check types of POLL constants on Windows
//

#if os(Windows)
import WinSDK

print("Checking types of POLL constants on Windows:")

print("\nPOLLIN:")
print("  Type: \(type(of: POLLIN))")
print("  Value: \(POLLIN)")

print("\nPOLLOUT:")
print("  Type: \(type(of: POLLOUT))")
print("  Value: \(POLLOUT)")

print("\nPOLLERR:")
print("  Type: \(type(of: POLLERR))")  
print("  Value: \(POLLERR)")

// Check if they can be converted to CInt
print("\nTesting conversions:")
print("CInt(POLLIN): \(CInt(POLLIN))")
print("CInt(POLLOUT): \(CInt(POLLOUT))")
print("CInt(POLLERR): \(CInt(POLLERR))")

// Test what happens when we define a computed property like in Constants.swift
print("\nTesting computed property pattern:")
var testPOLLIN: CInt { POLLIN }
print("testPOLLIN: \(testPOLLIN)")

// Check all POLL constants that might be defined
print("\nAll POLL constants:")
print("POLLIN: \(POLLIN)")
print("POLLPRI: \(POLLPRI)")
print("POLLOUT: \(POLLOUT)")
print("POLLERR: \(POLLERR)")
print("POLLHUP: \(POLLHUP)")
print("POLLNVAL: \(POLLNVAL)")

// Check if any other Windows-specific ones exist
print("POLLRDNORM: \(POLLRDNORM)")
print("POLLRDBAND: \(POLLRDBAND)")
print("POLLWRNORM: \(POLLWRNORM)")
print("POLLWRBAND: \(POLLWRBAND)")

#else
print("This test is for Windows only")
#endif