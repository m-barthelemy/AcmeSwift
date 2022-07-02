import Foundation
import PotentASN1

public struct Asn1Extension: HasSchemaProtocol {
    public var oid: ObjectIdentifier
    public var critical: Bool
    public var value: Data
    
    static var schema: Schema {
        .sequence([
            "oid": .objectIdentifier()
        ])
    }
}
