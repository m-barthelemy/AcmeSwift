import Foundation

/// The Directory endpoint of the ACMEv2 service, providing discovery information about various endpoints
public struct AcmeDirectory: Codable, Sendable {
    public let newAuthz: URL?
    public let newNonce: URL
    
    /// The endpoint to call in order to create a new `Account`.
    public let newAccount: URL
    public let newOrder: URL
    public let revokeCert: URL
    public let keyChange: URL
    public let meta: Meta?
    
    public struct Meta: Codable, Sendable {
        public let termsOfService: URL?
        
        /// The web page of the ACME provider.
        public let website: URL?
        
        /// The Certificate Authorities that can issue certificates via the ACMEv2 provider.
        /// This can be used to configure your domains CAA records.
        public let caaIdentities: [String]?
        
        public let externalAccountRequired: Bool?
    }
}
