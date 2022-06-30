import Foundation
import NIOHTTP1

struct ValidateChallengeEndpoint: EndpointProtocol {
    var body: Body? = NoBody()
    
    typealias Response = AcmeAuthorization.Challenge
    typealias Body = NoBody
    let url: URL
    
    init(challengeURL: URL) {
        self.url = challengeURL
    }
}
