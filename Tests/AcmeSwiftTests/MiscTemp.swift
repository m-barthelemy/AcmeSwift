import XCTest
import AsyncHTTPClient
import NIO
import Logging
import PotentASN1
import Crypto
import _CryptoExtras

@testable import AcmeSwift

final class MiscTempTests: XCTestCase {
    func testHahi() throws {
        let privateKey = Crypto.P256.Signing.PrivateKey.init()
        let rsaPrivate = try _RSA.Signing.PrivateKey.init(keySize: .bits2048)
        //privateKey.publicKey.
        //try rsaPrivate.signature(for: Data()).rawRepresentation
        
        let csr = try AcmeX509Csr.ecdsa(
            domains: ["www.nuw.run", "nuw.run"],
            keyUsage: [.dataEncipherment, .digitalSignature],
            extendedKeyUsage: [.clientAuth, .serverAuth]
        )
        print("\n ECDSA CSR='\(try! csr.pemEncoded())'")
        print("\n ECDSA private key = \(csr.privateKeyPem)")
        let csr2 = try AcmeX509Csr.rsa(domains: ["www.nuw.run", "nuw.run"])
        print("\n RSA CSR='\(try! csr2.pemEncoded())'")
        print("\n RSA private key = \(csr2.privateKeyPem)")
    }
    
    
}
