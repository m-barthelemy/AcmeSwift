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
            
            let newAccount = try await client.account.create(contacts: ["bonsouere3456@gmail.com"], acceptTOS: true)
            print("\n•••• Response = \(newAccount)")
            
            
            let privateKeyPem = """
            -----BEGIN PRIVATE KEY-----
            MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQglxrdsu3lP83xzUej
            ytJ7zvy2uuW3Qt7SWGRiGx8dJJuhRANCAARcpivMPbQWA/T2h8YNQPgOF+8jhyaY
            iO6kepubzBqqgk/iub3w+ZBDfKi6RgGYX2yVRlHMS4ZhhSoFFLoP57eI
            -----END PRIVATE KEY-----
            """
            let login = try AccountCredentials(contacts: ["bonsouere3456@gmail.com"], pemKey: privateKeyPem)
            let existingclient = try await AcmeSwift(login: login, client: http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
            let account = try await existingclient.account.get()
            print("\n•••• Response = \(account)")
            
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
