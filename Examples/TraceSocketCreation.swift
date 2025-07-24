//
//  TraceSocketCreation.swift
//  
//
//  Trace socket creation to find overflow
//

import Socket
#if os(Windows)
import WinSDK
#endif

@main
struct TraceSocketCreation {
    static func main() async {
        print("Tracing socket creation...")
        
        // Step by step trace
        
        print("\n1. Creating IPv4Protocol.tcp")
        let proto = IPv4Protocol.tcp
        print("   ✓ Protocol: \(proto)")
        print("   ✓ Raw value: \(proto.rawValue)")
        
        print("\n2. Getting socket parameters")
        let family = IPv4Protocol.family
        let type = proto.type
        print("   ✓ Family: \(family) (raw: \(family.rawValue))")
        print("   ✓ Type: \(type) (raw: \(type.rawValue))")
        
        print("\n3. Creating SocketDescriptor through init")
        do {
            print("   About to call SocketDescriptor(protocolID)...")
            
            // This is what happens inside Socket init
            let descriptor = try SocketDescriptor(proto)
            print("   ✓ SocketDescriptor created: \(descriptor)")
            
            // Close it
            try descriptor.close()
            print("   ✓ Socket closed")
        } catch {
            print("   ✗ Failed: \(error)")
        }
        
        print("\n4. Now trying full Socket creation...")
        do {
            let socket = try await Socket(proto)
            print("   ✓ Socket created successfully!")
            await socket.close()
        } catch {
            print("   ✗ Failed: \(error)")
        }
        
        print("\nDone!")
    }
}