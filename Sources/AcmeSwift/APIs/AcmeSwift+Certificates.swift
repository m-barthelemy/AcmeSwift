import Foundation
import X509

extension AcmeSwift {
    /// APIs related to ACMEv2 certificates management.
    public var certificates: CertificatesAPI {
        .init(client: self)
    }
    
    public struct CertificatesAPI {
        fileprivate var client: AcmeSwift
        
        /// Downloads the certificate chain for a finalized Order.
        /// The certificates are returned a a list of PEM strings.
        /// The first item is the final certificate for the domain.
        /// The second item, if any, is the issuer certificate.
        public func download(`for` order: AcmeOrderInfo) async throws -> [String] {
            try await self.client.ensureLoggedIn()
            
            guard order.status == .valid, let certURL = order.certificate else {
                throw AcmeError.certificateNotReady(order.status, "Order must have a `valid` status. Some challenges might not have been completed yet")
            }

            let separator = "-----END CERTIFICATE-----\n"
            let ep = DownloadCertificateEndpoint(certURL: certURL)
            let (certificateChain, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            var certificates: [String] = []
            for certificate in  certificateChain.components(separatedBy: separator) {
                if certificate != "" {
                    certificates.append("\(certificate)\(separator)".trimmingCharacters(in: .newlines))
                }
            }
            return certificates
        }
        
        /// Revokes a previously issued certificate.
        /// - Parameters:
        ///   - certificatePem: The Certificate **in PEM format**.
        ///   - reason: An optional justification for the revocation.
        public func revoke(certificatePem: String, reason: AcmeRevokeReason? = nil) async throws {
            try await self.client.ensureLoggedIn()
            
            let csrBytes = certificatePem.pemToData()
            let pemStr = csrBytes.toBase64UrlString()
            
            let ep = RevokeCertificateEndpoint(
                directory: self.client.directory, 
                spec: .init(certificate: pemStr, reason: reason)
            )
            let (_, _) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
        }

        /// Gets the Automated Renewal Information for a certificate.
        /// - Parameters:
        ///   - certificate: The X509.Certificate.
        /// - Returns: Returns an `AcmeCertificateRenewalInfo` object with the currently recommended time window to renew the certificate (`suggestedWindow` property).
        ///
        ///   If a certificate issued by Let'sEncrypt is renewed during this interval, the renewal is exempted from rate limits.
        public func getRenewalInfo(for certificate: X509.Certificate) async throws -> AcmeCertificateRenewalInfo {
            try await self.client.ensureLoggedIn()

            guard var ariURL = self.client.directory.renewalInfo else {
                throw AcmeError.unsupportedFeature(\.renewalInfo)
            }

            let ariCertId = try certificate.getARICertId()
            ariURL.append(path: ariCertId)

            let ep = GetCertificateARIEndpoint(url: ariURL)
            var (ariInfo, headers) = try await self.client.run(ep, privateKey: self.client.login!.key, accountURL: client.accountURL!)
            if let retryAfterRaw = headers["Retry-After"].first, let retryAfterSec = Int(retryAfterRaw) {
                ariInfo.nextCheck = TimeInterval(retryAfterSec)
            }
            
            return ariInfo
        }

        /// Gets the Automated Renewal Information for a certificate.
        /// - Parameters:
        ///   - certificatePem: The Certificate **in PEM format**.
        /// - Returns: Returns an `AcmeCertificateRenewalInfo` object with the currently recommended time window to renew the certificate (`suggestedWindow` property).
        ///
        ///   If a certificate issued by Let'sEncrypt is renewed during this interval, the renewal is exempted from rate limits.
        public func getRenewalInfo(certificatePem: String) async throws -> AcmeCertificateRenewalInfo {
            let x509 = try Certificate(pemEncoded: certificatePem)
            return try await getRenewalInfo(for: x509)
        }
    }
}
