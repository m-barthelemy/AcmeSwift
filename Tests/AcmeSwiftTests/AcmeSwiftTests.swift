import XCTest
import AsyncHTTPClient
import NIO

@testable import AcmeSwift

final class AcmeSwiftTests: XCTestCase {
    func testExample() async throws {
        
        let client = try await AcmeSwift(acmeEndpoint: AcmeServer.letsEncryptStaging)
        defer{try! client.syncShutdown()}
        print("\n directory=\(client.directory)")
        
        do {
            let nonce = try await client.getNonce()
            print("\n••• Nonce: \(nonce)")
            
            var bogus = HTTPClientRequest(url: "https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce")
            bogus.method = .POST
            try await client.client.execute(bogus, deadline: .now() + TimeAmount.seconds(15))
                .decode(as: AcmeDirectory.self)
        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
        }
    }
}
