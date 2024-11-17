import Foundation
import Crypto
import JWTKit

/*
Example request body:
 {
     "protected": base64url({
         "alg": "ES256",
         "jwk": {...},
         "nonce": "6S8IqOGY7eL2lsGoTZYifg",
         "url": "https://example.com/acme/new-account"
     }),
     "payload": base64url({
         "termsOfServiceAgreed": true,
         "contact": [
            "mailto:cert-admin@example.org",
            "mailto:admin@example.org"
         ]
     }),
     "signature": "RZPOnYoPs1PhjszF...-nh6X1qtOFPB519I"
 }
*/

/// All requests to the ACMEv2 server must have their body wrapped into a custom JWS format
struct AcmeRequestBody<T: EndpointProtocol>: Encodable {
    var protected: ProtectedHeader
    
    var payload: T.Body
    
    private var signature: String = ""
    
    private var privateKey: Crypto.P256.Signing.PrivateKey
    
    enum CodingKeys: String, CodingKey {
        case protected
        case payload
        case signature
    }
    
    struct ProtectedHeader: Codable {
        internal init(alg: Algorithm = .es256, jwk: JWK? = nil, kid: URL? = nil, nonce: String, url: URL) {
            self.alg = alg
            self.jwk = jwk
            self.kid = kid
            self.nonce = nonce
            self.url = url
        }
        
        var alg: Algorithm = .es256
        var jwk: JWK?
        var kid: URL?
        var nonce: String
        var url: URL
        
        enum Algorithm: String, Codable {
            case es256 = "ES256"
        }
        
    }
    
    init(accountURL: URL? = nil, privateKey: Crypto.P256.Signing.PrivateKey, nonce: String, payload: T) throws {
        self.privateKey = privateKey
        let publicKey = privateKey.publicKey.rawRepresentation
        
        self.protected = .init(
            alg: .es256,
            jwk: accountURL == nil ? JWTKit.JWK.ecdsa(
                nil,
                identifier: nil,
                x: publicKey.prefix(upTo: publicKey.count/2).base64EncodedString(),
                y: publicKey.suffix(from: publicKey.count/2).base64EncodedString(),
                curve: nil
            ) : nil,
            kid: accountURL,
            nonce: nonce,
            url: payload.url
        )
        self.payload = payload.body ?? (NoBody.init() as! T.Body)
    }
    
    /// Encode as a JWT as described in ACMEv2 (RFC 8555).
    func encode(to encoder: Encoder) throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = .sortedKeys
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let protectedData = try jsonEncoder.encode(self.protected)
        let protectedJSON = String(decoding: protectedData, as: UTF8.self)
        let protectedBase64 = protectedJSON.toBase64Url()
        try container.encode(protectedBase64, forKey: .protected)
        
        let payloadData = try jsonEncoder.encode(self.payload)
        let payloadJSON = String(decoding: payloadData, as: UTF8.self)
        
        // Empty payload is required most of the time for so-called POST-AS-GET ACMEv2 requests.
        let payloadBase64 = payloadJSON == "\"\"" ? "" : payloadJSON.toBase64Url()
        try container.encode(payloadBase64, forKey: .payload)
        
        let signedString = "\(protectedBase64).\(payloadBase64)"
        let signature = try self.privateKey.signature(for: Data(signedString.utf8))
        let signatureData = signature.rawRepresentation
        
        let signatureBase64 = signatureData.toBase64UrlString()
        try container.encode(signatureBase64, forKey: .signature)
    }
}

/// For requests that have an empty body.
struct NoBody: Codable {
    init(){}
}
