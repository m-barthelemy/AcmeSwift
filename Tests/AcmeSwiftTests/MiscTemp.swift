import XCTest
import AsyncHTTPClient
import NIO
import Logging
import Crypto
import _CryptoExtras
import SwiftASN1
import X509

@testable import AcmeSwift

final class MiscTempTests: XCTestCase {
    func testHahi() throws {
        let domains = ["www.nuw.run", "nuw.run"]

        let p256 = P256.Signing.PrivateKey()
        let privateKey = Certificate.PrivateKey(p256)
        let commonName = domains[0]
        let name = try DistinguishedName {
            CommonName(commonName)
        }
        let extensions = try Certificate.Extensions {
            SubjectAlternativeNames(domains.map({ GeneralName.dnsName($0) }))
        }
        let extensionRequest = ExtensionRequest(extensions: extensions)
        let attributes = try CertificateSigningRequest.Attributes(
            [.init(extensionRequest)]
        )
        let csr = try CertificateSigningRequest(
            version: .v1,
            subject: name,
            privateKey: privateKey,
            attributes: attributes,
            signatureAlgorithm: .ecdsaWithSHA256
        )

        print("\n ECDSA CSR='\(try! csr.serializeAsPEM().pemString)'")
        print("\n ECDSA private key = '\(try! privateKey.serializeAsPEM().pemString)'")

        let p256RSA = try _CryptoExtras._RSA.Signing.PrivateKey(keySize: .bits2048)
        let privateKeyRSA = Certificate.PrivateKey(p256RSA)
        let csr2 = try CertificateSigningRequest(
            version: .v1,
            subject: name,
            privateKey: privateKeyRSA,
            attributes: attributes,
            signatureAlgorithm: .sha256WithRSAEncryption
        )

        print("\n RSA CSR='\(try! csr2.serializeAsPEM().pemString)'")
        print("\n RSA private key = '\(try! privateKeyRSA.serializeAsPEM().pemString)'")
    }
    
    
}
