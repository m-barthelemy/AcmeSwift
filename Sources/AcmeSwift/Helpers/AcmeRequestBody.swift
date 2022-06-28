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
        
        let pubKey = try JWTKit.ECDSAKey.public(pem: privateKey.publicKey.pemRepresentation)
        guard let parameters = pubKey.parameters else {
            throw AcmeError.invalidKeyError("Public key parameters are nil")
        }
        
        self.protected = .init(
            alg: .es256,
            jwk: accountURL == nil ?  .init(
                x: parameters.x,
                y: parameters.y
            ) : nil,
            kid: accountURL,
            nonce: nonce,
            url: payload.url
        )
        self.payload = payload.body ?? (NoBody.init() as! T.Body)
    }
    
    /// Encode as a JWT as  described in ACMEv2 (RFC 8555)
    func encode(to encoder: Encoder) throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        let protectedData = try jsonEncoder.encode(self.protected)
        guard let protectedJson = String(data: protectedData, encoding: .utf8) else {
            throw AcmeError.jwsEncodeError("Unable to encode AcmeRequestBody.protected as JSON string")
        }
        let protectedBase64 = protectedJson.toBase64Url()
        
        let payloadData = try jsonEncoder.encode(self.payload)
        guard let payloadJson = String(data: payloadData, encoding: .utf8) else {
            throw AcmeError.jwsEncodeError("Unable to encode AcmeRequestBody.payload as JSON string")
        }
        let payloadBase64 = payloadJson.toBase64Url()
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(protectedBase64, forKey: .protected)
        try container.encode(payloadBase64, forKey: .payload)
        
        let signedString = "\(protectedBase64).\(payloadBase64)"
        guard let signedData = signedString.data(using: .utf8) else {
            throw AcmeError.jwsEncodeError("Unable to encode data to sign String as Data")
        }
        
        let signature = try self.privateKey.signature(for: signedData)
        let signatureData = signature.rawRepresentation
        
        let signatureBase64 = signatureData.toBase64UrlString()
        try container.encode(signatureBase64, forKey: .signature)
    }
    
    struct NoBody: Codable {
        init(){}
    }
}

public struct JWK: Codable {
    /// Key Type
    private(set) public var kty: KeyType = .ec
    
    /// Curve
    private(set) public var crv: CurveType = .p256
    
    /// The x coordinate for the Elliptic Curve point.
    private(set) public var x: String
    
    /// The y coordinate for the Elliptic Curve point.
    private(set) public var y: String
    
    public enum KeyType: String, Codable {
        case ec = "EC"
        case rsa = "RSA"
        case oct
    }
    
    public enum CurveType: String, Codable {
        case p256 = "P-256"
    }
}
