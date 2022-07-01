import Foundation
import Crypto
import JWTKit

extension AcmeSwift {
    
    /// APIs related to ACMEv2 orders management.
    public var orders: OrdersAPI {
        .init(client: self)
    }
    
    public struct OrdersAPI {
        fileprivate var client: AcmeSwift
        
        
        /// List pending orders for the Account.
        /// WARNING: no ACMEv2 provider seems to have this actually implemented. Doesn't work with Lets Encrypt.
        public func list() async throws -> [URL] {
            try await self.client.ensureLogged()
            
            let account = try await self.client.account.get()
            var orders: [URL] = []
            if let ordersURL = account.orders {
                let ep = ListOrdersEndpoint(url: ordersURL)
                let (orderInfo, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
                orders = orderInfo.orders
            }
            return orders
        }
        
        /// Creates an Order for obtaining a new certificate.
        /// - Parameters:
        ///   - domains: The domains for which we want to create a certificate. Example: `["*.mydomain.com", "mydomain.com"]`
        ///   - notBefore: Minimum Date when the future certificate will start being valid. **Note:** Let's Encrypt does not support setting this.
        ///   - notAfter: Desired expiration date of the future certificate. **Note:** Let's Encrypt does not support setting this.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func create(domains: [String], notBefore: Date? = nil, notAfter: Date? = nil) async throws -> AcmeOrderInfo {
            try await self.client.ensureLogged()
            
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
            
            let (info, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return info
        }
        
        /// Finalizes an Order and send the CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`
        ///   - withCsr: The CSR (Certificate Signing Request) **in PEM format**.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func finalize(order: AcmeOrderInfo, withPemCsr: String) async throws -> AcmeOrderInfo {
            try await self.client.ensureLogged()
            
            let csrBytes = withPemCsr.pemToData()
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
            try await self.client.ensureLogged()
            
            var authorizations: [AcmeAuthorization] = []
            for auth in order.authorizations {
                let ep = GetAuthorizationEndpoint(url: auth)
                let (authorization, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
                authorizations.append(authorization)
            }
            return authorizations
        }
        
        /// Gets a user-friendly list of the Order challenges that need to be published.
        /// These are the challenges that have a `pending` or `invalid` status.
        /// NOTE: ALPN challenges are not returned.
        /// - Parameters:
        ///   - from: The `AcmeOrderInfo` representing the certificates Order.
        ///   - preferring: Your preferred challenge validation method. Note: when requesting a wildcard certificate, a challenge will have to be published over DNS regardless of your preferred method..
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  a list of `ChallengeDescription` items that explain what information has to be published in order to validate the challenges.
        public func describePendingChallenges(from order: AcmeOrderInfo, preferring: AcmeAuthorization.Challenge.ChallengeType) async throws -> [ChallengeDescription] {
            
            let accountThumbprint = try getAccountThumbprint()
            let authorizations = try await getAuthorizations(from: order)
            var descs: [ChallengeDescription] = []
            for auth in authorizations.filter({$0.status == .pending}) {
                for challenge in auth.challenges.filter({
                    ($0.type == preferring || auth.wildcard == true) && ($0.status == .pending || $0.status == .invalid)
                }) {
                    let digest = "\(challenge.token).\(accountThumbprint.base64EncodedString().base64ToBase64Url())"
                    if challenge.type == .dns {
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "_acme-challenge.\(auth.identifier.value)",
                            value: sha256Digest(data: digest.data(using: .utf8)!).base64EncodedString().base64ToBase64Url(),
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
        
        /// Call this to get the ACMEv2 provider to verify the pending challenges once you have published them over HTTP or DNS
        /// - Parameters:
        ///   - from: The `AcmeOrderInfo` representing the certificates Order.
        ///   - preferring: Your preferred challenge validation method. Note: when requesting a wildcard certificate, a challenge will have to be published over DNS regardless of your preferred method..
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  a list of `AcmeAuthorization` containing the challenges that could **not** be validated.
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
            try await self.client.ensureLogged()
            
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
        public func wait(`for` order: AcmeOrderInfo, timeout: TimeInterval) async throws -> [AcmeAuthorization] {
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
        }
        
        private func validateChallenge(url: URL) async throws -> AcmeAuthorization.Challenge {
            try await self.client.ensureLogged()
            
            let ep = ValidateChallengeEndpoint(challengeURL: url)
            let (updatedChallenge, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            return updatedChallenge
        }
        
        /// Return the SHA256 digest of the ACMEv2 account public key's JWK JSON.
        /// This value has to be present in an HTTP challenge value.
        private func getAccountThumbprint() throws -> Data {
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
            let jwkData = try! encoder.encode(jwk)
            return sha256Digest(data: jwkData)
        }
        
        private func sha256Digest(data: Data) -> Data {
            let digest: SHA256Digest = Crypto.SHA256.hash(data: data)
            let array = digest.compactMap{UInt8($0)}
            let hashData = Data(array)
            return hashData
            /*return String(data: data, encoding: .utf8)!
            return digest.map { String(format: "%02x", $0) }.joined()*/
        }
        
    }
}
