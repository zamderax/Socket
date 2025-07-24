import Testing
import Socket
import SystemPackage

@Suite("Sync Socket Test")
struct SyncSocketTest {
    @Test("Create socket descriptor")
    func testCreateSocket() throws {
        // SyncSocketTest: Creating socket descriptor
        
        // Try to create a socket descriptor directly
        let descriptor = try SocketDescriptor(IPv4Protocol.tcp)
        // SyncSocketTest: Created socket descriptor
        
        // Close it
        try descriptor.close()
        // SyncSocketTest: Socket closed
        
        #expect(Bool(true))
    }
}