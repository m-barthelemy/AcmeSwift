import Foundation

struct AcmeFinalizeOrderSpec: Codable {
    init(csr: String) {
        self.csr = csr
    }
    
    /// The CSR (Certificate Signing Request) for this order.
    /// The CSR is sent in the  base64url-encoded version of the DER format.
    /// Note: Because this field uses base64url, and does not include headers, it is different from PEM.
    var csr: String
}
