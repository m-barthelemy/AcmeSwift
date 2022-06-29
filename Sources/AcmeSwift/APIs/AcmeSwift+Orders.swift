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
        
        /// Creates an Order for obtaining a new certificate.
        /// - Parameters:
        ///   - domains: The domains for which we want to create a certificate. Example: `["*.mydomain.com", "mydomain.com"]`
        ///   - notBefore: Minimum Date when the future certificate will start being valid. **Note:** Let's Encrypt does not support setting this.
        ///   - notAfter: Desired expiration date of the future certificate. **Note:** Let's Encrypt does not support setting this.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func create(domains: [String], notBefore: Date? = nil, notAfter: Date? = nil) async throws -> AcmeOrderInfo {
            guard let login = self.client.login else {
                throw AcmeError.mustBeAuthenticated("\(AcmeSwift.self).init() must be called with an \(AccountCredentials.self)")
            }
            
            if client.accountURL == nil {
                let info = try await self.client.account.get()
                client.accountURL = info.url
            }
            
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
            
            let (info, _) = try await self.client.run(ep, privateKey: login.key, accountURL: client.accountURL!)
            return info
        }
        
        /// Finalizes an Order and send the CSR.
        /// - Parameters:
        ///   - order: The `AcmeOrderInfo` returned by the call to `.create()`
        ///   - withCsr: The CSR (Certificate Signing Request) **in PEM format**.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func finalize(order: AcmeOrderInfo, withCsr: String) async throws -> AcmeOrderInfo {
            guard let login = self.client.login else {
                throw AcmeError.mustBeAuthenticated("\(AcmeSwift.self).init() must be called with an \(AccountCredentials.self)")
            }
            
            if client.accountURL == nil {
                let info = try await self.client.account.get()
                client.accountURL = info.url
            }
            
            let ep = FinalizeOrderEndpoint(orderURL: order.finalize, spec: .init(csr: withCsr))
            
            let (info, _) = try await self.client.run(ep, privateKey: login.key, accountURL: client.accountURL!)
            return info
        }
        
        public func getAuthorizations(order: AcmeOrderInfo) async throws -> [AcmeAuthorization] {
            guard let login = self.client.login else {
                throw AcmeError.mustBeAuthenticated("\(AcmeSwift.self).init() must be called with an \(AccountCredentials.self)")
            }
            
            if client.accountURL == nil {
                let info = try await self.client.account.get()
                client.accountURL = info.url
            }
            
            var authorizations: [AcmeAuthorization] = []
            for auth in order.authorizations {
                let ep = GetAuthorizationEndpoint(url: auth)
                let (authorization, _) = try await self.client.run(ep, privateKey: login.key, accountURL: client.accountURL!)
                authorizations.append(authorization)
            }
            return authorizations
        }
        
        /// Gets a user-friendly list of the Order challenges that need to be published.
        public func describePendingChallenges(from order: AcmeOrderInfo, preferring: AcmeAuthorization.Challenge.ChallengeType) async throws -> [ChallengeDescription] {
            
            let accountThumbprint = try getAccountThumbprint()
            let authorizations = try await getAuthorizations(order: order)
            var descs: [ChallengeDescription] = []
            for auth in authorizations.filter({$0.status == .pending}) {
                for challenge in auth.challenges.filter({
                    ($0.type == preferring || auth.wildcard == true) && $0.status == .pending
                }) {
                    if challenge.type == .dns {
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "_acme-challenge.\(auth.identifier.value)",
                            value: challenge.token
                        )
                        descs.append(challengeDesc)
                    }
                    else if challenge.type == .http {
                        let challengeDesc = ChallengeDescription(
                            type: challenge.type,
                            endpoint: "http://\(auth.identifier.value)/.well-known/acme-challenge/\(challenge.token)",
                            value: "\(challenge.token).\(accountThumbprint.toBase64Url())"
                        )
                        descs.append(challengeDesc)
                    }
                }
            }
            return descs
        }
        
        /// Return the SHA256 digest of the ACMEv2 account public key's JWK JSON.
        /// This value has to be present in an HTTP challenge value.
        private func getAccountThumbprint() throws -> String {
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
            let digest: SHA256Digest = Crypto.SHA256.hash(data: jwkData)
            return digest.compactMap { String(format: "%02hhx", $0) }.joined()
        }
        /// Call this to get the ACMEv2 provider to verify the challenges once you have published them over HTTP or DNS
        /*public func validatechallenges(order: AcmeOrderInfo) async throws -> [AcmeAuthorization] {
            
        }*/
    }
}
