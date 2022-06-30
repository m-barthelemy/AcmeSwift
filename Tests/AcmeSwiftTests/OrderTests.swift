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
            
            let order = try await acme.orders.create(domains: ["*.nuw.run"])
            //print("\n••• Order: \(order)")
            XCTAssert(order.status == .pending, "Ensure order is pending")
            XCTAssert(order.expires > Date(), "Ensure order expiry is parsed")
            XCTAssert(order.identifiers.count == 2, "Ensure identifiers match number of requested domains")
            
            let authorizations = try await acme.orders.getAuthorizations(from: order)
            let challengeDescriptions = try await acme.orders.describePendingChallenges(from: order, preferring: .http)
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
            MIICwDCCAagCAQAwezELMAkGA1UEBhMCU0cxEjAQBgNVBAgMCVNpbmdhcG9yZTES
            MBAGA1UEBwwJU2luZ2Fwb3JlMQwwCgYDVQQKDANOdXcxEjAQBgNVBAMMCSoubnV3
            LnJ1bjEiMCAGCSqGSIb3DQEJARYTYm9uc291ZXJlQGdtYWlsLmNvbTCCASIwDQYJ
            KoZIhvcNAQEBBQADggEPADCCAQoCggEBAOZIx/N31FX0RLsN3Uo+GYjYc3m7bvPa
            7BCSJYQZpNvFkIQDEw+4q//Yq/u0NdhTwfi3lMc87vH5Sqycw0sBU5todE8SH78G
            qoUuchKdwnY7xHwx+IBto1pc0VZ5nxQ2xQh9W2GiTAYke8z16SxFXbF/NNk4J8fn
            DB3tP4da/04nw1Znw+6oE9dLtb2jRZneMuk46KF9speIOwoSz1D1/fiA+bfXc6Ks
            wY6+bmdNlS6droyqUrNhS+lLZI/klfGBPZ90Nw8NfynbYxJS6LQ7QFDhe8uEvokH
            /0svwUaGDCn4Uaz50TqdL4YbJreQ9nou3UpR4kLAW7Dy6V29QRAWwwECAwEAAaAA
            MA0GCSqGSIb3DQEBCwUAA4IBAQCi/xZfDCxNgstCRvfT6pqmq8D+cA1/rGebPMvF
            bJVxEAo76uSKuSmnvzNCF5QCDlbYbsQXii9mlyLE06X8njJ2QGommfX8aZJELabJ
            kbAk/GcIkx25G4vcu8d2v7OsHXcv+Nl2wVCnvlfYh/KeOGtJJ8fP3QQf8F6Bx2n3
            QzIX9IS9gId7oNCpFiVuWVmI5NATGV/yrqhzTZzGV1pyJeJoueBzE1IueFlXw8LE
            YHRN+r+lRbMhavdMhnJRaAX3MuJ9IBycgOBrHcJrmN6C0jLwgb9+aUMkAVejv0Ro
            wkyOGceRN95l0j7uhZ5WGRtZCasjQKbVtaskGDUUttw9BUM/
            -----END CERTIFICATE REQUEST-----
            """
            
            print("\nCREATE DNS CHALLENGES!!")
            try await Task.sleep(nanoseconds: 120_000_000_000)

            try await acme.orders.validateChallenges(from: order, preferring: .dns)
            let failedAuthorizations = try await acme.orders.wait(for: order, timeout: 120 /* in seconds*/)
            guard failedAuthorizations.count == 0 else {
                fatalError("\n#### Some challenges were not validated! \(failedAuthorizations)")
            }
            let finalized = try await acme.orders.finalize(order: order, withCsr: csr)
            let certs = try await acme.certificates.download(for: finalized)
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
