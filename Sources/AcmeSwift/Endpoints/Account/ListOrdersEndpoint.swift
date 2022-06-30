import Foundation
import NIOHTTP1

struct ListOrdersEndpoint: EndpointProtocol {
    var body: Body? = NoBody()
    var method: HTTPMethod = .GET
    typealias Response = AccountOrdersUrls
    typealias Body = NoBody
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}
