import Foundation
import PotentASN1

protocol HasSchemaProtocol: Codable {
    static var schema: Schema {get}
}
