#if !canImport(Darwin)
import FoundationEssentials
#else
import Foundation
#endif
import AsyncHTTPClient
import Logging

import Testing
import AcmeSwift

@Suite("ACMEv2 Account")
struct AccountTests {
    var logger: Logger
    var http: HTTPClient

    let endpointKeys: [AcmeEndpoint:String] = [
        .letsEncryptStaging: ProcessInfo.processInfo.environment["LETSENCRYPT_PRIVATE_KEY"]!,
        .googleStaging: ProcessInfo.processInfo.environment["GOOGLE_PRIVATE_KEY"]!,
    ]

    private init() async throws {
        self.logger = Logger.init(label: "acme-swift-tests")
        self.logger.logLevel = .debug

        let config = HTTPClient.Configuration(certificateVerification: .fullVerification, backgroundActivityLogger: self.logger)
        self.http = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: config
        )
    }

    @Test("Create and Deactivate Account")
    func testCreateAndDeactivateAccount() async throws {
        let email = "\(UUID())@notadomain.com"
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        
        let account = try await acme.account.create(contacts: [email], acceptTOS: true)
        try acme.account.use(account)
        #expect(account.status == .valid)
        logger.info("Created account: \(account)")

        try await acme.account.deactivate()

        let error = await #expect(throws: AcmeResponseError.self) {
            _ = try await acme.account.get()
        }
        #expect(error?.type == .unauthorized)
    }

    @Test("Get Account Info", arguments: [AcmeEndpoint.letsEncryptStaging/*, .googleStaging*/])
    func testGetAccount(_ endpoint: AcmeEndpoint) async throws {
        let contacts = ["mailto:bonsouere3456@gmail.com"]
        
        let login = try AccountCredentials(contacts: contacts, pemKey: self.endpointKeys[endpoint]!)
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: endpoint, logger: logger)
        defer {try? acme.syncShutdown()}
        
        try acme.account.use(login)
        let account = try await acme.account.get()
        #expect(account.privateKeyPem != "", "Ensure private key is set")
        //#expect(account.contact == contacts, "Ensure Account contacts are set")
        #expect(account.key != nil, "Ensure account JWK is set")
    }
    
    /*func testGetNonce() async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        let nonce = try await acme.getNonce()
        #expect(nonce != "", "ensure Nonce is set")
    }*/
}

extension AcmeEndpoint: @retroactive Hashable{
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension AcmeEndpoint: @retroactive Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.value == rhs.value
    }
}
