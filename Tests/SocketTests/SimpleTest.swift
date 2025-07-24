import Testing

@Suite("Simple Test")
struct SimpleTest {
    @Test("Basic test")
    func testBasic() {
        // SimpleTest: Basic test running
        #expect(1 == 1)
    }
}