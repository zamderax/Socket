import Testing
import Socket
import SystemPackage

@Suite("Sync Socket Test")
struct SyncSocketTest {
    @Test("Create socket descriptor")
    func testCreateSocket() throws {
        print("SyncSocketTest: Creating socket descriptor")
        
        // Try to create a socket descriptor directly
        let descriptor = try SocketDescriptor(IPv4Protocol.tcp)
        print("SyncSocketTest: Created socket descriptor: \(descriptor.rawValue)")
        
        // Close it
        try descriptor.close()
        print("SyncSocketTest: Socket closed")
        
        #expect(true)
    }
}