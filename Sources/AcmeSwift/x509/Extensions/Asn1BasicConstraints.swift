import Foundation
import PotentASN1

struct Asn1BasicConstraints: X509ExtensionProtocol {
    private(set) var oid: OID = CsrExtensionsOID.basicConstraints.value
    var critical: Bool = true
    var data: Data
    
    init(isCa: Bool = false, pathLen: UInt? = nil) {
        let constraints = Constraints(isCa: isCa, pathLen: pathLen)
        let asn1Encoder = ASN1Encoder(schema: Constraints.schema)
        self.data = try! asn1Encoder.encode(constraints)
    }
    
    struct Constraints: HasSchemaProtocol {
        var isCa: Bool = false
        var pathLen: UInt? = nil
        
        static var schema: Schema {
            .sequence([
                "isCa": .boolean(),
                "pathLen": .optional(.integer())
            ])
        }
    }
}
