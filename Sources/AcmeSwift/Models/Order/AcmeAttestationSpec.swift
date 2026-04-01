import Foundation

public struct AcmeAttestationSpec {
    init(attObj: String) {
        self.attObj = attObj
    }
    
    var attObj: String
}

extension AcmeAttestationSpec: Codable{}
