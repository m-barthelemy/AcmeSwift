import Foundation

/// Account information returned when calling `get()` or `create()`
public struct AcmeAccountInfo: Codable {
    /// Information about the Account private key in JWK format
    public let key: JWK
    
    /// The PEM representation of the private key for this Account
    internal(set) public var privateKeyPem: String?
    
    /// The contact entries
    public let contact: [String]
    
    ///
    public let initialIp: String
    
    /// Date when the Account was created
    public let createdAt: String
    
    /// Current status of the Account
    public let status: Status
    
    public enum Status: String, Codable {
        case valid, deactivated
    }
}
