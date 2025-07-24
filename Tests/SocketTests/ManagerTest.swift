import Testing
import Socket
@testable import Socket

@Suite("Manager Test")
struct ManagerTest {
    @Test("Access AsyncSocketManager directly")
    func testAccessManager() async {
        print("ManagerTest: Accessing AsyncSocketManager.shared")
        
        // Try to access the shared manager directly
        let manager = await AsyncSocketManager.shared
        print("ManagerTest: Manager accessed successfully")
        
        #expect(true)
    }
}