import Foundation
import Crypto
import _CryptoExtras
import PotentASN1
import CryptoKit

public struct AcmeX509Csr {
    
    /// The private key used to generate the CSR, in DER format
    private(set) public var privateKey: Data
    
    /// The private key used to generate the CSR, in PEM format with headers
    private(set) public var privateKeyPem: String
    
    private var asn1Csr: Asn1CertificateSigningRequest
 
    public static func rsa(key: _CryptoExtras._RSA.Signing.PrivateKey = try! .init(keySize: .bits2048), subject: X509Subject? = nil, domains: [String]) throws -> AcmeX509Csr {
        guard domains.count > 0 else {
            throw X509Error.noDomains("At least 1 DNS name is required")
        }
        let rsa = try RsaCSR.init(key: key, subject: subject, domains: domains)
        let csr = self.init(privateKey: rsa.key.derRepresentation, privateKeyPem: rsa.key.pemEncoded(), asn1Csr: rsa.asn1Csr)
        
        return csr
    }
    
    public static func rsa(keyPem: String, subject: X509Subject? = nil, domains: [String]) throws -> AcmeX509Csr {
        let key = try _CryptoExtras._RSA.Signing.PrivateKey.init(pemRepresentation: keyPem)
        return try rsa(key: key, subject: subject, domains: domains)
    }
    
    /// A CSR using a P256 private key
    public static func ecdsa(key: Crypto.P256.Signing.PrivateKey = .init(), subject: X509Subject? = nil, domains: [String]) throws -> AcmeX509Csr {
        guard domains.count > 0 else {
            throw X509Error.noDomains("At least 1 DNS name is required")
        }
        let ecdsa = try EcdsaCSR.init(key: key, subject: subject, domains: domains)
        return self.init(privateKey: ecdsa.key.derRepresentation, privateKeyPem: ecdsa.key.pemEncoded(), asn1Csr: ecdsa.asn1Csr)
    }
    
    /// A CSR using a P256 private key
    public static func ecdsa(keyPem: String, subject: X509Subject? = nil, domains: [String]) throws -> AcmeX509Csr {
        let key = try Crypto.P256.Signing.PrivateKey.init(pemRepresentation: keyPem)
        return try ecdsa(key: key, subject: subject, domains: domains)
    }
    
    /// Returns the CSR as DER Data
    public func derEncoded() throws -> Data {
        let encoder = ASN1Encoder(schema: Asn1CertificateSigningRequest.schema)
        return try encoder.encode(self.asn1Csr)
    }
    
    /// Returns the CSR as a PEM encoded string with headers.
    public func pemEncoded() throws -> String {
        let data = try self.derEncoded().base64EncodedString(options: .lineLength64Characters)
        return """
        -----BEGIN CERTIFICATE REQUEST-----
        \(data)
        -----END CERTIFICATE REQUEST-----
        """
    }
}


/// A CSR using an ECDSA key
struct EcdsaCSR {
    var key: Crypto.P256.Signing.PrivateKey
    var subject: X509Subject
    var domains: [String]
    var asn1Csr: Asn1CertificateSigningRequest
    
    init(key: Crypto.P256.Signing.PrivateKey = .init(), subject: X509Subject? = nil, domains: [String]) throws {
        
        self.domains = domains
        self.subject = subject ?? .init(commonName: domains.first!)
        self.key = key
        
        let crInfo = Asn1CertificateRequestInfo(
            subject: .init(subject: subject ?? .init(commonName: domains.first!)),
            subjectPKInfo: .init(
                algorithm: Asn1AlgorithmIdentifier(
                    algorithm: X509PublicKeyAlgorithmOID.idEcPublicKey.value,
                    parameters: ECCurve.prime256v1.value
                ),
                publicKey: self.key.publicKey.x963Representation
            ),
            extensions: [.init(value: .init([.init(value: .init(dnsNames: domains))]))]
        )
        let crInfoEncoder = ASN1Encoder(schema: Asn1CertificateRequestInfo.schema)
        let crInfoEncoded = try crInfoEncoder.encode(crInfo)
        
        let digest = Crypto.SHA256.hash(data: crInfoEncoded)
        let signature = try self.key.signature(for: digest)
                
        self.asn1Csr = .init(
            certificationRequestInfo: crInfo,
            signatureAlgorithm: .init(algorithm: OID(X509SignatureAlgorithmOID.ecdsaWithSHA256.value)),
            signature: signature.derRepresentation
        )
    }
}

/// A CSR using an RSA key
struct RsaCSR {
    var key: _CryptoExtras._RSA.Signing.PrivateKey
    public var subject: X509Subject
    var domains: [String]
    var asn1Csr: Asn1CertificateSigningRequest

    init(key: _CryptoExtras._RSA.Signing.PrivateKey = try! .init(keySize: .bits2048), subject: X509Subject? = nil, domains: [String]) throws {
        self.domains = domains
        self.subject = subject ?? .init(commonName: domains.first!)
        self.key = key

        let crInfo = Asn1CertificateRequestInfo(
            subject: .init(subject: subject ?? .init(commonName: domains.first!)),
            subjectPKInfo: .init(
                algorithm: .rsaEncryption,
                publicKey: self.key.publicKey.derRepresentation
            ),
            extensions: [.init(value: .init([.init(value: .init(dnsNames: domains))]))]
        )
        let crInfoEncoder = ASN1Encoder(schema: Asn1CertificateRequestInfo.schema)
        let crInfoEncoded = try crInfoEncoder.encode(crInfo)
        let digest = Crypto.SHA256.hash(data: crInfoEncoded)
        let signature = try self.key.signature(for: digest, padding: .insecurePKCS1v1_5)
        
        self.asn1Csr = .init(
            certificationRequestInfo: crInfo,
            signatureAlgorithm: .init(algorithm: OID(X509SignatureAlgorithmOID.sha256WithRSAEncryption.value)),
            signature: signature.rawRepresentation
        )
    }
}
