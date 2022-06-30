import Foundation

/// Account information returned when calling `get()` or `create()`
public struct AcmeAccountInfo: Codable {
    
    /// URL containing the ID of the Account
    /// This URL is used to performa some account management operations.
    internal(set) public var url: URL?
    
    /// Information about the Account public key in JWK format
    public let key: JWK
    
    /// The PEM representation of the private key for this Account
    internal(set) public var privateKeyPem: String?
    
    /// The contact entries
    public let contact: [String]
    
    /// Source IP (as seen by the ACME servers) from which the Account was created
    public let initialIp: String
    
    /// Date when the Account was created
    public let createdAt: String
    
    /// Current status of the Account
    public let status: Status
    
    /// URL to the pending orders for this account
    /// No provider seems to have this fully implemented
    public let orders: URL?
    
    public enum Status: String, Codable {
        case valid, deactivated
    }
}
