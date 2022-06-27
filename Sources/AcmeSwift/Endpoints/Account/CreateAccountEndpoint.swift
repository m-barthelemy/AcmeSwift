import Foundation
import NIOHTTP1

struct CreateAccountEndpoint:  EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeAccount
    typealias Body = AcmeAccountSpec
    var method: HTTPMethod = .POST
        
    init(spec: AcmeAccountSpec) {
        self.body = spec
    }
    
    var path: String {
        "acme/new-account"
    }
}
