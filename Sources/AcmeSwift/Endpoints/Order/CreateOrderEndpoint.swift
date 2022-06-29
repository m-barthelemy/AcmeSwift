import Foundation
import NIOHTTP1

struct CreateOrderEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeOrderInfo
    typealias Body = AcmeOrderSpec
    let url: URL
    
    init(directory: AcmeDirectory, spec: AcmeOrderSpec) {
        self.body = spec
        self.url = directory.newOrder
    }
}
