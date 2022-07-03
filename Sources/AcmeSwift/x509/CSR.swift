import Foundation
import Crypto
import _CryptoExtras
import PotentASN1
import CryptoKit

/// A CSR using an ECDSA key
public struct CSR {
    internal(set) public var key: Crypto.P256.Signing.PrivateKey
    internal(set) public var subject: X509Subject
    internal(set) public var domains: [String]
    var asn1Csr: Asn1CertificateSigningRequest
    
    public init(key: Crypto.P256.Signing.PrivateKey = .init(), subject: X509Subject? = nil, domains: [String]) throws {
        guard domains.count > 0 else {
            throw X509Error.noDomains("At least 1 DNS name is required")
        }
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
            )
            //extensions: []
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
    
    public init(keyPem: String, subject: X509Subject? = nil, domains: [String]) throws {
        let key = try Crypto.P256.Signing.PrivateKey.init(pemRepresentation: keyPem)
        try self.init(key: key, subject: subject, domains: domains)
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
    
    /// Returns the CSR as DER Data
    public func derEncoded() throws -> Data {
        let encoder = ASN1Encoder(schema: Asn1CertificateSigningRequest.schema)
        return try encoder.encode(self.asn1Csr)
    }
}

/// A CSR using an RSA key
public struct rsaCSR {
    internal(set) public var key: _CryptoExtras._RSA.Signing.PrivateKey
    internal(set) public var subject: X509Subject
    internal(set) public var domains: [String]
    var asn1Csr: Asn1CertificateSigningRequest

    public init(key: _CryptoExtras._RSA.Signing.PrivateKey = try! .init(keySize: .bits2048), subject: X509Subject? = nil, domains: [String]) throws {
        guard domains.count > 0 else {
            throw X509Error.noDomains("At least 1 DNS name is required")
        }
        self.domains = domains
        self.subject = subject ?? .init(commonName: domains.first!)
        self.key = key
        
        
        let crInfo = Asn1CertificateRequestInfo(
            subject: .init(subject: subject ?? .init(commonName: domains.first!)),
            subjectPKInfo: .init(
                algorithm: .rsaEncryption,
                publicKey: self.key.publicKey.derRepresentation
            )
            //extensions: []
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
    
    public init(keyPem: String, subject: X509Subject? = nil, domains: [String]) throws {
        let key = try _CryptoExtras._RSA.Signing.PrivateKey.init(pemRepresentation: keyPem)
        try self.init(key: key, subject: subject, domains: domains)
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
    
    /// Returns the CSR as DER Data
    public func derEncoded() throws -> Data {
        let encoder = ASN1Encoder(schema: Asn1CertificateSigningRequest.schema)
        return try encoder.encode(self.asn1Csr)
    }
}

public enum CsrType {
    /// ECDSA certificate (recommended)
    case ecdsa
    
    /// Classical RSA certificate
    case rsa
}
