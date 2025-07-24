//
//  SimpleDebug.swift
//  
//
//  Simple debug to isolate crash
//

import Foundation

@main
struct SimpleDebug {
    static func main() async {
        print("1. Starting SimpleDebug")
        
        // Just import Socket and see if it crashes
        print("2. About to import Socket module functionality")
        
        do {
            // Import and use a simple type from Socket
            print("3. Creating IPv4 protocol")
            let proto = IPv4Protocol.tcp
            print("4. Protocol created: \(proto)")
            
            // Try creating a socket
            print("5. About to create socket")
            let socket = try await Socket(proto)
            print("6. Socket created successfully!")
            
            await socket.close()
            print("7. Socket closed")
        } catch {
            print("Error: \(error)")
        }
        
        print("8. Done")
    }
}

// Import Socket at the end to see if the import itself causes issues
import Socket