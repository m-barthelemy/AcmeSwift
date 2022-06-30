import Foundation

public struct AcmeAuthorization: Codable {
    public let status: AuthorizationStatus
    
    /// The timestamp after which the server will consider this authorization invalid
    public let expires: Date?
    
    public let identifier: AcmeOrderSpec.Identifier
    public let challenges: [Challenge]
    
    /// Present and `true` if the current authorization is for a domain for which a wildcard certificate was requested.
    public let wildcard: Bool?
    
    public enum AuthorizationStatus: String, Codable {
        case pending
        case valid
        case invalid
        case deactivated
        case expired
        case revoked
    }
    
    public struct Challenge: Codable {
        /// The URL to which a response can be posted
        public let url: URL
        
        /// The type of challenge
        public let `type`: ChallengeType
        
        /// The status of this challenge
        public let status: ChallengeStatus
        
        
        public let token: String
        
        /// The time at which the server validated this challenge.
        public let validated: Date?
        
        /// Error that occurred while the server was validating the challenge
        public let error: AcmeResponseError?

        public enum ChallengeType: String, Codable {
            //// A HTTP challenge that requires publishing the contents of a challenge at a specific URL to prove ownership of the domain record.
            case http = "http-01"

            /// A DNS challenge requiring the creation of TXT records to prove ownership of a domain or record.
            case dns = "dns-01"

            /// A TLS-ALPN-01 challenge
            case alpn = "tls-alpn-01"
        }
        
        public enum ChallengeStatus: String, Codable {
            case pending
            case processing
            case valid
            case invalid
        }
    }
}
