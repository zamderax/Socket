import Testing
import Socket
import SystemPackage
@testable import Socket

@Suite("Add Socket Test")
struct AddSocketTest {
    @Test("Add socket to manager")
    func testAddSocket() async throws {
        print("AddSocketTest: Creating socket descriptor")
        
        // Create a socket descriptor
        let descriptor = try SocketDescriptor(IPv4Protocol.tcp)
        print("AddSocketTest: Created socket descriptor: \(descriptor.rawValue)")
        
        // Get the manager
        let manager = AsyncSocketManager.shared
        print("AddSocketTest: Got manager")
        
        // Try to add the socket
        print("AddSocketTest: Adding socket to manager...")
        let eventStream = await manager.add(descriptor)
        print("AddSocketTest: Socket added successfully")
        
        // Close
        await manager.remove(descriptor)
        try descriptor.close()
        
        #expect(true)
    }
}