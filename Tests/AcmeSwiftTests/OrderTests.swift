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
        
        var config = HTTPClient.Configuration(certificateVerification: .fullVerification, backgroundActivityLogger: self.logger)
        self.http = HTTPClient(
            eventLoopGroupProvider: .createNew,
            configuration: config
        )
    }
    
    func testCreateOrder() async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: AcmeServer.letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}
        do {
            let account = try await acme.account.create(contacts: ["bonsouere3456@gmail.com", "bonsouere+299@gmail.com"], acceptTOS: true)
            try acme.account.use(account)
            
            let order = try await acme.orders.create(domains: ["mydomain.com", "*.mydomain.com"])
            //print("\n••• Order: \(order)")
            XCTAssert(order.status == .pending, "Ensure order is pending")
            XCTAssert(order.expires > Date(), "Ensure order expiry is parsed")
            XCTAssert(order.identifiers.count == 2, "Ensure identifiers match number of requested domains")
            
            let authorizations = try await acme.orders.getAuthorizations(order: order)
            let challengeDescriptions = try await acme.orders.describePendingChallenges(from: order, preferring: .http)
            for desc in challengeDescriptions {
                if desc.type == .http {
                    print("\n • The URL \(desc.endpoint) needs to return \(desc.value)")
                }
                else if desc.type == .dns {
                    print("\n • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
                }
            }
        }
        catch(let error) {
            print("\n•••• BOOM! \(error)")
            throw error
        }
    }
    
    private func toJson<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
        
    }
    
}
