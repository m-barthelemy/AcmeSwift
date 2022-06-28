import Foundation
import NIOHTTP1

struct CreateAccountEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeAccountInfo
    typealias Body = AcmeAccountSpec
    var method: HTTPMethod = .POST
        
    init(directory: AcmeDirectory,spec: AcmeAccountSpec) {
        self.body = spec
        self.url = directory.newAccount
    }
    
    let url: URL
}
