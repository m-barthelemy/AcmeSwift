import Foundation
import PotentASN1

struct X509CertificateSigningRequest: Codable {
    var certificationRequestInfo: X509CertificateRequestInfo
    var signatureAlgorithm: X509SignatureAlgorithm
    var signature: Data
    
    public init(
        certificationRequestInfo: X509CertificateRequestInfo,
        signatureAlgorithm: X509SignatureAlgorithm,
        signature: Data
    ) {
        self.certificationRequestInfo = certificationRequestInfo
        self.signatureAlgorithm = signatureAlgorithm
        self.signature = signature
    }
}


