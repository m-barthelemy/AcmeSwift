import Foundation
import NIOHTTP1

struct GetAuthorizationEndpoint: EndpointProtocol {
    var body: Body? = ""
    
    typealias Response = AcmeAuthorization
    typealias Body = String
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}
