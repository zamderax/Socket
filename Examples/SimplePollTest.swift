//
//  SimplePollTest.swift
//  
//
//  Simple WSAPoll test
//

#if os(Windows)
import WinSDK

print("Simple WSAPoll Test")
print("==================")

// Initialize Winsock
var wsaData = WSADATA()
let startupResult = WSAStartup(0x0202, &wsaData)  // Version 2.2
if startupResult != 0 {
    print("WSAStartup failed: \(startupResult)")
} else {
    print("WSAStartup succeeded")
    
    // Create a socket
    let sock = socket(AF_INET, SOCK_STREAM, 0)
    print("Created socket: \(sock)")
    
    if sock != INVALID_SOCKET {
        // Set non-blocking mode
        var nonBlocking: u_long = 1
        let ioctlResult = ioctlsocket(sock, FIONBIO, &nonBlocking)
        print("Set non-blocking: \(ioctlResult == 0 ? "Success" : "Failed")")
        
        // Try WSAPoll with this socket
        var pollfd = WSAPOLLFD(fd: sock, events: Int16(POLLIN | POLLOUT), revents: 0)
        
        print("\nWSAPOLLFD structure:")
        print("  fd: \(pollfd.fd)")
        print("  events: \(pollfd.events) (POLLIN=\(POLLIN), POLLOUT=\(POLLOUT))")
        print("  size of WSAPOLLFD: \(MemoryLayout<WSAPOLLFD>.size)")
        
        let pollResult = WSAPoll(&pollfd, 1, 0)
        print("\nWSAPoll result: \(pollResult)")
        
        if pollResult == SOCKET_ERROR {
            let error = WSAGetLastError()
            print("WSAPoll error: \(error)")
            switch error {
            case WSAEINVAL:
                print("Error is WSAEINVAL - Invalid argument")
            case WSAENOTSOCK:
                print("Error is WSAENOTSOCK - Not a socket")
            default:
                print("Unknown error")
            }
        } else {
            print("WSAPoll succeeded!")
            print("Returned events: \(pollfd.revents)")
        }
        
        closesocket(sock)
    }
    
    WSACleanup()
}

#else
print("This test is for Windows only")
#endif