import Foundation
import NIOHTTP1

struct RevokeCertificateEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = NoBody
    typealias Body = CertificateRevokeSpec
    let url: URL
    
    init(directory: AcmeDirectory,spec: CertificateRevokeSpec) {
        self.body = spec
        self.url = directory.revokeCert
    }
}


