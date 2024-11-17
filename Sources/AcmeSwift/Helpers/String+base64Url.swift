import Foundation

extension String {
    
    /// Decodes a Base64 string into a decoded string.
    func fromBase64Url() -> String? {
        var base64 = self
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        guard let data = Data(base64Encoded: base64)
        else { return nil }
        
        return String(decoding: data, as: UTF8.self)
    }
    
    /// Encodes the string as a Base64 string suitable for use as URL parameters.
    @usableFromInline
    func toBase64Url() -> String {
        return Data(self.utf8)
            .base64EncodedString()
            .base64ToBase64Url()
    }
    
    /// Converts a Base64 string to one suitable for use as URL parameters.
    @usableFromInline
    func base64ToBase64Url() -> String {
        return self
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Converts a PEM certificate or key into a Base64 string suitable for use as URL parameters.
    func pemToBase64Url() -> String {
        return self.replacingOccurrences(of: "-----BEGIN CERTIFICATE REQUEST-----", with: "")
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE REQUEST-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .toBase64Url()
    }
    
    /// Converts a PEM certificate or key back to DER.
    func pemToData() -> Data {
        let rawData = self.replacingOccurrences(of: "-----BEGIN CERTIFICATE REQUEST-----", with: "")
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE REQUEST-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Data(base64Encoded: rawData)!
    }
}

extension Data {
    func toBase64UrlString() -> String {
        return self.base64EncodedString().base64ToBase64Url()
    }
}
