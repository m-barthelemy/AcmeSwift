import Foundation
import Crypto

public struct CSR {
    internal(set) public var key: Crypto.P256.Signing.PrivateKey
    internal(set) public var subject: X509Subject
    internal(set) public var domains: [String]
    
    public init(key: Crypto.P256.Signing.PrivateKey = .init(), subject: X509Subject? = nil, domains: [String]) throws {
        guard domains.count > 0 else {
            throw X509Error.noDomains("At least 1 DNS name is required")
        }
        self.domains = domains
        self.subject = subject ?? .init(commonName: domains.first!)
        self.key = key
    }
    
    public init(keyPem: String, subject: X509Subject? = nil, domains: [String]) throws {
        let key = try Crypto.P256.Signing.PrivateKey.init(pemRepresentation: keyPem)
        try self.init(key: key, subject: subject, domains: domains)
    }
}
