//
//  DebugPoll.swift
//  
//
//  Debug WSAPoll parameters
//

import Socket
#if os(Windows)
import CSocket
import WinSDK
#endif

@main
struct DebugPoll {
    static func main() async throws {
        print("Debug WSAPoll")
        print("=============")
        
        #if os(Windows)
        // Initialize Winsock
        print("Initializing Winsock...")
        var wsaData = WSADATA()
        let result = WSAStartup(MAKEWORD(2, 2), &wsaData)
        if result != 0 {
            print("WSAStartup failed: \(result)")
            return
        }
        print("WSAStartup succeeded")
        
        // Create a socket
        let sock = WinSDK.socket(AF_INET, SOCK_STREAM, 0)
        print("Created socket: \(sock)")
        
        if sock == INVALID_SOCKET {
            print("Failed to create socket")
            return
        }
        
        // Try to poll with valid parameters
        print("\nTesting WSAPoll with valid socket...")
        var pollfd = WSAPOLLFD(fd: sock, events: Int16(POLLIN), revents: 0)
        
        print("WSAPOLLFD:")
        print("  fd: \(pollfd.fd) (0x\(String(pollfd.fd, radix: 16)))")
        print("  events: \(pollfd.events)")
        print("  revents: \(pollfd.revents)")
        
        let pollResult = WSAPoll(&pollfd, 1, 0)
        print("WSAPoll result: \(pollResult)")
        
        if pollResult == SOCKET_ERROR {
            let error = WSAGetLastError()
            print("WSAPoll failed with error: \(error) (0x\(String(error, radix: 16)))")
        } else {
            print("WSAPoll succeeded, returned events: \(pollfd.revents)")
        }
        
        // Clean up
        closesocket(sock)
        WSACleanup()
        
        print("\nNow testing with Socket library...")
        // Test with actual Socket library
        do {
            let socket = try Socket(IPv4Protocol.tcp)
            print("Created Socket: \(socket.fileDescriptor)")
            
            // Try polling directly
            let events = try socket.fileDescriptor.poll(for: [.read], timeout: 0)
            print("Poll succeeded, events: \(events)")
            
            try socket.close()
        } catch {
            print("Socket test failed: \(error)")
        }
        #else
        print("This test is for Windows only")
        #endif
    }
}

#if os(Windows)
private func MAKEWORD(_ low: UInt8, _ high: UInt8) -> WORD {
    return WORD(low) | (WORD(high) << 8)
}
#endif