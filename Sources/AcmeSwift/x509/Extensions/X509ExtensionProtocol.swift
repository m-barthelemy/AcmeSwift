import Foundation
import PotentASN1

protocol X509ExtensionProtocol: HasSchemaProtocol {
    var oid: OID {get}
    var critical: Bool {get set}
    var data: Data {get set}
}

extension X509ExtensionProtocol {
    static var schema: Schema {
        .sequence([
            "oid": .objectIdentifier(),
            "critical": .boolean(),
            "data": .octetString()
        ])
    }
}
