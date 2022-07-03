import Foundation
import PotentASN1

public struct Asn1Extension: HasSchemaProtocol {
    public var oid: OID
    //public var critical: Bool
    public var value: Data
    
    static var schema: Schema {
        .sequence([
            "oid": .objectIdentifier(),
            //"value": .setOf(.dynamic(unknownTypeSchema: unknownTypeSchema, ioSet)),
        ])
    }
    
    
}
