import Foundation
import Crypto

extension AcmeSwift {
    /// APIs related to ACMEv2 certificates management.
    public var certificates: CertificatesAPI {
        .init(client: self)
    }
    
    public struct CertificatesAPI {
        private let separator = "-----END CERTIFICATE-----\n"
        fileprivate var client: AcmeSwift
        
        /// Download the certificate chain for a finalized Order.
        /// The certificates are returned a a list of PEM strings.
        /// The first item is the final certificate for the domain.
        /// The second item, if any, is the issuer certificate.
        public func download(order: AcmeOrderInfo) async throws -> [String] {
            guard let login = self.client.login else {
                throw AcmeError.mustBeAuthenticated("\(AcmeSwift.self).init() must be called with an \(AccountCredentials.self)")
            }
            guard order.status == .valid, let certURL = order.certificate else {
                throw AcmeError.certificateNotReady(order.status, "Order must have a `valid` status. Some challenges might not have been completed yet")
            }
            
            if client.accountURL == nil {
                let info = try await self.client.account.get()
                client.accountURL = info.url
            }
            
            let ep = DownloadCertificateEndpoint(certURL: certURL)
            let (certificateChain, _) = try await self.client.run(ep, privateKey: login.key, accountURL: client.accountURL!)
            return certificateChain.components(separatedBy: self.separator).map{ str in
                return "\(str)\(separator)"
            }
        }
        
        public func revoke() async throws {
            
        }
    }
}
