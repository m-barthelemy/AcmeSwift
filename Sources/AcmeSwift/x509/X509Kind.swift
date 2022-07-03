import Foundation
import PotentASN1

struct X509Kind {
    static func schema(_ valueKind: Schema = .string(kind: .ia5, size: .range(1, 64))) -> Schema {
        .sequence([
            "oid": .objectIdentifier(),
            "value": valueKind
        ])
    }
}

struct X509Item<T: Codable>: Codable {
    var oid: OID
    var value: T?
}
