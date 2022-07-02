import Foundation
import PotentASN1

public struct X509SignatureAlgorithm : Codable {
    public static var sha256WithRSAEncryption: OID {
        return [1,2,840,113549,1,1,11]
    }
    
    public static var ecdsaWithSHA256: OID {
        return [1,2,840,10045,4,3,2]
    }
    
    public static var ecdsaWithSHA512: OID {
        return [1,2,840,10045,4,3,4]
    }
}
