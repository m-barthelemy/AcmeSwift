import Foundation

extension AcmeSwift {
    
    /// APIs related to ACMEv2 account management.
    public var account: AccountAPI {
        .init(client: self)
    }
    
    public struct AccountAPI {
        fileprivate var client: AcmeSwift
    }
        
}
