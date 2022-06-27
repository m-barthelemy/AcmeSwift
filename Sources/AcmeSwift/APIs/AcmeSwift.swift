import Foundation
import NIO
import NIOHTTP1
import NIOSSL
import AsyncHTTPClient
import Logging

/// The entry point for Acmev2 client commands.
public class AcmeSwift {
    /// Information about the endpoints of the ACMEv2 server
    public let directory: AcmeDirectory
    
    private let headers = HTTPHeaders([
        ("Host", "localhost"),
        ("Accept", "application/json;charset=utf-8"),
        ("Content-Type", "application/json")
    ])
    
    private let decoder: JSONDecoder
    internal let server: URL
    internal let client: HTTPClient
    private let logger: Logger
    
    
    public init(client: HTTPClient = .init(eventLoopGroupProvider: .createNew), acmeEndpoint: URL = AcmeServer.letsEncrypt, logger: Logger = Logger.init(label: "AcmeSwift")) async throws {
        self.client = client
        self.server = acmeEndpoint
        self.logger = logger
        
        self.decoder = JSONDecoder()
        
        var request = HTTPClientRequest.init(url: acmeEndpoint.absoluteString)
        request.method = .GET
        self.directory = try await self.client.execute(request, deadline: .now() + TimeAmount.seconds(15), logger: self.logger)
            .decode(as: AcmeDirectory.self)
        
    }
    
    /// The client needs to be shutdown otherwise it can crash on exit.
    public func syncShutdown() throws {
        try client.syncShutdown()
    }
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
