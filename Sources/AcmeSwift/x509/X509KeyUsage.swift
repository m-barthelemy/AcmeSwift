import Foundation

public struct X509KeyUsage: OptionSet {
    public let rawValue: UInt16
    
    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    public static let digitalSignature = X509KeyUsage(rawValue: 1 << 0)
    public static let nonRepudiation = X509KeyUsage(rawValue: 1 << 1)
    public static let keyEncipherment = X509KeyUsage(rawValue: 1 << 2)
    public static let dataEncipherment = X509KeyUsage(rawValue: 1 << 3)
    public static let keyAgreement = X509KeyUsage(rawValue: 1 << 4)
    public static let keyCertSign = X509KeyUsage(rawValue: 1 << 5)
    public static let cRLSign = X509KeyUsage(rawValue: 1 << 6)
    public static let encipherOnly = X509KeyUsage(rawValue: 1 << 7)
    public static let decipherOnly = X509KeyUsage(rawValue: 1 << 8)
    public static let contentCommitment = nonRepudiation
}
