//
//  CheckIPProto.swift
//  
//
//  Check IPPROTO values on Windows
//

#if os(Windows)
import WinSDK

print("IPPROTO type info:")
print("IPPROTO_TCP type: \(type(of: IPPROTO_TCP))")
print("IPPROTO_TCP value: \(IPPROTO_TCP)")
print("IPPROTO_TCP.rawValue: \(IPPROTO_TCP.rawValue)")
print("IPPROTO_TCP.rawValue type: \(type(of: IPPROTO_TCP.rawValue))")

print("\nIPPROTO_UDP:")
print("IPPROTO_UDP.rawValue: \(IPPROTO_UDP.rawValue)")

print("\nIPPROTO_RAW:")
print("IPPROTO_RAW.rawValue: \(IPPROTO_RAW.rawValue)")

// Check if they fit in CInt
print("\nCan convert to CInt:")
print("TCP: \(CInt(exactly: IPPROTO_TCP.rawValue) != nil)")
print("UDP: \(CInt(exactly: IPPROTO_UDP.rawValue) != nil)")
print("RAW: \(CInt(exactly: IPPROTO_RAW.rawValue) != nil)")

// Try the actual conversion that's failing
print("\nTrying actual conversions:")
if let tcpValue = CInt(exactly: IPPROTO_TCP.rawValue) {
    print("TCP as CInt: \(tcpValue)")
} else {
    print("TCP conversion would overflow!")
    print("TCP raw value: \(IPPROTO_TCP.rawValue) (0x\(String(IPPROTO_TCP.rawValue, radix: 16)))")
}

#else
print("This test is for Windows only")
#endif