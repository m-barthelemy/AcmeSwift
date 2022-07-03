import Foundation
import PotentASN1

public struct X509Subject {
    /// C
    public var countryName: String?
    
    /// S
    public var stateOrProvinceName: String?
    
    /// L
    public var localityName: String?
    
    /// O
    public var organizationName: String?
    
    /// OU
    public var organizationalUnitName: String?
    
    /// CN
    public var commonName: String?
    
    /// E (deprecated)
    //public var emailAddress: String?
}

