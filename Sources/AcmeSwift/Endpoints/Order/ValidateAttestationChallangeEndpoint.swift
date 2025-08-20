import Foundation
import NIOHTTP1

struct ValidateAttestationChallengeEndpoint: EndpointProtocol {
    var body: Body?
    
    typealias Response = AcmeAuthorization.Challenge
    typealias Body = AcmeAttestationSpec
    let url: URL
    
    init(challengeURL: URL, spec: AcmeAttestationSpec) {
        self.body = spec
        self.url = challengeURL
    }
}
