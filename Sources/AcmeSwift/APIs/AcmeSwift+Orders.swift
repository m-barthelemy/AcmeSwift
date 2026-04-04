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
            var (info, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            info.url = url
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
            order.url = url
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

        /// Creates an Order for obtaining a new certificate.
        /// - Parameters:
        ///   - permanentIdentifier: The hardware permanent identifier for which we want to create a certificate. Example: `"123456789" or "urn:ek:sha256:p4y5IVB2fMIpdusxon+MUwYU4o/7/tgvKB9fyu8Idko="`.
        ///   - notBefore: Minimum Date when the future certificate will start being valid. **Note:** Let's Encrypt does not support setting this.
        ///   - notAfter: Desired expiration date of the future certificate. **Note:** Let's Encrypt does not support setting this.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func create(permanentIdentifier: String, notBefore: Date? = nil, notAfter: Date? = nil) async throws -> AcmeOrderInfo {
            try await self.client.ensureLoggedIn()

            var identifiers: [AcmeOrderSpec.Identifier] = []
            identifiers.append(.init(type: .permanentIdentifier, value: permanentIdentifier))
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

        /// Creates the attestation payload used device-attest-01 challenges
        /// - Parameters:
        ///   - attObj: the base64url string with the WebAuthn attestation object.
        /// - Returns: returns the `AcmeAttestationSpec`.
        public func createAttestationPayload(attObj: String) -> AcmeAttestationSpec {
            return AcmeAttestationSpec(attObj: attObj)
        }

        /// Finalizes an Order, and generates a private key and CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - subject: Subject of certificate.
        ///   - type: The type of the private key and certificate. Default: `.ecdsa(.p384)` (ECDSA P-384).
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns the automatically generated `Certificate.PrivateKey`.
        public func finalize(order: inout AcmeOrderInfo, subject: String? = nil, type: KeyType = .ecdsa()) async throws -> Certificate.PrivateKey {

            guard order.identifiers.count > 0 else {
                throw AcmeError.noDomains("At least 1 DNS name is required")
            }

            var privateKey: Certificate.PrivateKey!
            var signatureAlg: Certificate.SignatureAlgorithm!
            switch type {
            case .ecdsa(let alg):
                switch alg {
                case .p256:
                    privateKey = .init(P256.Signing.PrivateKey())
                    signatureAlg = .ecdsaWithSHA256
                case .p384:
                    privateKey = .init(P384.Signing.PrivateKey())
                    signatureAlg = .ecdsaWithSHA384
                case .p521:
                    privateKey = .init(P521.Signing.PrivateKey())
                    signatureAlg = .ecdsaWithSHA512 // ?
                }
            case .rsa(let bits):
                var keySize: _RSA.Signing.KeySize!
                switch bits {
                case .`2048`:
                    keySize = .bits2048
                case .`3072`:
                    keySize = .bits3072
                case .`4096`:
                    keySize = .bits4096
                }
                privateKey = try .init(_CryptoExtras._RSA.Signing.PrivateKey(keySize: keySize))
                signatureAlg = .sha256WithRSAEncryption
            }
            let commonName = subject ?? order.identifiers[0].value
            let name = try DistinguishedName {
                CommonName(commonName)
            }
            let extensions = try Certificate.Extensions {
                SubjectAlternativeNames(order.identifiers.map({ GeneralName.dnsName($0.value) }))
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
                signatureAlgorithm: signatureAlg
            )

            try await finalize(order: &order, withCsr: csr)
            return privateKey
        }

        
        /// Finalizes an Order and send the CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - withCsr: An instance of a `CertificateSigningRequest`.
        /// - Throws: Errors that can occur when executing the request.
        public func finalize(order: inout AcmeOrderInfo, withCsr csr: CertificateSigningRequest) async throws {
            var serializer = DER.Serializer()
            try serializer.serialize(csr)

            let csrBytes = Data(serializer.serializedBytes)
            try await finalize(order: &order, csrBytes: csrBytes)
        }

        /// Finalizes an Order and send the CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`.
        ///   - withPemCsr: The CSR (Certificate Signing Request) **in PEM format**.
        /// - Throws: Errors that can occur when executing the request.
        public func finalize(order: inout AcmeOrderInfo, withPemCsr: String) async throws {
            let csrBytes = withPemCsr.pemToData()
            try await finalize(order: &order, csrBytes: csrBytes)
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

                    switch challenge.type {
                    case .dns:
                        guard let token = challenge.token else {
                            throw AcmeError.missingChallengeToken
                        }
                        let digest = "\(token).\(accountThumbprint.base64URLString)"
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "_acme-challenge.\(auth.identifier.value)",
                            value: Crypto.SHA256.hash(data: Array(digest.utf8)).base64URLString,
                            token: token,
                            url: challenge.url
                        )
                        descs.append(challengeDesc)

                    case .http:
                        guard let token = challenge.token else {
                            throw AcmeError.missingChallengeToken
                        }
                        let digest = "\(token).\(accountThumbprint.base64URLString)"
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "http://\(auth.identifier.value)/.well-known/acme-challenge/\(token)",
                            value: digest,
                            token: token,
                            url: challenge.url
                        )
                        descs.append(challengeDesc)

                    case .deviceAttest:
                        guard let token = challenge.token else {
                            throw AcmeError.missingChallengeToken
                        }
                        let digest = "\(token).\(accountThumbprint.base64URLString)"
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "",
                            value: digest,
                            token: token,
                            url: challenge.url
                        )
                        descs.append(challengeDesc)

                    case .dnsPersist:
                        guard let issuerDomainName = challenge.issuerDomainNames?.first else {
                            throw AcmeError.noIssuerDomainReturned
                        }
                        var digest = "\(issuerDomainName); accounturi=\(client.accountURL!)"
                        if let isWildcard = auth.wildcard, isWildcard {
                            digest += "; policy=wildcard"
                        }
                        let challengeDesc = ChallengeDescription(
                            type: preferring,
                            endpoint: "_validation-persist.\(auth.identifier.value)",
                            value: digest,
                            token: nil,
                            url: challenge.url
                        )
                        descs.append(challengeDesc)

                    default:
                        throw AcmeError.unsupportedChallenge(type: challenge.type)
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
        public func validateChallenges(from order: AcmeOrderInfo, preferring: AcmeAuthorization.Challenge.ChallengeType, payload: Codable? = nil) async throws -> [AcmeAuthorization.Challenge] {
            // get pending challenges
            let pendingChallenges = try await describePendingChallenges(from: order, preferring: preferring)
            var updatedChallenges: [AcmeAuthorization.Challenge] = []
            for challengeDesc in pendingChallenges {
                if challengeDesc.type == .deviceAttest {
                    updatedChallenges.append(try await validateAttestationChallenge(url: challengeDesc.url, payload: payload as! AcmeAttestationSpec))
                } else {
                    updatedChallenges.append(try await validateChallenge(url: challengeDesc.url))
                }
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
        
        private func validateChallenge(url: URL) async throws -> AcmeAuthorization.Challenge {
            try await self.client.ensureLoggedIn()
            
            let ep = ValidateChallengeEndpoint(challengeURL: url)
            let (updatedChallenge, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return updatedChallenge
        }

        private func validateAttestationChallenge(url: URL, payload: AcmeAttestationSpec) async throws -> AcmeAuthorization.Challenge {
            try await self.client.ensureLoggedIn()

            let ep = ValidateAttestationChallengeEndpoint(challengeURL: url, spec: payload)
            let (updatedChallenge, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return updatedChallenge
        }

        private func finalize(order: inout AcmeOrderInfo, csrBytes: Data) async throws {
            try await self.client.ensureLoggedIn()

            let pemStr = csrBytes.toBase64UrlString()
            let ep = FinalizeOrderEndpoint(orderURL: order.finalize, spec: .init(csr: pemStr))

            let (info, headers) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            order = info
            if order.url == nil {
                order.url = URL(string: headers["Location"].first ?? "")
            }
            /* RFC8555
             "processing": The certificate is being issued. Send a POST-as-GET
             request after the time given in the Retry-After header field of
             the response, if any.
            */
            while order.status == .processing {
                var delay: Duration = .seconds(3)
                if let recommendedRaw = headers["retry-after"].first, let recommended = Int(recommendedRaw) {
                    delay = .seconds(recommended)
                }
                self.client.logger.debug("Order still in \(order.status) status, will check in \(delay)...")
                try await Task.sleep(for: delay)
                try await self.refresh(&order)
            }
            if order.url == nil {
                order.url = URL(string: headers["Location"].first ?? "")
            }
        }

        /// Return the SHA256 digest of the ACMEv2 account public key's JWK JSON.
        ///
        /// This value has to be present in an HTTP challenge value.
        private func getAccountThumbprint() throws -> SHA256Digest {
            guard let login = self.client.login else {
                throw AcmeError.mustBeAuthenticated("\(AcmeSwift.self).init() must be called with an \(AccountCredentials.self)")
            }
            
            let publicKey = login.key.publicKey.rawRepresentation
            
            let jwk = JWK.ecdsa(
                nil,
                identifier: nil,
                x: publicKey.prefix(publicKey.count/2).toBase64UrlString(),
                y: publicKey.suffix(publicKey.count/2).toBase64UrlString(),
                curve: .p256
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            return Crypto.SHA256.hash(data: try encoder.encode(jwk))
        }
    }

    @nonexhaustive
    public enum KeyType: Sendable {
        case rsa(_ bits: RSABits = .`2048`)
        case ecdsa(_ bits: ECCBits = .p384)

        @nonexhaustive
        public enum RSABits: Sendable {
            case `2048`
            case `3072`
            case `4096`
        }

        @nonexhaustive
        public enum ECCBits: Sendable {
            /// secp256r1 or prime256v1
            case p256
            /// secp384r1 or prime384v1
            case p384
            /// secp521r1 or prime521v1.
            /// May not be supported by all CAs.
            case p521
        }
    }
}

extension SHA256Digest {
    var base64URLString: String {
        Data(self).toBase64UrlString()
    }
}

