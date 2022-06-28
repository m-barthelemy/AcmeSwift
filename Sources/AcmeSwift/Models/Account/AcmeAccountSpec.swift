import Foundation

/// Configuration for creating or querying an ACMEv2 account.
struct AcmeAccountSpec: Codable {
    var contact: [String] = []
    var termsOfServiceAgreed: Bool = true
    
    /// If this field is present with the value "true", then the server MUST NOT create a new account if one does not already exist.
    /// This allows a client to look up an account URL based on an account key.
    var onlyReturnExisting: Bool = false
    
    var externalAccountBinding: ExternalAccountBinding? = nil
    
    /// This is in fact a JWS
    struct ExternalAccountBinding: Codable {
        
    }
}
