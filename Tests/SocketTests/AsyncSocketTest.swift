import Testing
import Socket
import SystemPackage

@Suite("Async Socket Test")
struct AsyncSocketTest {
    @Test("Create async socket")
    func testCreateAsyncSocket() async throws {
        // Try to create a socket asynchronously
        let socket = try await Socket(IPv4Protocol.tcp)
        
        // Close it
        await socket.close()
        
        #expect(true)
    }
}