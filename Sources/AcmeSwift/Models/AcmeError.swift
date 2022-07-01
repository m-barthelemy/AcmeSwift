import Foundation

public enum AcmeError: Error {
    // This Account information has no private key
    case invalidAccountInfo
    
    /// You need to call `account.use()` before performing this operation
    case mustBeAuthenticated(String)
    
    /// Deactivating the account failed, account still active
    case deactivateFailed
    
    /// The Order is not in a state that allows downloading the certificate.
    /// It can be invalid, or some challenges have not yet been completed
    case certificateNotReady(AcmeOrderInfo.OrderStatus, String)
    
    /// No nonce (anti-replay) value was returned by the endpoint
    case noNonceReturned
    
    case jwsEncodeError(String)
    
    case invalidKeyError(String)
    
    case dataCorrupted(String)
    case errorCode(UInt, String?)
    
    /// A resource should have a URL, returned in a response "Location" header, but couldn't find or parse the header.
    case noResourceUrl
}

public struct AcmeResponseError: Codable, Error {
    public let type: AcmeErrorType
    
    public let title: String?
    
    public let detail: String
    
    public let instance: String?
    
    public let identifier: ErrorIdentifier?
    
    public let subproblems: [AcmeResponseError]?
    
    public enum AcmeErrorType: String, Codable, Error {
        /// The request message was malformed
        case malformed = "urn:ietf:params:acme:error:malformed"
        
        /// The server will not issue certificates for the identifier
        case rejectedIdentifier = "urn:ietf:params:acme:error:rejectedIdentifier"
        
        /// The request specified an account that does not exist
        case accountDoesNotExist = "urn:ietf:params:acme:error:accountDoesNotExist"
        
        /// The request specified a certificate to be revoked that has already been revoked
        case alreadyRevoked = "urn:ietf:params:acme:error:alreadyRevoked"
        
        /// The CSR is unacceptable (e.g., due to a short key)
        case badCSR = "urn:ietf:params:acme:error:badCSR"
        
        /// The client sent an unacceptable anti-replay nonce
        case badNonce = "urn:ietf:params:acme:error:badNonce"
        
        /// The JWS was signed by a public key the server does not support
        case badPublicKey = "urn:ietf:params:acme:error:badPublicKey"
        
        /// The revocation reason provided is not allowed by the server
        case badRevocationReason = "urn:ietf:params:acme:error:badRevocationReason"
        
        /// The JWS was signed with an algorithm the server does not support
        case badSignatureAlgorithm = "urn:ietf:params:acme:error:badSignatureAlgorithm"
        
        /// Certification Authority Authorization (CAA) records forbid the CA from issuing a certificate
        case caa = "urn:ietf:params:acme:error:caa"
        
        /// Specific error conditions are indicated in the `subproblems` array
        case compound = "urn:ietf:params:acme:error:compound"
        
        /// The server could not connect to the validation target
        case connection = "urn:ietf:params:acme:error:connection"
        
        /// There was a problem with a DNS query during identifier validation
        case dns = "urn:ietf:params:acme:error:dns"
        
        /// The request must include a value for the "externalAccountBinding" field
        case externalAccountRequired = "urn:ietf:params:acme:error:externalAccountRequired"
        
        /// Response received didn't match the challenge's requirements
        case incorrectResponse = "urn:ietf:params:acme:error:incorrectResponse"
        
        /// A contact URL for an account was invalid
        case invalidContact = "urn:ietf:params:acme:error:invalidContact"
        
        /// A contact URL for an account was invalid.
        /// Specific to Let's Encrypt (Boulder)
        case invalidEmail = "urn:ietf:params:acme:error:invalidEmail"
        
        /// A contact URL for an account used an unsupported protocol scheme
        case unsupportedContact = "urn:ietf:params:acme:error:unsupportedContact"
        
        /// The request attempted to finalize an order that is not ready to be finalized
        case orderNotReady = "urn:ietf:params:acme:error:orderNotReady"
        
        /// The request exceeds a rate limit
        case rateLimited = "urn:ietf:params:acme:error:rateLimited"
        
        /// The server experienced an internal error
        case serverInternal = "urn:ietf:params:acme:error:serverInternal"
        
        /// The server received a TLS error during validation
        case tls = "urn:ietf:params:acme:error:tls"
        
        /// The client lacks sufficient authorization
        case unauthorized = "urn:ietf:params:acme:error:unauthorized"
        
        /// An identifier is of an unsupported type
        case unsupportedIdentifier = "urn:ietf:params:acme:error:unsupportedIdentifier"
        
        /// Visit the "instance" URL and take actions specified there
        case userActionRequired = "urn:ietf:params:acme:error:userActionRequired"
    }
    
    public struct ErrorIdentifier: Codable {
        public let type: String
        public let value: String
    }
}
