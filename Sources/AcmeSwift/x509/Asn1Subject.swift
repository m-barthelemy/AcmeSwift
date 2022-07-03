import Foundation
import PotentASN1

struct Asn1Subject: HasSchemaProtocol {
    /*var countryName: X509Item<String>?
     var stateOrProvinceName: X509Item<String>?
     var localityName: X509Item<String>?
     var organizationName: X509Item<String>?
     var organizationalUnitName: X509Item<String>?
     var commonName: X509Item<String>?
     var emailAddress: X509Item<String>?*/
    var values: [X509Item<String>] = []
    
    /*init(subject: X509Subject) {
     self.countryName =              .init(oid: [2,5,4,6], value: subject.countryName)
     self.stateOrProvinceName =      .init(oid: [2,5,4,8], value: subject.stateOrProvinceName)
     self.localityName =             .init(oid: [2,5,4,7], value: subject.localityName)
     self.organizationName =         .init(oid: [2,5,4,10], value: subject.organizationName)
     self.organizationalUnitName =   .init(oid: [2,5,4,11], value: subject.organizationalUnitName)
     self.commonName =               .init(oid: [2,5,4,3], value: subject.commonName)
     self.emailAddress =             .init(oid: [1,2,840,113549,1,9,1], value: subject.emailAddress)
     }*/
    
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
