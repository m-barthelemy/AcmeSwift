import Foundation
import PotentASN1

/*struct X509CertificateRequestInfo {
    public var version: CSRVersion = .v1
    public var subject: X509Subject
    public var subjectPKInfo: Asn1SubjectPublicKeyInfo
    public var attributes: [Asn1Extension]
    
    enum CSRVersion: Int, Codable {
        case v1 = 0
    }
}*/

struct Asn1CertificateRequestInfo: HasSchemaProtocol {
    var version: Int = 0
    var subject: Asn1Subject
    var subjectPKInfo: Asn1SubjectPublicKeyInfo
    //var extensions: [Asn1Extension]
    
    static var schema: Schema {
        .sequence([
            "version": .version(.integer(allowed: 0 ..< 1)),
            "subject": Asn1Subject.schema,
            "subjectPKInfo": Asn1SubjectPublicKeyInfo.schema,
            //"extensions": .setOf(Asn1Extension.schema)
        ])
    }
}
