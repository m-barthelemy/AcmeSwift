import Foundation
import PotentASN1

struct Asn1KeyUsage: X509ExtensionProtocol {
    private(set) var oid: OID = CsrExtensionsOID.keyUsage.value
    var critical: Bool = true
    var data: Data
    
    init(_ value: X509KeyUsage) {
        let asn1Encoder = ASN1Encoder(schema: .bitString())
        self.data = try! asn1Encoder.encode(value.rawValue)
    }
}
