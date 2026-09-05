import Foundation
import X509

extension X509.Certificate {
    // https://www.rfc-editor.org/rfc/rfc9773.html#section-4.1
    func getARICertId() throws -> String {
        guard let aki = try self.extensions.authorityKeyIdentifier?.keyIdentifier else {
            throw AcmeError.missingAuthorityKeyIdentifier
        }

        // TODO: support older versions
        guard #available(macOS 26.4, iOS 26.4, watchOS 26.4, tvOS 26.4, visionOS 26.4, *) else {
            fatalError("swift too old")
        }
        let encodedAki = Data(aki)
            .base64EncodedString(options: [.omitPaddingCharacter, .base64URLAlphabet])
        let encodedSerial = Data(self.serialNumber.bytes)
            .base64EncodedString(options: [.omitPaddingCharacter, .base64URLAlphabet])

        let ariCertId = encodedAki + "." + encodedSerial
        return ariCertId
    }
}
