import Foundation
import Crypto
import _CryptoExtras

public extension Crypto.P256.Signing.PrivateKey {
    /// A PEM encoded representation of the private key.
    /// If `withHeaders` is set to `true`, the returned value can be used as-is by most software using PEM keys.
    func pemEncoded(withHeaders: Bool = true) -> String {
        let privateKeyData = self.derRepresentation.base64EncodedString(options: .lineLength64Characters)
        if !withHeaders {
            return privateKeyData
        }
        else {
            return """
            -----BEGIN EC PRIVATE KEY-----
            \(privateKeyData)
            -----END EC PRIVATE KEY----
            """
        }
    }
}

public extension _CryptoExtras._RSA.Signing.PrivateKey {
    /// A PEM encoded representation of the private key.
    /// If `withHeaders` is set to `true`, the returned value can be used as-is by most software using PEM keys.
    func pemEncoded(withHeaders: Bool = true) -> String {
        let privateKeyData = self.derRepresentation.base64EncodedString(options: .lineLength64Characters)
        if !withHeaders {
            return privateKeyData
        }
        else {
            return """
            -----BEGIN PRIVATE KEY-----
            \(privateKeyData)
            -----END PRIVATE KEY----
            """
        }
    }
}
