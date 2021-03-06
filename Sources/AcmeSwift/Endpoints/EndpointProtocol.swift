import NIOHTTP1
import NIO
import NIOFoundationCompat
import Foundation

protocol EndpointProtocol {
    associatedtype Response: Codable
    associatedtype Body: Codable
    var url: URL{ get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? {get}
    var body: Body? { get }
}

extension EndpointProtocol {
    public var body: Body? {
        return nil
    }
    
    public var headers: HTTPHeaders? {
        return nil
    }
    
    public var method: HTTPMethod {
        return .POST
    }
}
