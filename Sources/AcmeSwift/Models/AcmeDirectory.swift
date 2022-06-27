import Foundation

/// The Directory endpoint of the ACMEv2 service, providing discovery information about various endpoints
public struct AcmeDirectory: Codable {
    public let newAuthz: URL?
    public let newNonce: URL
    public let newAccount: URL
    public let newOrder: URL
    public let revokeCert: URL
    public let keyChange: URL
    public let meta: Meta
    
    public struct Meta: Codable {
        public let termsOfService: URL?
        public let website: URL?
        public let caaIdentities: [String]?
        public let externalAccountRequired: Bool?
    }
}
