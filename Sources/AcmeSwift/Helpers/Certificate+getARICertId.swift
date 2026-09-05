import Foundation
import X509

extension X509.Certificate {
    // https://www.rfc-editor.org/rfc/rfc9773.html#section-4.1
    func getARICertId() throws -> String {
        guard let aki = try self.extensions.authorityKeyIdentifier?.keyIdentifier else {
            throw AcmeError.missingAuthorityKeyIdentifier
        }

        var ariCertId: String
        if #available(macOS 26.4, iOS 26.4, watchOS 26.4, tvOS 26.4, visionOS 26.4, *) {
            let encodedAki = Data(aki)
                .base64EncodedString(options: [.omitPaddingCharacter, .base64URLAlphabet])
            let encodedSerial = Data(self.serialNumber.bytes)
                .base64EncodedString(options: [.omitPaddingCharacter, .base64URLAlphabet])
            ariCertId = encodedAki + "." + encodedSerial
        }
        else {
            let encodedAki = Data(aki)
                .base64EncodedString()
                .base64ToBase64Url()
            let encodedSerial = Data(self.serialNumber.bytes)
                .base64EncodedString()
                .base64ToBase64Url()
            ariCertId = encodedAki + "." + encodedSerial
        }
        return ariCertId
    }
}
