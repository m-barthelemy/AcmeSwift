import Foundation

public struct AcmeAttestationSpec: Codable {
    init(attObj: String) {
        self.attObj = attObj
    }
    
    var attObj: String
}
