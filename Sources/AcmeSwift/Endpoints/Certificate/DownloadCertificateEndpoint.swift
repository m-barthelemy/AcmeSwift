import Foundation
import NIOHTTP1

struct DownloadCertificateEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = String
    typealias Body = NoBody
    let url: URL
    var method: HTTPMethod = .POST
    
    init(certURL: URL) {
        self.body = NoBody()
        self.url = certURL
    }
}
