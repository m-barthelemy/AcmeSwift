import Foundation
import PotentASN1

struct Asn1SubjectAltName: HasSchemaProtocol {
    private(set) var oid: OID = CsrExtensionsOID.subjectAltName.value
    var critical: Bool = true
    var domains: Data
    
    init(dnsNames: [String]) {
        var generalNames: GeneralNames = []
        for name in dnsNames {
            generalNames.append(X509GeneralName.dnsName(name))
        }
        // The actual value of an extension must be passed as an ASN.1 Octet String
        let asn1Encoder = ASN1Encoder(schema: GeneralNames.schema)
        self.domains = try! asn1Encoder.encode(generalNames)
    }
    
    static var schema: Schema {
        .sequence([
            "oid": .objectIdentifier(),
            "critical": .boolean(),
            "domains": .octetString()
        ])
    }
}
