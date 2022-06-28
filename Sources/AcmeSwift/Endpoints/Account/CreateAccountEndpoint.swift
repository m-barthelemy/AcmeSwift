import Foundation
import NIOHTTP1

struct CreateAccountEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeAccountInfo
    typealias Body = AcmeAccountSpec
    let url: URL
    var method: HTTPMethod = .POST
        
    init(directory: AcmeDirectory,spec: AcmeAccountSpec) {
        self.body = spec
        self.url = directory.newAccount
    }
}
