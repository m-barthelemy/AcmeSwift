import Foundation

/// Account information returned when calling `get()` or `create()`
public struct AcmeAccountInfo: Codable {
    public let key: JWK
    internal(set) public var privateKeyPem: String?
    public let contact: [String]
    public let initialIp: String
    public let createdAt: Date
    public let status: Status
    
    public enum Status: String, Codable {
        case valid, deactivated
    }
}
