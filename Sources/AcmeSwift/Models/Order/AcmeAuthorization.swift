import Foundation

public struct AcmeAuthorization: Codable, Sendable {
    public let status: AuthorizationStatus
    
    /// The timestamp after which the server will consider this authorization invalid
    public let expires: Date?
    
    public let identifier: AcmeOrderSpec.Identifier
    
    public let challenges: [Challenge]
    
    /// Present and `true` if the current authorization is for a domain for which a wildcard certificate was requested.
    public let wildcard: Bool?
    
    public enum AuthorizationStatus: String, Codable, Sendable {
        /// Initial status when the authorization is created.
        case pending
        
        /// A challenge listed in the authorization was validated successfully.
        case valid
        
        case invalid
        
        /// Deactivated by the client.
        case deactivated
        
        case expired
        
        /// Revoked by the ACMEv2 server.
        case revoked
    }
    
    public struct Challenge: Codable, Sendable {
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

        public enum ChallengeType: String, Codable, Sendable {
            //// A HTTP challenge that requires publishing the contents of a challenge at a specific URL to prove ownership of the domain record.
            case http = "http-01"

            /// A DNS challenge requiring the creation of TXT records to prove ownership of a domain or record.
            case dns = "dns-01"

            /// A TLS-ALPN-01 challenge.
            case alpn = "tls-alpn-01"

            /// A device attestation challenge, see  https://datatracker.ietf.org/doc/draft-acme-device-attest/
            case deviceAttest = "device-attest-01"
        }
        
        public enum ChallengeStatus: String, Codable, Sendable {
            case pending
            case processing
            case valid
            case invalid
        }
    }
}
