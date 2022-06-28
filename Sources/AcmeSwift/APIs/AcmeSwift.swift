import Foundation
import NIO
import NIOHTTP1
import NIOSSL
import AsyncHTTPClient
import Logging
import JWTKit
import Crypto

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
    
    /// Gets a Nonce (anti-replay) to include in an upcoming POST request
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
    /// - Returns: Returns the expected result defined by the `Endpoint`.
    @discardableResult
    internal func run<T: EndpointProtocol>(_ endpoint: T) async throws -> T.Response {
        logger.debug("\(Self.self) execute Endpoint: \(endpoint.method) \(endpoint.url)")
        
        var finalHeaders: HTTPHeaders = self.headers
        if let additionalHeaders = endpoint.headers {
            finalHeaders.add(contentsOf: additionalHeaders)
        }
        
        var request = HTTPClientRequest(url: endpoint.url.absoluteString)
        request.method = endpoint.method
        request.headers = finalHeaders
        
        //let signers = JWTSigners()
        //signers.use(.rs256(key: .private(pem: "")), kid: .init(string: ""), isDefault: true)
        
        let nonce = try await self.getNonce()
        
        // Create private key
        let privateKey = Crypto.P256.Signing.PrivateKey.init(compactRepresentable: true)
        
        let wrappedBody = try AcmeRequestBody(privateKey: privateKey, nonce: nonce, payload: endpoint)
        let body = try JSONEncoder().encode(wrappedBody)
        
        let bodyDebug = String(data: body, encoding: .utf8)!
        print("\n••• Request final body: \(bodyDebug)")
        
        request.body = .bytes(ByteBuffer(data: body))
        
        return try await client.execute(request, deadline: .now() + TimeAmount.seconds(15), logger: self.logger)
            .decode(as: T.Response.self, decoder: self.decoder)
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
