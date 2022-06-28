import XCTest
import AsyncHTTPClient
import NIO
import Logging

@testable import AcmeSwift

final class AcmeSwiftTests: XCTestCase {
    var logger: Logger!
    
    override func setUp() async throws {
        self.logger = Logger.init(label: "acme-swift-tests")
        self.logger.logLevel = .trace
    }
    
    func testCreateAndDeactivateAccount() async throws {
        var config = HTTPClient.Configuration.init()
        //config.httpVersion =  .http1Only
        let http = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: config
        )
        
        do {
            let client = try await AcmeSwift(client: http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
            defer{try? client.syncShutdown()}
            
            let newAccount = try await client.account.create(contacts: ["bonsouere3456@gmail.com", "bonsouere+299@gmail.com"], acceptTOS: true)
            print("\n•••• Response = \(newAccount)")
            
            let newAccountCli = try await AcmeSwift(login: .init(contacts: newAccount.contact, pemKey: newAccount.privateKeyPem!), client: http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
            defer{try? newAccountCli.syncShutdown()}
            try await newAccountCli.account.deactivate()
            
        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
            throw error
        }
    }
    
    func testGetAccount() async throws {
        // TODO: pass the key as a secret/env var
        let privateKeyPem = """
            -----BEGIN PRIVATE KEY-----
            MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQglxrdsu3lP83xzUej
            ytJ7zvy2uuW3Qt7SWGRiGx8dJJuhRANCAARcpivMPbQWA/T2h8YNQPgOF+8jhyaY
            iO6kepubzBqqgk/iub3w+ZBDfKi6RgGYX2yVRlHMS4ZhhSoFFLoP57eI
            -----END PRIVATE KEY-----
            """
        let contacts = ["mailto:bonsouere3456@gmail.com"]
        
        let login = try AccountCredentials(contacts: contacts, pemKey: privateKeyPem)
        let acme = try await AcmeSwift(login: login, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer{try? acme.syncShutdown()}
        let account = try await acme.account.get()
        XCTAssert(account.privateKeyPem != "", "Ensure private key is set")
        XCTAssert(account.contact == contacts, "Ensure Account contacts are set")
        print("\n•••• Response = \(account)")
    }
    
    func testGetNonce() async throws {
        let client = try await AcmeSwift(acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer{try? client.syncShutdown()}
        let nonce = try await client.getNonce()
        XCTAssert(nonce != "", "ensure Nonce is set")
    }
}
