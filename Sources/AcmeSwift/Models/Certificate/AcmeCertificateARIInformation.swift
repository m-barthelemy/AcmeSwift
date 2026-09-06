import Foundation

/// Information about the recommended renewal window for a certificate.
public struct AcmeCertificateRenewalInfo: Sendable {

    /// The window of time in which the CA recommends renewing the certificate.
    public let suggestedWindow: SuggestedRenewalWindow

    /// A URL pointing to a page that may explain why the suggested renewal window has its current value.
    public let explanationURL: URL?

    /// Recommended amount of time (in seconds) after which this renewal info should be fetched again.
    internal(set) public var nextCheck: TimeInterval? = nil

    public struct SuggestedRenewalWindow: Sendable {
        public let start: Date
        public let end: Date
    }
}

extension AcmeCertificateRenewalInfo: Codable {}
extension AcmeCertificateRenewalInfo.SuggestedRenewalWindow: Codable {}
