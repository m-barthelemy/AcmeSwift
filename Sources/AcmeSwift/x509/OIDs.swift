import Foundation
import PotentASN1

public enum X509SignatureAlgorithmOID {
    case sha256WithRSAEncryption
    case ecdsaWithSHA256
    case ecdsaWithSHA512

    var value: [UInt64] {
        switch self {
            case .sha256WithRSAEncryption:  return [1,2,840,113549,1,1,11]
            case .ecdsaWithSHA256:          return [1,2,840,10045,4,3,2]
            case .ecdsaWithSHA512:          return [1,2,840,10045,4,3,4]
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
            case .rsaEncryption:            return [1,2,840,113549,1,1,1]
            case .sha256WithRSAEncryption:  return [1,2,840,113549,1,1,11]
            case .sha512WithRSAEncryption:  return [1,2,840,113549,1,1,13]
            case .idEcDH:                   return [1,3,132,1,12]
            case .idEcPublicKey:            return [1,2,840,10045,2,1]
        }
    }
}

enum ECCurve {
    case prime256v1
    
    var value: OID {
        switch self {
            case .prime256v1: return [1,2,840,10045,3,1,7]
        }
    }
}

enum CsrExtension {
    case extensionRequest
    
    var value: OID {
        switch self {
            case .extensionRequest: return [1,2,840,113549,1,9,14]
        }
    }
}

enum CsrExtensionsOID {
    case basicConstraints
    case keyUsage
    case extendedKeyUsage
    case subjectAltName
    
    var value: OID {
        switch self {
            case .basicConstraints: return [2,5,29,19]
            case .keyUsage:         return [2,5,29,15]
            case .extendedKeyUsage: return [2,5,29,37]
            case .subjectAltName:   return [2,5,29,17]
        }
    }
}

enum KeyUsageOID {
    case digitalSignature
    case nonRepudiation
    case keyEncipherment
    case dataEncipherment
    case keyAgreement
    case keyCertSign
    case cRLSign
    case encipherOnly
    case decipherOnly
    
    var value: OID {
        switch self {
            case .digitalSignature: return [2,5,29,15,0]
            case .nonRepudiation:   return [2,5,29,15,1]
            case .keyEncipherment:  return [2,5,29,15,2]
            case .dataEncipherment: return [2,5,29,15,3]
            case .keyAgreement:     return [2,5,29,15,4]
            case .keyCertSign:      return [2,5,29,15,5]
            case .cRLSign:          return [2,5,29,15,6]
            case .encipherOnly:     return [2,5,29,15,7]
            case .decipherOnly:     return [2,5,29,15,8]
        }
    }
}

public enum X509ExtendedKeyUsageOID: Codable {
    /// The most common type. A certificate for a server (web...)
    case serverAuth
    /// A certificate for client authentication (mutual TLS)
    case clientAuth
    
    case codesigning
    
    case ocspSigning
    
    var value: OID {
        switch self {
            case .serverAuth:   return [1,3,6,1,5,5,7,3,1]
            case .clientAuth:   return [1,3,6,1,5,5,7,3,2]
            case .codesigning:  return [1,3,6,1,5,5,7,3,3]
            case .ocspSigning:  return [1,3,6,1,5,5,7,3,9]
        }
    }
}

enum GeneralNameOID {
    /// Email address
    case rfc822Name
    
    /// DNS name
    case dNSName
    
    // URI
    case uniformResourceIdentifier
    
    var value: OID {
        switch self {
            case .rfc822Name:                   return [2,5,29,17,1]
            case .dNSName:                      return [2,5,29,17,2]
            case .uniformResourceIdentifier:    return [2,5,29,17,6]
        }
    }
}
