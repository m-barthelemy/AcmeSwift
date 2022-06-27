import XCTest
@testable import AcmeSwift

final class AcmeSwiftTests: XCTestCase {
    func testExample() async throws {
        
        let client = try await AcmeSwift(acmeEndpoint: AcmeServer.letsEncryptStaging)
        print("\n directory=\(client.directory)")
        defer{try! client.syncShutdown()}
    }
}
