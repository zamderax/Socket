import Testing
import Socket
import SystemPackage
@testable import Socket

@Suite("Add Socket Test")
struct AddSocketTest {
    @Test("Add socket to manager")
    func testAddSocket() async throws {
        // AddSocketTest: Creating socket descriptor
        
        // Create a socket descriptor
        let descriptor = try SocketDescriptor(IPv4Protocol.tcp)
        // AddSocketTest: Created socket descriptor
        
        // Get the manager
        let manager = AsyncSocketManager.shared
        // AddSocketTest: Got manager
        
        // Try to add the socket
        // AddSocketTest: Adding socket to manager...
        let eventStream = await manager.add(descriptor)
        // AddSocketTest: Socket added successfully
        
        // Close
        await manager.remove(descriptor)
        try descriptor.close()
        
        #expect(true)
    }
}