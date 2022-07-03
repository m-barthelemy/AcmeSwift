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
        
        let csr = try CSR(domains: ["www.nuw.run"])
        print("\n ECDSA CSR='\(try! csr.pemEncoded())'")
        let csr2 = try rsaCSR(domains: ["www.nuw.run"])
        print("\n RSA CSR='\(try! csr2.pemEncoded())'")
    }
    
    
}
