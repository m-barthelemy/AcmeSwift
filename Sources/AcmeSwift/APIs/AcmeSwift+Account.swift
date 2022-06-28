import Foundation
import Crypto

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
        public func get() async throws -> AcmeAccountInfo {
            guard let login = self.client.login else {
                throw AcmeUnspecifiedError.mustBeAuthenticated("\(AcmeSwift.self) must be called with a \(AccountLogin.self)")
            }
            let ep = CreateAccountEndpoint(
                directory: self.client.directory,
                spec: .init(
                    contact: login.contacts,
                    termsOfServiceAgreed: true,
                    onlyReturnExisting: true,
                    externalAccountBinding: nil
                )
            )
            
            var info = try await self.client.run(ep, privateKey: login.key)
            info.privateKeyPem = login.key.pemRepresentation
            return info
        }
        
        /// Creates a new account on the ACMEv2 provider.
        /// - Parameters:
        ///   - contacts: Email addresses of the contact points for this account.
        ///   - acceptTOS: Automatically accept the ACMEv2 provider Terms Of Service.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  an `Account` that can be saves for future connections.
        public func create(contacts: [String], acceptTOS: Bool) async throws -> AcmeAccountInfo {
            var contactsWithURL: [String] = []
            for var contact in contacts {
              if contact.firstIndex(of: ":") == nil {
                contact = "mailto:" + contact
              }
              contactsWithURL.append(contact)
            }
            // Create private key
            let privateKey = Crypto.P256.Signing.PrivateKey.init(compactRepresentable: true)
            //print("\n •••••• Private key: \(privateKey.pemRepresentation)")
            
            let ep = CreateAccountEndpoint(
                directory: self.client.directory,
                spec: .init(
                    contact: contactsWithURL,
                    termsOfServiceAgreed: acceptTOS,
                    onlyReturnExisting: false,
                    externalAccountBinding: nil
                )
            )
            
            var info = try await self.client.run(ep, privateKey: privateKey)
            info.privateKeyPem = privateKey.pemRepresentation
            return info
        }
        
    }
        
}
