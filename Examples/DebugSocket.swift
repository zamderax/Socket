//
//  DebugSocket.swift
//  
//
//  Debug socket creation issue
//

import Socket
import Foundation
#if os(Windows)
import CSocket
import WinSDK
#endif

@main
struct DebugSocket {
    static func main() async {
        print("Debug Socket Creation")
        print("====================")
        
        #if os(Windows)
        // Test raw socket creation
        print("\n1. Testing raw socket() call:")
        
        // Initialize Winsock manually
        var wsaData = WSADATA()
        let wsaResult = WSAStartup(MAKEWORD(2, 2), &wsaData)
        print("WSAStartup result: \(wsaResult)")
        
        // Create a raw socket
        let rawSocket = socket(Int32(AF_INET), Int32(SOCK_STREAM), Int32(IPPROTO_TCP.rawValue))
        print("Raw socket() returned: \(rawSocket) (hex: 0x\(String(rawSocket, radix: 16)))")
        print("Is INVALID_SOCKET: \(rawSocket == INVALID_SOCKET)")
        
        if rawSocket != INVALID_SOCKET {
            // Try to convert to CInt
            print("\nTrying conversions:")
            print("Direct CInt cast would overflow: \(rawSocket > UInt64(Int32.max))")
            print("UInt32 truncated: \(UInt32(truncatingIfNeeded: rawSocket))")
            print("CInt with bitPattern: \(CInt(bitPattern: UInt32(truncatingIfNeeded: rawSocket)))")
            
            closesocket(rawSocket)
        }
        
        WSACleanup()
        #endif
        
        print("\n2. Testing through Socket library:")
        do {
            print("Creating socket...")
            let socket = try await Socket(IPv4Protocol.tcp)
            print("Success! Socket created")
            await socket.close()
        } catch {
            print("Failed: \(error)")
        }
    }
}

#if os(Windows)
private func MAKEWORD(_ low: UInt8, _ high: UInt8) -> WORD {
    return WORD(low) | (WORD(high) << 8)
}
#endif