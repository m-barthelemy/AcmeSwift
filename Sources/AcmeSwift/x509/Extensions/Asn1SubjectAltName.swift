import Foundation
import PotentASN1

struct Asn1SubjectAltName: X509ExtensionProtocol {
    private(set) var oid: OID = CsrExtensionsOID.subjectAltName.value
    var critical: Bool = true
    var data: Data
    
    init(dnsNames: [String]) {
        var generalNames: GeneralNames = []
        for name in dnsNames {
            generalNames.append(X509GeneralName.dnsName(name))
        }
        // The actual value of an extension must be passed as an ASN.1 Octet String
        let asn1Encoder = ASN1Encoder(schema: GeneralNames.schema)
        self.data = try! asn1Encoder.encode(generalNames)
    }
}
