import Foundation

/// Information returned when creating a new Order
public struct AcmeOrderInfo: Codable {
    
    public let status: OrderStatus
    
    public let expires: Date
    
    public let notBefore: Date?
    
    public let notAfter: Date?
    
    public let identifiers: [AcmeOrderSpec.Identifier]
    
    public let authorizations: [URL]
    
    /// URL to call once all the authorizations (challenges) have been completed.
    public let finalize: URL
    
    public enum OrderStatus: String, Codable {
        /// The certificate will not be issued.  Consider thisorder process abandoned.
        case invalid
        
        /// The server does not believe that the client has fulfilled all the requirements.
        ///  Check the "authorizations" array for entries that are still pending.
        case pending
        
        /// The server agrees that the requirements have been fulfilled, and is awaiting finalization.
        /// Submit a finalization request.
        case ready
        
        /// The certificate is being issued.
        /// Send a POST-as-GET request after the time given in the Retry-After header field of the response, if any.
        case processing
        
        /// The server has issued the certificate and provisioned its URL to the "certificate" field of the order.
        /// Download the certificate.
        case valid
    }
}
