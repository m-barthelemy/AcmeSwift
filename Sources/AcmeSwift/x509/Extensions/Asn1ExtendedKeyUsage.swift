import Foundation
import PotentASN1

struct Asn1ExtendedKeyUsage: X509ExtensionProtocol {
    private(set) var oid: OID = CsrExtensionsOID.extendedKeyUsage.value
    var critical: Bool = true
    var data: Data = Data()
    
    init(usages: [X509ExtendedKeyUsageOID]) {
        var extKeyUsages: [OID] = []
        for usage in usages {
            extKeyUsages.append(usage.value)
        }
        let asn1Encoder = ASN1Encoder(schema: .sequenceOf(.objectIdentifier(), size: .min(1)))
        self.data = try! asn1Encoder.encode(extKeyUsages)
    }
}
