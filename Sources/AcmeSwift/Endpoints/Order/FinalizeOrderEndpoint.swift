import Foundation
import NIOHTTP1

struct FinalizeOrderEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeOrderInfo
    typealias Body = AcmeFinalizeOrderSpec
    let url: URL
    
    init(orderURL: URL, spec: AcmeFinalizeOrderSpec) {
        self.body = spec
        self.url = orderURL
    }
}
