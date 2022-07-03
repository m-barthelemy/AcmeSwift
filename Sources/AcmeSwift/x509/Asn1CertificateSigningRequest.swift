import Foundation
import PotentASN1

struct Asn1CertificateSigningRequest: HasSchemaProtocol {
    var certificationRequestInfo: Asn1CertificateRequestInfo
    var signatureAlgorithm: Asn1AlgorithmIdentifier
    var signature: Data
    
    static var schema: Schema {
        .sequence([
            "certificationRequestInfo": Asn1CertificateRequestInfo.schema,
            "signatureAlgorithm": Asn1AlgorithmIdentifier.schema,
            "signature": .bitString(),
        ])
    }
}


