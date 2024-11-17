import Foundation
import Crypto
import _CryptoExtras
import JWTKit
import SwiftASN1
import X509

extension AcmeSwift {
    
    /// APIs related to ACMEv2 orders management.
    public var orders: OrdersAPI {
        .init(client: self)
    }
    
    public struct OrdersAPI {
        fileprivate var client: AcmeSwift
        
        
        /// List pending orders for the Account.
        ///
        /// - Warning: No ACMEv2 provider seems to have this actually implemented. Doesn't work with Let's Encrypt.
        public func list() async throws -> [URL] {
            try await self.client.ensureLoggedIn()
            
            let account = try await self.client.account.get()
            var orders: [URL] = []
            if let ordersURL = account.orders {
                let ep = ListOrdersEndpoint(url: ordersURL)
                let (orderInfo, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
                orders = orderInfo.orders
            }
            return orders
        }
        
        
        /// Fetches the latest status of an existing Order.
        /// - Parameters:
        ///   - url: The URL of the Order.
        public func get(url: URL) async throws -> AcmeOrderInfo {
            try await self.client.ensureLoggedIn()

            let ep = GetOrderEndpoint(url: url)
            var (info, headers) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            info.url = URL(string: headers["Location"].first ?? "")
            return info
        }
        
        /// Fetches the latest information about an existing Order.
        /// - Parameters:
        ///   - order: an existing Order object to be updated.
        public func refresh(_ order: inout AcmeOrderInfo) async throws {
            try await self.client.ensureLoggedIn()
            
            guard let url = order.url else {
                throw AcmeError.noResourceUrl
            }
            order = try await get(url: url)
        }
        
        
        /// Creates an Order for obtaining a new certificate.
        /// - Parameters:
        ///   - domains: The domains for which we want to create a certificate. Example: `["*.mydomain.com", "mydomain.com"]`.
        ///   - notBefore: Minimum Date when the future certificate will start being valid. **Note:** Let's Encrypt does not support setting this.
        ///   - notAfter: Desired expiration date of the future certificate. **Note:** Let's Encrypt does not support setting this.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func create(domains: [String], notBefore: Date? = nil, notAfter: Date? = nil) async throws -> AcmeOrderInfo {
            try await self.client.ensureLoggedIn()
            
            var identifiers: [AcmeOrderSpec.Identifier] = []
            for domain in domains {
                identifiers.append(.init(value: domain))
            }
            let ep = CreateOrderEndpoint(
                directory: self.client.directory,
                spec: .init(
                    identifiers: identifiers,
                    notBefore: notBefore,
                    notAfter: notAfter
                )
            )
            
            var (info, headers) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            info.url = URL(string: headers["Location"].first ?? "")
            return info
        }
        
        /// Finalizes an Order and send the CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - withPemCsr: The CSR (Certificate Signing Request) **in PEM format**.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func finalize(order: AcmeOrderInfo, withPemCsr: String) async throws -> AcmeOrderInfo {
            try await self.client.ensureLoggedIn()
            
            let csrBytes = withPemCsr.pemToData()
            let pemStr = csrBytes.toBase64UrlString()
            let ep = FinalizeOrderEndpoint(orderURL: order.finalize, spec: .init(csr: pemStr))
            
            let (info, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return info
        }

        /// Finalizes an Order and send the ECDSA CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - subject: Subject of certificate.
        ///   - domains: Domains for certificate.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  `Certificate.PrivateKey`, `CertificateSigningRequest` and `Account`.
        public func finalizeWithEcdsa(order: AcmeOrderInfo, subject: String? = nil, domains: [String]) async throws -> (Certificate.PrivateKey, CertificateSigningRequest, AcmeOrderInfo) {
            guard domains.count > 0 else {
                throw AcmeError.noDomains("At least 1 DNS name is required")
            }

            let p256 = P256.Signing.PrivateKey()
            let privateKey = Certificate.PrivateKey(p256)
            let commonName = subject ?? domains[0]
            let name = try DistinguishedName {
                CommonName(commonName)
            }
            let extensions = try Certificate.Extensions {
                SubjectAlternativeNames(domains.map({ GeneralName.dnsName($0) }))
            }
            let extensionRequest = ExtensionRequest(extensions: extensions)
            let attributes = try CertificateSigningRequest.Attributes(
                [.init(extensionRequest)]
            )
            let csr = try CertificateSigningRequest(
                version: .v1,
                subject: name,
                privateKey: privateKey,
                attributes: attributes,
                signatureAlgorithm: .ecdsaWithSHA256
            )
            
            let account = try await finalize(order: order, withCsr: csr)

            return (privateKey, csr, account)
        }

