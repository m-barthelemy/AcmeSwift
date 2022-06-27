import XCTest
@testable import AcmeSwift

final class AcmeSwiftTests: XCTestCase {
    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //XCTAssertEqual(AcmeSwift().text, "Hello, World!")
        
        let client = try await AcmeSwift()
        print("\n directory=\(client.directory)")
        defer{try! client.syncShutdown()}
    }
}
