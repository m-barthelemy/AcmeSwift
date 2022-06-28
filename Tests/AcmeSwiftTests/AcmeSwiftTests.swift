import XCTest
import AsyncHTTPClient
import NIO
import Logging

@testable import AcmeSwift

final class AcmeSwiftTests: XCTestCase {
    func testExample() async throws {
        var logger = Logger.init(label: "acme-swift-tests")
        logger.logLevel = .trace
        
        var config = HTTPClient.Configuration.init()
        //config.httpVersion =  .http1Only
        let http = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: config
        )
        let client = try await AcmeSwift(client: http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer{try! client.syncShutdown()}
        print("\n directory=\(client.directory)")
        
        do {
            let nonce = try await client.getNonce()
            print("\n••• Nonce: \(nonce)")
            
            let boobz = try await client.account.create(contacts: ["bonsouere3456@gmail.com"], acceptTOS: true)
            print("\n•••• Response = \(boobz)")
            
            /*var bogus = HTTPClientRequest(url: "https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce")
            bogus.method = .POST
            try await client.client.execute(bogus, deadline: .now() + TimeAmount.seconds(15))
                .decode(as: AcmeDirectory.self)*/
        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
        }
    }
}
