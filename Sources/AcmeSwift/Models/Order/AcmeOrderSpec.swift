import Foundation

public struct AcmeOrderSpec: Sendable {
    public init(identifiers: [AcmeOrderSpec.Identifier], replaces: String? = nil, notBefore: Date? = nil, notAfter: Date? = nil) {
        self.identifiers = identifiers
        self.notBefore = notBefore
        self.notAfter = notAfter
        self.replaces = replaces
    }
    
    public var identifiers: [Identifier]

    /// The ARI CertID if we're trying to renew a previous certificate.
    public var replaces: String?

    /// The requested value of the notBefore field in the certificate.
    public var notBefore: Date? = nil
    
    /// The requested value of the notAfter field in the certificate.
    public var notAfter: Date? = nil
    
    public struct Identifier: Codable, Sendable {

        public var `type`: IdentifierType = .dns
        
        public var value: String
        
        public enum IdentifierType: String, Codable, Sendable {
            case dns
            case permanentIdentifier = "permanent-identifier"
        }
    }
}

extension AcmeOrderSpec: Codable {}