        /// Finalizes an Order and send the RSA CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - subject: Subject of certificate.
        ///   - domains: Domains for certificate.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  `Certificate.PrivateKey`, `CertificateSigningRequest` and `Account`.
        public func finalizeWithRsa(order: AcmeOrderInfo, subject: String? = nil, domains: [String]) async throws -> (Certificate.PrivateKey, CertificateSigningRequest, AcmeOrderInfo) {
            guard domains.count > 0 else {
                throw AcmeError.noDomains("At least 1 DNS name is required")
            }

            let p256 = try _CryptoExtras._RSA.Signing.PrivateKey(keySize: .bits2048)
            let privateKey = Certificate.PrivateKey(p256)
            let commonName = subject ?? domains[0]
            let name = try DistinguishedName {
                CommonName(commonName)
            }
            let extensions = try Certificate.Extensions {
                SubjectAlternativeNames(domains.map({ GeneralName.dnsName($0) }))
            }
            let extensionRequest = ExtensionRequest(extensions: extensions)
            let attributes = try CertificateSigningRequest.Attributes(
                [.init(extensionRequest)]
            )
            let csr = try CertificateSigningRequest(
                version: .v1,
                subject: name,
                privateKey: privateKey,
                attributes: attributes,
                signatureAlgorithm: .sha256WithRSAEncryption
            )

            let account = try await finalize(order: order, withCsr: csr)

            return (privateKey, csr, account)
        }
        
        /// Finalizes an Order and send the CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - withCsr: An instance of an `Certificate`.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func finalize(order: AcmeOrderInfo, withCsr csr: CertificateSigningRequest) async throws -> AcmeOrderInfo {
            try await self.client.ensureLoggedIn()

            var serializer = DER.Serializer()
            try serializer.serialize(csr)

            let csrBytes = Data(serializer.serializedBytes)
            let pemStr = csrBytes.toBase64UrlString()
            let ep = FinalizeOrderEndpoint(orderURL: order.finalize, spec: .init(csr: pemStr))
            
            let (info, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return info
        }
        
        /// Get the authorizations containing the challenges for this Order.
        /// - Parameters:
        ///   - from: The `AcmeOrderInfo` representing the certificates Order.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the list of `AcmeAuthorization` for this Order.
        public func getAuthorizations(from order: AcmeOrderInfo) async throws -> [AcmeAuthorization] {
            try await self.client.ensureLoggedIn()
            
            var authorizations: [AcmeAuthorization] = []
            for auth in order.authorizations {
                let ep = GetAuthorizationEndpoint(url: auth)
                let (authorization, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
                authorizations.append(authorization)
            }
            return authorizations
        }
        
        /// Gets a user-friendly list of the Order challenges that need to be published.
        ///
        /// These are the challenges that have a `pending` or `invalid` status.
        ///
        /// - Note: ALPN challenges are not returned.
        /// - Parameters:
        ///   - from: The `AcmeOrderInfo` representing the certificates Order.
        ///   - preferring: Your preferred challenge validation method. Note: when requesting a wildcard certificate, a challenge will have to be published over DNS regardless of your preferred method.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  a list of `ChallengeDescription` items that explain what information has to be published in order to validate the challenges.
        public func describePendingChallenges(from order: AcmeOrderInfo, preferring: AcmeAuthorization.Challenge.ChallengeType) async throws -> [ChallengeDescription] {
            
            let accountThumbprint = try getAccountThumbprint()
            let authorizations = try await getAuthorizations(from: order)
            var descs: [ChallengeDescription] = []
            for auth in authorizations where auth.status == .pending {
                for challenge in auth.challenges where (challenge.type == preferring || auth.wildcard == true) && (challenge.status == .pending || challenge.status == .invalid) {
                    let digest = "\(challenge.token).\(accountThumbprint.base64URLString)"
                    
                    if challenge.type == .dns {
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "_acme-challenge.\(auth.identifier.value)",
                            value: Crypto.SHA256.hash(data: Array(digest.utf8)).base64URLString,
                            url: challenge.url
                        )
                        descs.append(challengeDesc)
                    }
                    else if challenge.type == .http {
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "http://\(auth.identifier.value)/.well-known/acme-challenge/\(challenge.token)",
                            value: digest,
                            url: challenge.url
                        )
                        descs.append(challengeDesc)
                    }
                }
            }
            return descs
        }
        
