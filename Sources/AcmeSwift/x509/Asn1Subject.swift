import Foundation
import PotentASN1

struct Asn1Subject: HasSchemaProtocol {
    var values: [X509Item<String>] = []
    
    init(subject: X509Subject) {
        if let c = subject.countryName {
            self.values.append(.init(oid: [2,5,4,6], value: c))
        }
        if let s = subject.stateOrProvinceName {
            self.values.append(.init(oid: [2,5,4,8], value: s))
        }
        if let l = subject.localityName {
            self.values.append(.init(oid: [2,5,4,7], value: l))
        }
        if let o = subject.organizationName {
            self.values.append(.init(oid: [2,5,4,10], value: o))
        }
        if let ou = subject.organizationalUnitName {
            self.values.append(.init(oid: [2,5,4,11], value: ou))
        }
        if let cn = subject.commonName {
            self.values.append(.init(oid: [2,5,4,3], value: cn))
        }
    }
    
    static var schema: Schema {
        .sequence(
            ["values": .setOf(X509Kind.schema())]
        )
        // TODO: set proper kind and range for each field, or at least check spec
        /*.sequence([
         "countryName":              X509Kind.schema(),
         "stateOrProvinceName":      X509Kind.schema(),
         "localityName":             X509Kind.schema(),
         "organizationName":         X509Kind.schema(),
         "organizationalUnitName":   X509Kind.schema(),
         "commonName":               X509Kind.schema(),
         "emailAddress":             X509Kind.schema()
         ])*/
    }
}
