import Foundation

extension AcmeSwift {
    
    /// APIs related to ACMEv2 account management.
    public var account: AccountAPI {
        .init(client: self)
    }
    
    public struct AccountAPI {
        fileprivate var client: AcmeSwift
        
        /// Gets an existing account on the ACMEv2 provider.
        /// - Parameters:
        ///   - contacts: Email addresses of the contact points for this account.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  the `Account`.
        public func get(contacts: [String]) async throws {
            let ep = CreateAccountEndpoint(
                directory: self.client.directory,
                spec: .init(
                    contact: contacts,
                    termsOfServiceAgreed: true,
                    onlyReturnExisting: true,
                    externalAccountBinding: nil
                )
            )
            try await self.client.run(ep)
        }
        
        /// Creates a new account on the ACMEv2 provider.
        /// - Parameters:
        ///   - contacts: Email addresses of the contact points for this account.
        ///   - acceptTOS: Automatically accept the ACMEv2 provider Terms Of Service.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  an `Account` that can be saves for future connections.
        public func create(contacts: [String], acceptTOS: Bool) async throws {
            var contactsWithURL: [String] = []
            for var contact in contacts {
              if contact.firstIndex(of: ":") == nil {
                contact = "mailto:" + contact
              }
              contactsWithURL.append(contact)
            }
            let ep = CreateAccountEndpoint(
                directory: self.client.directory,
                spec: .init(
                    contact: contactsWithURL,
                    termsOfServiceAgreed: acceptTOS,
                    onlyReturnExisting: false,
                    externalAccountBinding: nil
                )
            )
            try await self.client.run(ep)
        }
        
    }
        
}
