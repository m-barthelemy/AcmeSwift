import Foundation
import NIOHTTP1

struct DownloadCertificateEndpoint: EndpointProtocol {
    var body: Body? = ""
    
    typealias Response = String
    typealias Body = String
    let url: URL
    
    init(certURL: URL) {
        self.url = certURL
    }
}

