//
//  TypeCheck.swift
//  
//
//  Check Windows type sizes and signedness
//

#if os(Windows)
import CSocket
import WinSDK

@main
struct TypeCheck {
    static func main() {
        print("Type check for Windows socket types:")
        print("SOCKET size: \(MemoryLayout<SOCKET>.size) bytes")
        print("SOCKET is signed: \(SOCKET.isSigned)")
        print("CInt size: \(MemoryLayout<CInt>.size) bytes")
        print("Int32 size: \(MemoryLayout<Int32>.size) bytes")
        
        // Test INVALID_SOCKET value
        print("\nINVALID_SOCKET value: \(INVALID_SOCKET)")
        print("INVALID_SOCKET as hex: 0x\(String(INVALID_SOCKET, radix: 16))")
        
        // Test conversions
        let testSocket: SOCKET = 500
        print("\nTest socket value: \(testSocket)")
        print("Can convert to Int32: \(Int32(exactly: testSocket) != nil)")
        print("Can convert to CInt: \(CInt(exactly: testSocket) != nil)")
        
        // Test large value
        let largeSocket: SOCKET = 0x80000000
        print("\nLarge socket value: \(largeSocket) (0x\(String(largeSocket, radix: 16)))")
        print("Can convert to Int32: \(Int32(exactly: largeSocket) != nil)")
        print("Using bitPattern: \(CInt(bitPattern: UInt32(truncatingIfNeeded: largeSocket)))")
    }
}
#else
@main  
struct TypeCheck {
    static func main() {
        print("This test is for Windows only")
    }
}
#endif