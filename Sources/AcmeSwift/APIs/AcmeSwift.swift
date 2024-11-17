import Foundation
import NIO
import NIOHTTP1
import NIOSSL
import AsyncHTTPClient
import Logging
import Crypto

/// The entry point for Acmev2 client commands.
public class AcmeSwift {
    /// Information about the endpoints of the ACMEv2 server
    public let directory: AcmeDirectory
    
    private let headers = HTTPHeaders([
        ("User-Agent", "AcmeSwift (https://github.com/m-barthelemy/AcmeSwift)"),
        ("Content-Type", "application/jose+json")
    ])
    
    internal var login: AccountCredentials?
    internal var accountURL: URL?
    
    internal let server: URL
    internal let client: HTTPClient
    private let logger: Logger
    private let decoder: JSONDecoder
    
    public init(client: HTTPClient = .init(eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton)), acmeEndpoint: AcmeEndpoint = .letsEncrypt, logger: Logger = Logger.init(label: "AcmeSwift")) async throws {
        self.client = client
        self.server = acmeEndpoint.value
        self.logger = logger
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
        
        var request = HTTPClientRequest(url: self.server.absoluteString)
        request.method = .GET
        self.directory = try await self.client.execute(request, deadline: .now() + TimeAmount.seconds(30), logger: self.logger)
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
            throw AcmeError.noNonceReturned
        }
        return nonce
    }
    
    /// Ensure we have account credentials for actions that require it.
    internal func ensureLoggedIn() async throws {
        guard self.login != nil else {
            throw AcmeError.mustBeAuthenticated("Request requires credentials")
        }
        
        if self.accountURL == nil {
            let info = try await self.account.get()
            self.accountURL = info.url
        }
    }
    /// Executes a request to a specific endpoint. The `Endpoint` struct provides all necessary data and parameters for the request.
    /// - Parameter endpoint: `Endpoint` instance with all necessary data and parameters.
    /// - Throws: It can throw an error when encoding the body of the `Endpoint` request to JSON.
    /// - Returns: Returns the expected result defined by the `Endpoint`.
    @discardableResult
    internal func run<T: EndpointProtocol>(_ endpoint: T, privateKey: Crypto.P256.Signing.PrivateKey, accountURL: URL? = nil) async throws -> (result: T.Response, headers: HTTPHeaders) {
        logger.debug("\(Self.self) execute Endpoint \(T.self): \(endpoint.method) \(endpoint.url)")
        
        var finalHeaders: HTTPHeaders = .init()
        finalHeaders.add(name: "Host", value: endpoint.url.host ?? "localhost")
        finalHeaders.add(contentsOf: self.headers)
        if let additionalHeaders = endpoint.headers {
            finalHeaders.add(contentsOf: additionalHeaders)
        }
        
        var request = HTTPClientRequest(url: endpoint.url.absoluteString)
        request.method = endpoint.method
        request.headers = finalHeaders
        
        let nonce = try await self.getNonce()
        
        let wrappedBody = try AcmeRequestBody(accountURL: accountURL, privateKey: privateKey, nonce: nonce, payload: endpoint)
        let body = try JSONEncoder().encode(wrappedBody)
        
        let bodyDebug = String(decoding: body, as: UTF8.self)
        logger.debug("\(Self.self) Endpoint: \(endpoint.method) \(endpoint.url) request body: \(bodyDebug)")
        
        request.body = .bytes(ByteBuffer(data: body))
        
        let response = try await client.execute(request, deadline: .now() + TimeAmount.seconds(15), logger: self.logger)
        
        return (result: try await response.decode(as: T.Response.self, decoder: self.decoder), headers: response.headers)
    }
}

public enum AcmeEndpoint: Sendable {
    /// The default, production Let's Encrypt endpoint
    case letsEncrypt
    /// The staging Let's Encrypt endpoint, for tests. Issues certificate not recognized by clients/browsers
    case letsEncryptStaging
    /// A custom URL to a service compatible with the ACMEv2 protocol
    case custom(URL)
    
    public var value: URL {
        switch self {
            case .letsEncrypt: return URL(string: "https://acme-v02.api.letsencrypt.org/directory")!
            case .letsEncryptStaging: return URL(string: "https://acme-staging-v02.api.letsencrypt.org/directory")!
            case .custom(let url): return url
        }
    }
}
