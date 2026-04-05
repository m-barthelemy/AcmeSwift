import Foundation

public struct AcmeAuthorization: Sendable {
    public let status: AuthorizationStatus
    
    /// The timestamp after which the server will consider this authorization invalid
    public let expires: Date?
    
    public let identifier: AcmeOrderSpec.Identifier
    
    public let challenges: [Challenge]
    
    /// Present and `true` if the current authorization is for a domain for which a wildcard certificate was requested.
    public let wildcard: Bool?
    
    public enum AuthorizationStatus: String, Sendable {
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
    
    public struct Challenge: Sendable {
        /// The URL to which a response can be posted
        public let url: URL
        
        /// The type of challenge
        public let `type`: ChallengeType
        
        /// The status of this challenge
        public let status: ChallengeStatus
        
        /// A random value that uniquely identifies the challenge
        public let token: String?

        /// A URI identifying the ACME account requesting validation.
        /// NOTE: latest RFC draft (https://www.ietf.org/archive/id/draft-ietf-acme-dns-persist-01.html#name-challenge-object)
        /// says this is a required field, but Let's Encrypt does not currently set it.
        internal let accountURI: URL?

        internal let issuerDomainNames: [String]?

        /// The time at which the server validated this challenge.
        public let validated: Date?
        
        /// Error that occurred while the server was validating the challenge
        public let error: AcmeResponseError?

        @nonexhaustive
        public enum ChallengeType: String, Sendable {
            /// A HTTP challenge that requires publishing the contents of a challenge at a specific URL to prove ownership of the domain record.
            case http = "http-01"

            /// A DNS challenge requiring the creation of TXT records to prove ownership of a domain or record.
            case dns = "dns-01"

            /// A DNS challenge whose record name is unique to the ACMEv2 account being used.
            case dnsAccount = "dns-account-01"

            /// A DNS challenge requiring the creation of persistent TXT records to prove ownership of a domain or record.
            case dnsPersist = "dns-persist-01"

            /// A TLS-ALPN-01 challenge.
            case alpn = "tls-alpn-01"

            /// A device attestation challenge, see  https://datatracker.ietf.org/doc/draft-acme-device-attest/
            case deviceAttest = "device-attest-01"
        }
        
        public enum ChallengeStatus: String, Sendable {
            case pending
            case processing
            case valid
            case invalid
        }

        enum CodingKeys: String, CodingKey {
            case url
            case type
            case status
            case token
            case accountURI = "accounturi"
            case issuerDomainNames = "issuer-domain-names"
            case validated
            case error
        }
    }
}

extension AcmeAuthorization: Codable {}
extension AcmeAuthorization.AuthorizationStatus: Codable {}
extension AcmeAuthorization.Challenge: Codable {}
extension AcmeAuthorization.Challenge.ChallengeType: Codable {}
extension AcmeAuthorization.Challenge.ChallengeStatus: Codable {}
