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
        let acme = try await AcmeSwift(client: self.http, /*acmeEndpoint: AcmeServer.letsEncryptStaging,*/ logger: logger)
        defer {try? acme.syncShutdown()}
        do {
            let account = try await acme.account.create(contacts: ["bonsouere3456@gmail.com", "bonsouere+299@gmail.com"], acceptTOS: true)
            try acme.account.use(account)
            
            let order = try await acme.orders.create(domains: ["www.nuw.run"])
            //print("\n••• Order: \(order)")
            XCTAssert(order.status == .pending, "Ensure order is pending")
            XCTAssert(order.expires > Date(), "Ensure order expiry is parsed")
            XCTAssert(order.identifiers.count == 2, "Ensure identifiers match number of requested domains")
            
            let authorizations = try await acme.orders.getAuthorizations(from: order)
            let challengeDescriptions = try await acme.orders.describePendingChallenges(from: order, preferring: .dns)
            for desc in challengeDescriptions {
                if desc.type == .http {
                    print("\n • The URL \(desc.endpoint) needs to return \(desc.value)")
                }
                else if desc.type == .dns {
                    print("\n • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
                }
            }
            
            let csr = """
            -----BEGIN CERTIFICATE REQUEST-----
            MIIChDCCAWwCAQAwFjEUMBIGA1UEAwwLd3d3Lm51dy5ydW4wggEiMA0GCSqGSIb3
            DQEBAQUAA4IBDwAwggEKAoIBAQCkoaTT+aCYjT/W2EBXCim1lFi3Z2c4TlHSklYb
            BWtpBc9YIW3dm506uF3UkqVT5CFXnTNQEAfGH0OYMChRDeMTFMrFfIkvQI8D1ui9
            qDqlkDtA/NjG8P+avb0aXuvz1q4k+rrvBcBeNBpiv9KJ4/0gCpl5NpW0N+0+BkjN
            L34tJH2lpxNSVT8cLRrWPUPaPTsjb6PmRvZWM7cz4AUEA+56/2Rl+f7/6CQW+oAJ
            glwn84nGsBwUBnSZw266Mul66d7vQK9rnNgQpNxGZwbWBixURnYPuNBEkJIs9hzI
            PVDep5naAWHZrqMTtE2ZMFGR9tQnB2yoWflGVOO1sn9rDb1HAgMBAAGgKTAnBgkq
            hkiG9w0BCQ4xGjAYMBYGA1UdEQQPMA2CC3d3dy5udXcucnVuMA0GCSqGSIb3DQEB
            CwUAA4IBAQBCmLaXs7uEyOaC4lVPFXgykAJFxSWSb98biym6r9TceXZkEB0pLzGd
            /KCtUwBlg9eqYEC4mdt6KGfC2AjjgPUM/o2/fHEYjgqGzar2IWX3mOlw0lW1dVhB
            JCRRnd/PozeQOAQ9j6AqSXct6xRiFYlDGJLQtzdLePPvcRFyhnUYfzkTi7EAitHG
            j0wEKREUfdI+aM3gXCht6UGFPvk82RYP5ZNGac6Ry8Ehy4ZdwlD426ZzwQ320k8y
            Y9gnNoJPNbaPkIaiy8a1tl8lZomzHFbsbL9MhQdK8QD8TxMAiVXFdYY1lhUSWuhf
            bfeJ5vJwRwCtoKnBTDRFE8xJWl/WcprJ
            -----END CERTIFICATE REQUEST-----
            """
            print("\n•••• CSR to base64UERL: '\(csr.pemToBase64Url())'")
            print("\nCREATE DNS CHALLENGES!!")
            try await Task.sleep(nanoseconds: 60_000_000_000)

            try await acme.orders.validateChallenges(from: order, preferring: .dns)
            let failedAuthorizations = try await acme.orders.wait(for: order, timeout: 60 /* in seconds*/)
            guard failedAuthorizations.count == 0 else {
                fatalError("\n#### Some challenges were not validated! \(failedAuthorizations)")
            }
            let finalized = try await acme.orders.finalize(order: order, withPemCsr: csr)
            let certs = try await acme.certificates.download(for: finalized)
            for var cert in certs {
                print("\n • cert: \(cert)")
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
