//
//  CheckPollValues.swift
//  
//
//  Check POLL constant values on Windows
//

#if os(Windows)
import WinSDK

print("Windows POLL constants:")
print("POLLIN:  \(POLLIN) (0x\(String(POLLIN, radix: 16)))")
print("POLLOUT: \(POLLOUT) (0x\(String(POLLOUT, radix: 16)))")
print("POLLERR: \(POLLERR) (0x\(String(POLLERR, radix: 16)))")
print("POLLHUP: \(POLLHUP) (0x\(String(POLLHUP, radix: 16)))")
print("POLLNVAL: \(POLLNVAL) (0x\(String(POLLNVAL, radix: 16)))")
print("POLLPRI: \(POLLPRI) (0x\(String(POLLPRI, radix: 16)))")

// Calculate what 1815 would be
let events: Int16 = 1815
print("\nCombined events value: \(events) (0x\(String(events, radix: 16)))")

// See which flags are set
if (events & Int16(POLLIN)) != 0 { print("  POLLIN is set") }
if (events & Int16(POLLOUT)) != 0 { print("  POLLOUT is set") }
if (events & Int16(POLLERR)) != 0 { print("  POLLERR is set") }
if (events & Int16(POLLHUP)) != 0 { print("  POLLHUP is set") }
if (events & Int16(POLLNVAL)) != 0 { print("  POLLNVAL is set") }
if (events & Int16(POLLPRI)) != 0 { print("  POLLPRI is set") }

#else
print("This test is for Windows only")
#endif