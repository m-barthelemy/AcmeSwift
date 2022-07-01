import XCTest
import AsyncHTTPClient
import NIO
import Logging

@testable import AcmeSwift

final class AccountTests: XCTestCase {
    var logger: Logger!
    var http: HTTPClient!
    
    override func setUp() async throws {
        self.logger = Logger.init(label: "acme-swift-tests")
        self.logger.logLevel = .trace
        
        var config = HTTPClient.Configuration(certificateVerification: .fullVerification, backgroundActivityLogger: self.logger)
        self.http = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: config
        )
    }
    
    func testCreateAndDeactivateAccount() async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        
        let account = try await acme.account.create(contacts: ["bonsouere3456@gmail.com", "bonsouere+299@gmail.com"], acceptTOS: true)
        try acme.account.use(account)
        try await acme.account.deactivate()
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
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        
        try acme.account.use(login)
        let account = try await acme.account.get()
        XCTAssert(account.privateKeyPem != "", "Ensure private key is set")
        XCTAssert(account.contact == contacts, "Ensure Account contacts are set")
    }
    
    func testGetNonce() async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        let nonce = try await acme.getNonce()
        XCTAssert(nonce != "", "ensure Nonce is set")
    }
}
