//
//  TestMSGTruncCtrunc.swift
//  
//
//  Test if MSG_TRUNC and MSG_CTRUNC exist on Windows
//

#if os(Windows)
import WinSDK

print("Testing MSG_TRUNC and MSG_CTRUNC on Windows:")

// Check if MSG_TRUNC is defined
#if canImport(WinSDK.MSG_TRUNC)
print("MSG_TRUNC is defined")
#else
print("MSG_TRUNC is NOT defined")
#endif

// Try to access them to see what happens
print("\nTrying to access MSG_TRUNC...")
// This will cause a compile error if MSG_TRUNC doesn't exist
// print("MSG_TRUNC: \(MSG_TRUNC)")

print("\nTrying to access MSG_CTRUNC...")
// This will cause a compile error if MSG_CTRUNC doesn't exist
// print("MSG_CTRUNC: \(MSG_CTRUNC)")

// Actually, let's check what MSG constants are available
print("\nAvailable MSG constants on Windows:")
print("MSG_DONTROUTE: \(MSG_DONTROUTE)")
print("MSG_OOB: \(MSG_OOB)")
print("MSG_PEEK: \(MSG_PEEK)")
print("MSG_WAITALL: \(MSG_WAITALL)")

// MSG_PARTIAL is Windows-specific
print("MSG_PARTIAL: \(MSG_PARTIAL)")

#else
print("This test is for Windows only")
#endif