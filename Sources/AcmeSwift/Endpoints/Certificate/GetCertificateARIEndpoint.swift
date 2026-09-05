import Foundation
import NIOHTTP1

struct GetCertificateARIEndpoint: EndpointProtocol {
    var body: Body? = NoBody()
    var method: HTTPMethod = .GET
    typealias Response = AcmeCertificateRenewalInfo
    typealias Body = NoBody
    let url: URL

    init(url: URL) {
        self.url = url
    }
}