        /// Call this to get the ACMEv2 provider to verify the pending challenges once you have published them over HTTP or DNS.
        ///
        /// Request challenges to be validated only after they have been published. 
        /// - For DNS-based challenges, repeatedly wait and poll until the order expires or becomes invalid, or a timeout you define has been passed.
        /// - For HTTP-based challenges, request verification once, then wait for the endpoints to have been called before requesting again. Similarly, repeat the process until the order expires or becomes invalid, or a timeout you define has been passed.
        ///
        /// - SeeAlso: [ACME Section 7.5.1 - Responding to Challenges](https://www.rfc-editor.org/rfc/rfc8555.html#section-7.5.1)
        ///
        /// - Parameters:
        ///   - from: The `AcmeOrderInfo` representing the certificates Order.
        ///   - preferring: Your preferred challenge validation method. Note: when requesting a wildcard certificate, a challenge will have to be published over DNS regardless of your preferred method..
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  a list of `AcmeAuthorization` containing the challenges that were not validated yet and may be in the process of being validated, or have failed.
        @discardableResult
        public func validateChallenges(from order: AcmeOrderInfo, preferring: AcmeAuthorization.Challenge.ChallengeType) async throws -> [AcmeAuthorization.Challenge] {
            // get pending challenges
            let pendingChallenges = try await describePendingChallenges(from: order, preferring: preferring)
            var updatedChallenges: [AcmeAuthorization.Challenge] = []
            for challengeDesc in pendingChallenges {
                updatedChallenges.append(try await validateChallenge(url: challengeDesc.url))
            }
            return updatedChallenges
        }
        
        /// Validates a single Challenge.
        public func validateChallenge(challenge: AcmeAuthorization.Challenge) async throws -> AcmeAuthorization.Challenge {
            try await self.client.ensureLoggedIn()
            
            let ep = ValidateChallengeEndpoint(challengeURL: challenge.url)
            let (updatedChallenge, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return updatedChallenge
        }
        
        
        /// Poll ACMEv2 provider for order status and return when challenges have been processed.
        /// - Parameters:
        ///   - for: The `AcmeOrderInfo` representing the certificates Order.
        ///   - timeout: Your preferred challenge validation method. Note: when requesting a wildcard certificate, a challenge will have to be published over DNS regardless of your preferred method..
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns a list of `AcmeAuthorization` that are not is a `valid` status.
        /*public func wait(`for` order: AcmeOrderInfo, timeout: TimeInterval) async throws -> [AcmeAuthorization] {
            let startDate = Date()
            let stopDate = startDate.addingTimeInterval(timeout)
            repeat {
                let authorizations = try await getAuthorizations(from: order)
                let pending = authorizations.filter({$0.status == .pending})
                if pending.count == 0 { break } // nothing to wait for
                try await Task.sleep(nanoseconds: 5_000_000_000)
            } while stopDate > Date()
            
            let notReady = try await getAuthorizations(from: order)
                .filter({$0.status != .valid})
            return notReady
        }*/
        
        private func validateChallenge(url: URL) async throws -> AcmeAuthorization.Challenge {
            try await self.client.ensureLoggedIn()
            
            let ep = ValidateChallengeEndpoint(challengeURL: url)
            let (updatedChallenge, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return updatedChallenge
        }
        
        /// Return the SHA256 digest of the ACMEv2 account public key's JWK JSON.
        ///
        /// This value has to be present in an HTTP challenge value.
        private func getAccountThumbprint() throws -> SHA256Digest {
            guard let login = self.client.login else {
                throw AcmeError.mustBeAuthenticated("\(AcmeSwift.self).init() must be called with an \(AccountCredentials.self)")
            }
            let pubKey = try JWTKit.ECDSAKey.public(pem: login.key.publicKey.pemRepresentation)
            guard let parameters = pubKey.parameters else {
                throw AcmeError.invalidKeyError("Public key parameters are nil")
            }
            
            let jwk = JWK(
                x: parameters.x,
                y: parameters.y
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            return Crypto.SHA256.hash(data: try encoder.encode(jwk))
        }
    }
}

extension SHA256Digest {
    var base64URLString: String {
        Data(self).base64EncodedString().base64ToBase64Url()
    }
}
