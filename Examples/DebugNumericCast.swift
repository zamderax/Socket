//
//  DebugNumericCast.swift
//  
//
//  Debug the numericCast issue systematically
//

print("Debugging numericCast issue...")

// The crash happens in SignedInteger<>.init<A>(_:)
// This is called by numericCast when converting between integer types

// Let's test various conversions that might happen in the Socket module

// Test 1: Windows SOCKET type conversions
#if os(Windows)
import WinSDK

print("\n1. Testing SOCKET conversions:")
let testSocket: SOCKET = 100
print("SOCKET value: \(testSocket) (type: \(type(of: testSocket)))")

// SOCKET is UINT_PTR which is UInt64 on 64-bit Windows
// Converting to CInt (Int32) could overflow if the value is too large

// Test various socket values
let socketValues: [SOCKET] = [
    0,
    100,
    INVALID_SOCKET,
    SOCKET(Int32.max),
    SOCKET(Int32.max) + 1,
    SOCKET(UInt32.max)
]

for sock in socketValues {
    print("\nTesting SOCKET \(sock) (0x\(String(sock, radix: 16))):")
    
    if sock == INVALID_SOCKET {
        print("  This is INVALID_SOCKET")
    }
    
    // Check if it fits in Int32
    if let int32Value = Int32(exactly: sock) {
        print("  ✓ Fits in Int32: \(int32Value)")
    } else {
        print("  ✗ Does NOT fit in Int32!")
        // This would cause numericCast to crash
    }
    
    // Check if it fits in CInt
    if sock <= CInt.max {
        print("  ✓ Fits in CInt")
    } else {
        print("  ✗ Does NOT fit in CInt!")
    }
}

// Test 2: Check what happens with high socket values
print("\n2. Testing high socket values:")
// On Windows, socket handles can theoretically be any value
// Let's see what a real socket returns
do {
    // Initialize Winsock
    var wsaData = WSADATA()
    let result = WSAStartup(MAKEWORD(2, 2), &wsaData)
    if result == 0 {
        print("WSAStartup succeeded")
        
        // Create a socket
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        print("Created socket: \(sock) (0x\(String(sock, radix: 16)))")
        
        if sock != INVALID_SOCKET {
            closesocket(sock)
        }
        
        // Create multiple sockets to see the pattern
        print("\nCreating multiple sockets:")
        var sockets: [SOCKET] = []
        for i in 0..<10 {
            let s = socket(AF_INET, SOCK_STREAM, 0)
            if s != INVALID_SOCKET {
                print("  Socket \(i): \(s) (0x\(String(s, radix: 16)))")
                sockets.append(s)
            }
        }
        
        // Clean up
        for s in sockets {
            closesocket(s)
        }
        
        WSACleanup()
    }
}

// Helper to make WORD
func MAKEWORD(_ low: UInt8, _ high: UInt8) -> WORD {
    return WORD(low) | (WORD(high) << 8)
}

#else
print("This test is for Windows only")
#endif

print("\nDebug complete.")