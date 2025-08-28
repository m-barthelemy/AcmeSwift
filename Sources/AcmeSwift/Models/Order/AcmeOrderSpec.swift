import Foundation


public struct AcmeOrderSpec: Codable, Sendable {
    public init(identifiers: [AcmeOrderSpec.Identifier], notBefore: Date? = nil, notAfter: Date? = nil) {
        self.identifiers = identifiers
        self.notBefore = notBefore
        self.notAfter = notAfter
    }
    
    public var identifiers: [Identifier]
    
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
