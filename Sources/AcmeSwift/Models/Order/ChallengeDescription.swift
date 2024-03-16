import Foundation

public struct ChallengeDescription: Codable, Sendable {
    /// The type of challgen.
    /// For a wildcard certificate, there will **always** be a at least one DNS challenge, even if your proferred method is HTTP.
    public let type: AcmeAuthorization.Challenge.ChallengeType
    
    /// For a DNS challenge, the full DNS record name.
    /// For an HTTP challenge, the full URL where the challenge must be published. **Must** be simple HTTP over port 80.
    public let endpoint: String
    
    /// For a DNS challenge, the **TXT** record value.
    /// For an HTTP challenge, the exact value that the `endpoint` must return over HTTP on port 80.
    public let value: String
    
    /// The ACMEv2 server URL for validating this challenge.
    internal let url: URL
}
