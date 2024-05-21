import Foundation


struct CertificateRevokeSpec: Codable {
    /// PEM representation of the certificate.
    public var certificate: String
    
    /// Reason for the revocation.
    public var reason: AcmeRevokeReason?
}

/// Reason why we request for a certificate to be revoked.
public enum AcmeRevokeReason: Int, Codable, Sendable {
    case unspecified = 0
    case keyCompromise = 1
    case cACompromise = 2
    case affiliationChanged = 3
    case superseded = 4
    case cessationOfOperation = 5
    case certificateHold = 6
    case removeFromCRL = 8
    case privilegeWithdrawn = 9
    case aACompromise = 10
}
