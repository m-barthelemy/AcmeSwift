import Foundation
import PotentASN1


public struct X509SubjectPublicKeyInfo: Codable {
    
    public var algorithm: X509SignatureAlgorithm
    public var publicKey: Data
    
    public init(algorithm: X509SignatureAlgorithm, publicKey: Data) {
        self.algorithm = algorithm
        self.publicKey = publicKey
    }
    
}
