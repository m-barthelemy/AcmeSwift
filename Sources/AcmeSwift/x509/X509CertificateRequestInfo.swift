import Foundation
import PotentASN1

struct X509CertificateRequestInfo {
    public var version: CSRVersion = .v1
    public var subject: X509Subject
    public var subjectPKInfo: X509SubjectPublicKeyInfo
    public var attributes: [Asn1Extension]
    
    enum CSRVersion: Int, Codable {
        case v1 = 0
    }
    
    
    
}

struct Asn1CertificateRequestInfo: Codable, HasSchemaProtocol {
    var version: Int
    var subject: Asn1Subject
    //var subjectPKInfo:
    var extensions: [Asn1Extension]
    
    static var schema: Schema {
        // TODO: set proper kind and range for each field, or at least check spec
        .sequence([
            "version": .version(.integer(allowed: 0 ..< 1)),
            "subject": .sequence(Asn1Subject.schema),
            //"subjectPKInfo"
            "extensions": .setOf(Asn1Extension.schema)
        ])
    }
    init(reqInfo: X509CertificateRequestInfo) {
        
    }
}
