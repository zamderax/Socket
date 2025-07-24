//
//  IsolateOverflow.swift
//  
//
//  Isolate the integer overflow
//

import Socket

@main
struct IsolateOverflow {
    static func main() async {
        print("Starting isolation test...")

        // Test 1: Can we import the module at all?
        print("1. Socket module imported successfully")

        // Test 2: Can we access simple types?
        print("2. Accessing SocketAddressFamily...")
        let family = SocketAddressFamily.ipv4
        print("   ✓ Family: \(family)")

        // Test 3: Can we access IPv4Protocol?
        print("3. Accessing IPv4Protocol...")
        let proto = IPv4Protocol.tcp
        print("   ✓ Protocol: \(proto)")

        // Test 4: Can we get the raw value?
        print("4. Getting protocol raw value...")
        let protoRaw = proto.rawValue
        print("   ✓ Raw value: \(protoRaw)")

        // Test 5: Can we access IPv4Address constants?
        print("5. Accessing IPv4Address.any...")
        let anyAddr = IPv4Address.any
        print("   ✓ Any address accessed")

        // Test 6: Can we access IPv4Address.loopback?
        print("6. Accessing IPv4Address.loopback...")
        let loopback = IPv4Address.loopback
        print("   ✓ Loopback accessed")

        // Test 7: Can we create an IPv4SocketAddress?
        print("7. Creating IPv4SocketAddress...")
        let addr = IPv4SocketAddress(address: anyAddr, port: 0)
        print("   ✓ Address created")

        // Test 8: Can we access SocketDescriptor.invalid?
        print("8. Accessing SocketDescriptor.invalid...")
        let invalid = SocketDescriptor.invalid
        print("   ✓ Invalid descriptor accessed")

        // Test 9: Can we get to the socket creation point?
        print("9. Testing socket creation preparation...")
        do {
            print("   - Creating protocol ID...")
            let protocolID = IPv4Protocol.tcp
            print("   - Protocol ID created: \(protocolID)")
            
            print("   - Getting protocol family...")
            let family = IPv4Protocol.family
            print("   - Family: \(family)")
            
            print("   - Getting socket type...")
            let type = protocolID.type
            print("   - Type: \(type)")
            
            print("   - Getting raw values...")
            let familyRaw = family.rawValue
            let typeRaw = type.rawValue  
            let protoRaw = protocolID.rawValue
            print("   - Family raw: \(familyRaw), Type raw: \(typeRaw), Proto raw: \(protoRaw)")
            
            print("   ✓ Socket creation prep successful")
        } catch {
            print("   ✗ Error: \(error)")
        }

        // Test 10: Actually try to create a socket
        print("10. Creating actual socket...")
        do {
            let socket = try await Socket(IPv4Protocol.tcp)
            print("   ✓ Socket created successfully!")
            await socket.close()
        } catch {
            print("   ✗ Socket creation failed: \(error)")
        }

        print("\nAll tests completed!")
    }
}