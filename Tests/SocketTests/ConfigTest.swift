import Testing
import Socket

@Suite("Config Test")
struct ConfigTest {
    @Test("Access Socket.configuration")
    func testAccessConfig() {
        print("ConfigTest: Accessing Socket.configuration")
        
        // Try to access the static configuration
        let config = Socket.configuration
        print("ConfigTest: Configuration accessed successfully")
        print("ConfigTest: Monitor interval: \(config.monitorInterval)")
        
        #expect(true)
    }
}