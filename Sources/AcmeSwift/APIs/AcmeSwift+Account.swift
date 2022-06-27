import Foundation

extension AcmeSwift {
    
    /// APIs related to ACMEv2 account management.
    public var account: AccountAPI {
        .init(client: self)
    }
    
    public struct AccountAPI {
        fileprivate var client: AcmeSwift
        
        /// Creates a new account on the ACMEv2 provider
        public func create() async throws {
            
        }
    }
        
}
