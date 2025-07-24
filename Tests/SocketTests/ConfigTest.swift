import Testing
import Socket

@Suite("Config Test")
struct ConfigTest {
    @Test("Access Socket.configuration")
    func testAccessConfig() {
        // ConfigTest: Accessing Socket.configuration
        
        // Try to access the static configuration
        let config = Socket.configuration
        // ConfigTest: Configuration accessed successfully
        // ConfigTest: Monitor interval
        
        #expect(true)
    }
}