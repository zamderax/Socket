//
//  WindowsExample.swift
//  
//
//  Example of using sockets on Windows
//

import Socket
import Foundation
#if os(Windows)
import CSocket
#endif

// Define INET_ADDRSTRLEN if not available
#if !os(Windows)
let INET_ADDRSTRLEN = 16
#endif

@main
struct WindowsExample {
    static func main() async {
        print("Windows Socket Example")
        print("=====================")
        
        do {
            // Create a TCP socket - WSAStartup will be called automatically
            print("Creating TCP socket...")
            let socket = try await Socket(IPv4Protocol.tcp)
            print("✓ Socket created successfully")
            
            // Bind to localhost on any available port
            print("\nBinding to localhost...")
            let address = IPv4SocketAddress(address: .loopback, port: 0)
            try socket.fileDescriptor.bind(address)
            print("✓ Bound successfully")
            
            // Get the actual address we bound to
            let boundAddress = try socket.fileDescriptor.address(IPv4SocketAddress.self)
            print("✓ Bound to \(boundAddress.address):\(boundAddress.port)")
            
            // Set socket options
            print("\nTesting socket is ready...")
            
            // For a server, we would listen here
            // try await socket.fileDescriptor.listen(backlog: 5)
            
            // Close the socket - WSACleanup will be called when last socket closes
            print("\nClosing socket...")
            await socket.close()
            print("✓ Socket closed successfully")
            
            // Test UDP socket
            print("\n\nTesting UDP socket...")
            let udpSocket = try await Socket(IPv4Protocol.udp)
            print("✓ UDP socket created")
            
            // Bind UDP socket
            let udpAddress = IPv4SocketAddress(address: .any, port: 0)
            try udpSocket.fileDescriptor.bind(udpAddress)
            let udpBound = try udpSocket.fileDescriptor.address(IPv4SocketAddress.self)
            print("✓ UDP bound to port \(udpBound.port)")
            
            await udpSocket.close()
            print("✓ UDP socket closed")
            
            print("\n✅ All tests passed! Windows sockets are working correctly.")
            
        } catch {
            print("\n❌ Error: \(error)")
        }
    }
}

