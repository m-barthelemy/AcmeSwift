import Foundation
import NIOHTTP1

struct GetOrderEndpoint: EndpointProtocol {
    var body: Body? = ""
    
    typealias Response = AcmeOrderInfo
    typealias Body = String
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}
