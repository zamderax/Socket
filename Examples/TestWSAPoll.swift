//
//  TestWSAPoll.swift
//  
//
//  Test WSAPoll error handling
//

#if os(Windows)
import WinSDK

// Test WSAPoll to understand the error
print("Testing WSAPoll error handling:")

// Create a closed socket descriptor
let socket = WinSDK.socket(AF_INET, SOCK_STREAM, 0)
print("Created socket: \(socket)")

// Close it immediately
closesocket(socket)
print("Closed socket")

// Now try to poll on the closed socket
var pollfd = WSAPOLLFD(fd: socket, events: Int16(POLLIN), revents: 0)
let result = WSAPoll(&pollfd, 1, 0)

print("\nWSAPoll result: \(result)")
if result == SOCKET_ERROR {
    let wsaError = WSAGetLastError()
    print("WSAGetLastError: \(wsaError)")
    print("WSAERROR value: 0x\(String(wsaError, radix: 16))")
    
    // Check if it's WSAENOTSOCK
    if wsaError == WSAENOTSOCK {
        print("Error is WSAENOTSOCK (10038)")
    }
} else {
    print("WSAPoll did not return SOCKET_ERROR")
}

// Also check what SOCKET_ERROR is
print("\nSOCKET_ERROR value: \(SOCKET_ERROR)")

// Check common WSA error codes
print("\nCommon WSA error codes:")
print("WSAENOTSOCK: \(WSAENOTSOCK)")
print("WSAEINVAL: \(WSAEINVAL)")
print("WSAEWOULDBLOCK: \(WSAEWOULDBLOCK)")

// Map to errno equivalents
print("\nPOSIX errno equivalents (from ucrt):")
import ucrt
print("ENOTSOCK: \(ENOTSOCK)")
print("EINVAL: \(EINVAL)")
print("EWOULDBLOCK: \(EWOULDBLOCK)")
print("EAGAIN: \(EAGAIN)")

#else
print("This test is for Windows only")
#endif