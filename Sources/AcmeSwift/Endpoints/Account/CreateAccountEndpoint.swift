import Foundation
import NIOHTTP1

struct CreateAccountEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeAccountInfo
    typealias Body = AcmeAccountSpec
    let url: URL
        
    init(directory: AcmeDirectory, spec: AcmeAccountSpec) {
        self.body = spec
        self.url = directory.newAccount
    }
}
