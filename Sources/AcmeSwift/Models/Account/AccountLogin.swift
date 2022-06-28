import Foundation
import Crypto

public struct AccountLogin {
    private (set) public var contacts: [String] = []
    private (set) public var key: Crypto.P256.Signing.PrivateKey
    
    public init(contacts: [String], pemKey: String) throws {
        let privateKey = try Crypto.P256.Signing.PrivateKey.init(pemRepresentation: pemKey)
        self.init(contacts: contacts, key: privateKey)
    }
    
    public init(contacts: [String], key: Crypto.P256.Signing.PrivateKey) {
        self.key = key
        for var contact in contacts {
            if contact.firstIndex(of: ":") == nil {
                contact = "mailto:" + contact
            }
            self.contacts.append(contact)
        }
    }
    
}
