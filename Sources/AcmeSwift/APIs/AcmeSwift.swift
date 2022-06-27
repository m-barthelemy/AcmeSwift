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
        ("Content-Type", "application/jose+json")
    ])
    
    internal let server: URL
    internal let client: HTTPClient
    private let logger: Logger
    private let decoder: JSONDecoder
    
    public init(client: HTTPClient = .init(eventLoopGroupProvider: .createNew), acmeEndpoint: URL = AcmeServer.letsEncrypt, logger: Logger = Logger.init(label: "AcmeSwift")) async throws {
        self.client = client
        self.server = acmeEndpoint
        self.logger = logger
        
        self.decoder = JSONDecoder()
        
        var request = HTTPClientRequest(url: acmeEndpoint.absoluteString)
        request.method = .GET
        self.directory = try await self.client.execute(request, deadline: .now() + TimeAmount.seconds(15), logger: self.logger)
            .decode(as: AcmeDirectory.self)
    }
    
    /// The client needs to be shutdown otherwise it can crash on exit.
    public func syncShutdown() throws {
        try client.syncShutdown()
    }
    
    internal func getNonce() async throws -> String {
        var nonce = HTTPClientRequest(url: self.directory.newNonce.absoluteString)
        nonce.method = .HEAD
        let response = try await self.client.execute(nonce, deadline: .now() + TimeAmount.seconds(15))
        guard let nonce =  response.headers["Replay-Nonce"].first else {
            throw AcmeUnspecifiedError.noNonceReturned
        }
        return nonce
    }
    
    /// Executes a request to a specific endpoint. The `Endpoint` struct provides all necessary data and parameters for the request.
    /// - Parameter endpoint: `Endpoint` instance with all necessary data and parameters.
    /// - Throws: It can throw an error when encoding the body of the `Endpoint` request to JSON.
    /// - Returns: Returns the expected result definied by the `Endpoint`.
    @discardableResult
    internal func run<T: Endpoint>(_ endpoint: T) async throws -> T.Response {
        logger.debug("\(Self.self) execute Endpoint: \(endpoint.method) \(endpoint.path)")
        var finalHeaders: HTTPHeaders = self.headers
        if let additionalHeaders = endpoint.headers {
            finalHeaders.add(contentsOf: additionalHeaders)
        }
        return try await client.execute(
            endpoint.method,
            daemonURL: self.deamonURL,
            urlPath: "/\(apiVersion)/\(endpoint.path)",
            body: endpoint.body.map {HTTPClient.Body.data( try! $0.encode())},
            logger: logger,
            headers: finalHeaders
        )
        .logResponseBody(logger)
        .decode(as: T.Response.self, decoder: self.decoder)
        .get()
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
