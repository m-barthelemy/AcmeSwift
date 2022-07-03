import Foundation
import PotentASN1

public enum X509SignatureAlgorithmOID {
    case sha256WithRSAEncryption
    case ecdsaWithSHA256
    case ecdsaWithSHA512
    //case idEcPublicKey
    
    var value: [UInt64] {
        switch self {
            case .sha256WithRSAEncryption: return [1,2,840,113549,1,1,11]
            case .ecdsaWithSHA256: return [1,2,840,10045,4,3,2]
            case .ecdsaWithSHA512: return [1,2,840,10045,4,3,4]
            //case .idEcPublicKey: return OID([1.2.840,10045,2.1])
        }
    }
}

enum X509PublicKeyAlgorithmOID {
    case rsaEncryption
    case sha256WithRSAEncryption
    case sha512WithRSAEncryption
    case idEcDH
    case idEcPublicKey
    
    var value: OID {
        switch self {
            case .rsaEncryption: return OID([1,2,840,113549,1,1,1])
            case .sha256WithRSAEncryption: return OID([1,2,840,113549,1,1,11])
            case .sha512WithRSAEncryption: return OID([1,2,840,113549,1,1,13])
            case .idEcDH: return OID([1,3,132,1,12])
            case .idEcPublicKey: return OID([1,2,840,10045,2,1])
        }
    }
}

enum ECCurve {
    case prime256v1
    
    var value: OID {
        switch self {
            case .prime256v1: return OID([1,2,840,10045,3,1,7])
        }
    }
}
struct CsrExtensionsOID {
    static var basicConstraints: OID { [2,5,29,19] }
    
    static var keyUsage: OID { [2,5,29,15] }
    
    static var extendedKeyUsage: OID { [1,3,6,1,5,5,7,3] }
                                        
    static var subjectAltName: OID { [2,5,29,17] }
}

struct KeyUsageOID {
    static var digitalSignature: OID { [2,5,29,15,0] }
    static var nonRepudiation: OID { [2,5,29,15,1] }
    static var keyEncipherment: OID { [2,5,29,15,2] }
    static var dataEncipherment: OID { [2,5,29,15,3] }
    static var keyAgreement: OID { [2,5,29,15,4] }
    static var keyCertSign: OID { [2,5,29,15,5] }
    static var cRLSign: OID { [2,5,29,15,6] }
}

struct ExtendedKeyUsageOID {
    /// The most common type. A certificate for a server (web...)
    static var serverAuth: OID { [1,3,6,1,5,5,7,3,1] }
    
    /// A certificate for client authentication (mutual TLS)
    static var clientAuth: OID { [1,3,6,1,5,5,7,3,2] }
    
    static var codeSigning: OID { [1,3,6,1,5,5,7,3,3] }
    
    static var ocspSigning: OID { [1,3,6,1,5,5,7,3,9] }
}
