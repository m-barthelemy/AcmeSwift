import Foundation


public struct OrderSpec: Codable {
    
    public var identifiers: [Identifier]
    
    /// The requested value of the notBefore field in the certificate
    public var notBefore: Date
    
    /// The requested value of the notAfter field in the certificate
    public var notAfter: Date
    
    public struct Identifier: Codable {
        
        public var `type`: IdentifierType = .dns
        
        public var value: String
        
        public enum IdentifierType: String, Codable {
            case dns
        }
    }
}
