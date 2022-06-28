import Foundation
import Crypto

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
    }
}
