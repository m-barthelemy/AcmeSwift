import Foundation

/// Configuration for creating or querying an ACMEv2 account.
public struct AcmeAccountSpec: Codable {
    public var contact: [String] = []
    public var termsOfServiceAgreed: Bool = true
    
    /// If this field is present with the value "true", then the server MUST NOT create a new account if one does not already exist.
    /// This allows a client to look up an account URL based on an account key.
    public var onlyReturnExisting: Bool = false
    
    public var externalAccountBinding: ExternalAccountBinding? = nil
    
    /// This is in fact a JWS
    public struct ExternalAccountBinding: Codable {
        
    }
}
