import Foundation
import PotentASN1

struct Asn1SubjectPublicKeyInfo: HasSchemaProtocol {
    
    var algorithm: Asn1AlgorithmIdentifier
    
    /// The Subject public key
    var publicKey: Data
    
    init(algorithm: X509PublicKeyAlgorithmOID, publicKey: Data) {
        self.algorithm = Asn1AlgorithmIdentifier(algorithm: algorithm.value)
        self.publicKey = publicKey
    }
    
    init(algorithm: Asn1AlgorithmIdentifier, publicKey: Data) {
        self.algorithm = algorithm
        self.publicKey = publicKey
    }
    
    static var schema: Schema {
        .sequence([
            //"algorithm": .sequenceOf(.objectIdentifier(), .none),
            "algorithm": Asn1AlgorithmIdentifier.schema,
            "publicKey": .bitString(),
        ])
    }
}

struct Asn1AlgorithmIdentifier: HasSchemaProtocol {
    var algorithm: OID
    var parameters: OID? = nil
    
    static var schema: Schema {
        .sequence([
            "algorithm": .objectIdentifier(),
            "parameters": .objectIdentifier()
        ])
    }
    
}
