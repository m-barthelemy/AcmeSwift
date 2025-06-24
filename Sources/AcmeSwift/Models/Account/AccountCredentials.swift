import Foundation
import Crypto

public struct AccountCredentials {
    private(set) public var contacts: [String] = []
    private(set) public var key: Crypto.P256.Signing.PrivateKey
    
    public init(contacts: [String], pemKey: String) throws {
        let privateKey = try Crypto.P256.Signing.PrivateKey.init(pemRepresentation: pemKey)
        self.init(contacts: contacts, key: privateKey)
    }
    
    public init(contacts: [String], key: Crypto.P256.Signing.PrivateKey) {
        self.key = key
        self.contacts = contacts.map { $0.contains(":") ? $0 : "mailto:\($0)" }
    }
}
