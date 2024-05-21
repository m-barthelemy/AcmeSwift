import Foundation

/// Information returned when creating a new Order.
public struct AcmeOrderInfo: Codable, Sendable {
        
    /// The URL of this Order.
    internal(set) public var url: URL?
    
    /// The current status of the Order.
    public let status: OrderStatus
    
    /// Date after which the order must be started from scratch if still not valid.
    public let expires: Date
    
    /// Date when the certificate requested by this Order should start being valid.
    public let notBefore: Date?
    
    /// Desired expiry date of the certificate requested by this Order.
    public let notAfter: Date?
    
    /// DNS names for which we are requesting a certificate.
    public let identifiers: [AcmeOrderSpec.Identifier]
    
    public let authorizations: [URL]
    
    /// URL to call once all the authorizations (challenges) have been completed.
    public let finalize: URL
    
    /// URL to call to obtain the certificate  when the Order has been finalized and has a `valid` status.
    public let certificate: URL?
    
    
    public enum OrderStatus: String, Codable, Sendable {
        /// The certificate will not be issued. Consider this order process abandoned.
        case invalid
        
        /// The server does not believe that the client has fulfilled all the requirements.
        ///
        /// Check the "authorizations" array for entries that are still pending.
        case pending
        
        /// The server agrees that the requirements have been fulfilled, and is awaiting finalization.
        ///
        /// Submit a finalization request.
        case ready
        
        /// The certificate is being issued (`finalize()` has been called).
        ///
        /// Send a POST-as-GET request after the time given in the Retry-After header field of the response, if any.
        case processing
        
        /// The server has issued the certificate and provisioned its URL to the "certificate" field of the order.
        ///
        /// Download the certificate.
        case valid
    }
}
