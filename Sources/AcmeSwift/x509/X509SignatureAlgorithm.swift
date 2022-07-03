import Foundation
import PotentASN1

public struct X509SignatureAlgorithm: HasSchemaProtocol {
    var oid: OID
    
    public init(_ kind: X509SignatureAlgorithmOID) {
        self.oid = .init(kind.value)
    }
    
    static var schema: Schema {
        .sequence(["oid": .objectIdentifier()])
    }
    
}
