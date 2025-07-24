import Testing
import Socket
@testable import Socket

@Suite("Manager Test")
struct ManagerTest {
    @Test("Access AsyncSocketManager directly")
    func testAccessManager() async {
        // ManagerTest: Accessing AsyncSocketManager.shared
        
        // Try to access the shared manager directly
        _ = AsyncSocketManager.shared
        // ManagerTest: Manager accessed successfully
        
        #expect(Bool(true))
    }
}