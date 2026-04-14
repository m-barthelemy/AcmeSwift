#if !canImport(Darwin)
import FoundationEssentials
#else
import Foundation
#endif
import AsyncHTTPClient
import Logging
import SwiftASN1
import X509
import Crypto

import Testing
import AcmeSwift

@Suite("ACMEv2 Orders")
struct OrderTests {
    var logger: Logger
    var http: HTTPClient
    let privateKeyPem: String
    let accountContacts: [String]

    private init() {
        self.logger = Logger.init(label: "acme-swift-tests")
        self.logger.logLevel = .debug

        let config = HTTPClient.Configuration(certificateVerification: .fullVerification, backgroundActivityLogger: self.logger)
        self.http = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: config
        )
        self.privateKeyPem = ProcessInfo.processInfo.environment["LETSENCRYPT_PRIVATE_KEY"]!

        guard let contact = ProcessInfo.processInfo.environment["LETSENCRYPT_CONTACT"] else {
            fatalError("LETSENCRYPT_CONTACTS is not set")
        }
        self.accountContacts = [contact]
    }

    @Test("List Orders")
    func listOrders() async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}

        let contacts = ["mailto:bonsouere3456@gmail.com"]

        let login = try AccountCredentials(contacts: contacts, pemKey: privateKeyPem)
        try acme.account.use(login)

        let urls = try await acme.orders.list()
        logger.info("•••••• Got \(urls.count) orders: \(urls)")
    }

    @Test("Create Order", arguments: [AcmeAuthorization.Challenge.ChallengeType.dns, .dnsPersist, .http])
    func testCreateOrder(_ challenge: AcmeAuthorization.Challenge.ChallengeType) async throws {
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}

        let contacts = ["mailto:bonsouere3456@gmail.com"]

        let login = try AccountCredentials(contacts: contacts, pemKey: privateKeyPem)
        try acme.account.use(login)

        let domains = ["burrito.run", "www.burrito.run"]
        var order = try await acme.orders.create(domains: domains)
        #expect(order.url != nil, "Ensure order has URL")

        #expect(order.status == .pending, "Ensure order is pending (got \(order.status)")
        #expect(order.expires > Date(), "Ensure order expiry is parsed (got \(order.expires)")
        #expect(order.identifiers.count == domains.count, "Ensure identifiers match number of requested domains (expected \(domains.count), got \(order.identifiers.count)")

        let authorizations = try await acme.orders.getAuthorizations(from: order)
        #expect(authorizations.count == domains.count, "Ensure we only have 1 authorization")

        let challengeDescriptions = try await acme.orders.describePendingChallenges(from: order, preferring: challenge)

        #expect(challengeDescriptions.count == 2, "Ensure we have \(domains.count) pending challenges")

        try await acme.orders.refresh(&order)
    }

    /*@Test("Create and Finalize Order")
    func testWrapItUpLikeABurrito() async throws {
        let contacts = ["mailto:bonsouere3456@gmail.com"]

        let login = try AccountCredentials(contacts: contacts, pemKey: privateKeyPem)
        let acme = try await AcmeSwift(client: self.http, acmeEndpoint: .letsEncryptStaging, logger: logger)
        defer {try? acme.syncShutdown()}

        try acme.account.use(login)
        let domains = ["acmeswift-tests-dns-persist-01.nuw.run"]

        do {
            var order = try await acme.orders.create(domains: domains)
            //try await Task.sleep(nanoseconds: 60_000_000_000)
            for desc in try await acme.orders.describePendingChallenges(from: order, preferring: .dnsPersist) {
                if desc.type == .http {
                    logger.info(" • The URL \(desc.endpoint) needs to return \(desc.value)")
                }
                else if desc.type == .dns || desc.type == .dnsAccount {
                    logger.info(" • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
                }
                else if desc.type == .dnsPersist {
                    logger.info(" • Create the following DNS Persistent record: \(desc.endpoint) TXT \(desc.value)")
                }
            }
            logger.info("=====> CREATE DNS CHALLENGES!!")
            try await Task.sleep(for: .seconds(30))

            var remainingChallenges = try await acme.orders.validateChallenges(from: order, preferring: .dnsPersist)
            for timeout in [5, 10, 10, 10, 10, 30] {
                guard !remainingChallenges.isEmpty else { break }
                try await Task.sleep(for: .seconds(timeout))
                remainingChallenges = try await acme.orders.validateChallenges(from: order, preferring: .dnsPersist)
            }
            // Give up if we still haven't satisfied the request:
            guard remainingChallenges.isEmpty else {
                fatalError("Some validations failed! \(remainingChallenges)")
            }
            logger.debug("Order: \(toJson(order))")

            let key = try await acme.orders.finalize(order: &order, type: .ecdsa(.p256))
            logger.info("Certificate ready for download!")
            let certs = try await acme.certificates.download(for: order)
            try certs.joined(separator: "\n").write(to: URL(fileURLWithPath: "cert.pem"), atomically: true, encoding: .utf8)

            try key.serializeAsPEM().pemString.write(to: URL(fileURLWithPath: "key.pem"), atomically: true, encoding: .utf8)
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
        return String(decoding: data, as: UTF8.self)
    }
}
