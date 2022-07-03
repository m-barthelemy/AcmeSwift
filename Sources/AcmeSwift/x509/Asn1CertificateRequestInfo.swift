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
    var extensions: [Extensions]
    
    static var schema: Schema {
        .sequence([
            "version": .version(.integer(allowed: 0 ..< 1)),
            "subject": Asn1Subject.schema,
            "subjectPKInfo": Asn1SubjectPublicKeyInfo.schema,
            "extensions": .implicit(
                0,
                .setOf(Extensions.schema)
            )
        ])
    }
    
    struct Extensions: HasSchemaProtocol {
        private(set) var oid: OID = CsrExtension.extensionRequest.value
        var value: [ExtensionValue]
        //var keyUsage:
        
        static var schema: Schema {
            .sequence([
                "oid": .objectIdentifier(),
                "value": .setOf(
                    ExtensionValue.schema,
                    size: .is(1)
                )
                //"keyUsage":
            ])
        }
        
        struct ExtensionValue: HasSchemaProtocol {
            var value: Asn1SubjectAltName
            
            static var schema: Schema {
                .sequence([
                    "value": Asn1SubjectAltName.schema
                ])
            }
        }
        
    }
}
