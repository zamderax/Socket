//
//  CheckConstants.swift
//  
//
//  Check constant values on Windows
//

#if os(Windows)
import WinSDK

print("Checking Windows constants:")

print("\nINET_ADDRSTRLEN: \(INET_ADDRSTRLEN)")
print("Type: \(type(of: INET_ADDRSTRLEN))")

print("\nINET6_ADDRSTRLEN: \(INET6_ADDRSTRLEN)")
print("Type: \(type(of: INET6_ADDRSTRLEN))")

// Check MSG constants
print("\nMSG constants:")
print("MSG_OOB: \(MSG_OOB) type: \(type(of: MSG_OOB))")
print("MSG_PEEK: \(MSG_PEEK) type: \(type(of: MSG_PEEK))")
print("MSG_DONTROUTE: \(MSG_DONTROUTE) type: \(type(of: MSG_DONTROUTE))")
print("MSG_WAITALL: \(MSG_WAITALL) type: \(type(of: MSG_WAITALL))")

// Try numericCast
print("\nTrying numericCast:")
print("Can cast MSG_OOB: \(Int32(exactly: MSG_OOB) != nil)")
print("Can cast MSG_WAITALL: \(Int32(exactly: MSG_WAITALL) != nil)")

// Print actual values
if let msgOOB = Int32(exactly: MSG_OOB) {
    print("MSG_OOB as Int32: \(msgOOB)")
} else {
    print("MSG_OOB doesn't fit in Int32! Value: \(MSG_OOB) (0x\(String(MSG_OOB, radix: 16)))")
}

#else
print("This test is for Windows only")
#endif