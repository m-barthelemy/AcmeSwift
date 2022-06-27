import Foundation
import NIO
import NIOHTTP1
import NIOSSL
import AsyncHTTPClient
import Logging

/// The entry point for Acmev2 client commands.
public class AcmeSwift {
    
    private let headers = HTTPHeaders([
        ("Host", "localhost"),
        ("Accept", "application/json;charset=utf-8"),
        ("Content-Type", "application/json")
    ])
    
    private let decoder: JSONDecoder
    
    internal let server: URL
    internal let client: HTTPClient
    private let logger: Logger
    
    public init(client: HTTPClient = .init(eventLoopGroupProvider: .createNew), acmeEndpoint: URL = AcmeServer.letsEncrypt, logger: Logger = Logger.init(label: "AcmeSwift")) {
        self.client = client
        self.server = acmeEndpoint
        self.logger = logger
        
        self.decoder = JSONDecoder()
    }
    
    public struct AcmeServer {
        /// The default, production Let's Encrypt endpoint
        public static var letsEncrypt: URL {
            URL(string: "https://acme-v02.api.letsencrypt.org/directory")!
        }
        
        /// The staging Let's Encrypt endpoint, for tests. Issues certificate not recognized by clients/browsers
        public static var letsEncryptStaging: URL {
            URL(string: "https://acme-staging-v02.api.letsencrypt.org/directory")!
        }
        
        /// A custom URL to a service compatible with ACMEv2 protocol
        public static func custom(url: URL) -> URL {
            return url
        }
    }
}
