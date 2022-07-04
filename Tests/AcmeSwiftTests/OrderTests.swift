import XCTest
import AsyncHTTPClient
import NIO
import Logging

@testable import AcmeSwift

final class OrderTests: XCTestCase {
    var logger: Logger!
    var http: HTTPClient!
    
    override func setUp() async throws {
        self.logger = Logger.init(label: "acme-swift-tests")
        self.logger.logLevel = .trace
        
        let config = HTTPClient.Configuration(certificateVerification: .fullVerification, backgroundActivityLogger: self.logger)
        self.http = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: config
        )
    }
    
    func testCreateOrder() async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        do {
            let privateKeyPem = """
            -----BEGIN PRIVATE KEY-----
            MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQglxrdsu3lP83xzUej
            ytJ7zvy2uuW3Qt7SWGRiGx8dJJuhRANCAARcpivMPbQWA/T2h8YNQPgOF+8jhyaY
            iO6kepubzBqqgk/iub3w+ZBDfKi6RgGYX2yVRlHMS4ZhhSoFFLoP57eI
            -----END PRIVATE KEY-----
            """
            let contacts = ["mailto:bonsouere3456@gmail.com"]
            
            let login = try AccountCredentials(contacts: contacts, pemKey: privateKeyPem)
            let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
            defer {try? acme.syncShutdown()}
            
            try acme.account.use(login)
            
            var order = try await acme.orders.create(domains: ["burrito.run", "www.burrito.run"])
            XCTAssert(order.url != nil, "Ensure order has URL")
            XCTAssert(order.status == .pending, "Ensure order is pending (got \(order.status)")
            XCTAssert(order.expires > Date(), "Ensure order expiry is parsed (got \(order.expires)")
            XCTAssert(order.identifiers.count == 2, "Ensure identifiers match number of requested domains (expected 2, got \(order.identifiers.count)")
            
            let authorizations = try await acme.orders.getAuthorizations(from: order)
            XCTAssert(authorizations.count == 2, "Ensure we only have 1 authorization")
            
            let challengeDescriptions = try await acme.orders.describePendingChallenges(from: order, preferring: .dns)
            XCTAssert(challengeDescriptions.count == 2, "Ensure we have 1 pending challenge")
            XCTAssert(challengeDescriptions.filter({$0.type == .dns}).count == 2, "Ensure challenges are of the desired type")
            
            try await acme.orders.refresh(order: &order)

        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
            throw error
        }
    }
    
    /*func testWrapItUpLikeABurrito() async throws {
        let privateKeyPem = """
            -----BEGIN PRIVATE KEY-----
            MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQglxrdsu3lP83xzUej
            ytJ7zvy2uuW3Qt7SWGRiGx8dJJuhRANCAARcpivMPbQWA/T2h8YNQPgOF+8jhyaY
            iO6kepubzBqqgk/iub3w+ZBDfKi6RgGYX2yVRlHMS4ZhhSoFFLoP57eI
            -----END PRIVATE KEY-----
            """
        let contacts = ["mailto:bonsouere3456@gmail.com"]
        
        let login = try AccountCredentials(contacts: contacts, pemKey: privateKeyPem)
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        
        try acme.account.use(login)
        let domains = ["www.nuw.run"]
        
        do {
            var order = try await acme.orders.create(domains: domains)
            //try await Task.sleep(nanoseconds: 60_000_000_000)
            for desc in try await acme.orders.describePendingChallenges(from: order, preferring: .dns) {
                if desc.type == .http {
                    print("\n • The URL \(desc.endpoint) needs to return \(desc.value)")
                }
                else if desc.type == .dns {
                    print("\n • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
                }
            }
            print("\n =====> CREATE DNS CHALLENGES!!\n")
            
            try await Task.sleep(nanoseconds: 6_000_000_000)
            
            let failed = try await acme.orders.validateChallenges(from: order, preferring: .dns)
            guard failed.count == 0 else {
                fatalError("Some validations failed! \(failed)")
            }
            try await acme.orders.refresh(order: &order)
            print("\n => order: \(toJson(order))")

            let csr = try AcmeX509Csr.ecdsa(domains: domains)
        
            let finalized = try await acme.orders.finalize(order: order, withCsr: csr)
            let certs = try await acme.certificates.download(for: finalized)
            try certs.joined(separator: "\n").write(to: URL(fileURLWithPath: "cert.pem"), atomically: true, encoding: .utf8)
            
            try csr.privateKeyPem.write(to: URL(fileURLWithPath: "key.pem"), atomically: true, encoding: .utf8)
        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
            throw error
        }
    }*/
    
    private func toJson<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
        
    }
    
}
