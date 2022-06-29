import Foundation
import NIOHTTP1

struct DeactivateAccountEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeAccountInfo
    typealias Body = DeactivateAccountRequest
    let url: URL
    
    init(accountURL: URL) {
        self.body = DeactivateAccountRequest()
        self.url = accountURL
    }
    
    struct DeactivateAccountRequest: Codable {
        var status: AcmeAccountInfo.Status = .deactivated
    }
}
