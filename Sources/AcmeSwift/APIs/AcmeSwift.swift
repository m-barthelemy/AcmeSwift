import Foundation
import NIO
import NIOHTTP1
import NIOSSL
import AsyncHTTPClient
import Logging
//import JWTKit
import Crypto

/// The entry point for Acmev2 client commands.
public class AcmeSwift {
    /// Information about the endpoints of the ACMEv2 server
    public let directory: AcmeDirectory
    
    private let headers = HTTPHeaders([
        ("User-Agent", "AcmeSwift (https://github.com/m-barthelemy/AcmeSwift)"),
        ("Content-Type", "application/jose+json")
    ])
    
    internal let login: AccountCredentials?
    internal var accountURL: URL?
    
    internal let server: URL
    internal let client: HTTPClient
    private let logger: Logger
    private let decoder: JSONDecoder
    
    public init(login: AccountCredentials? = nil, client: HTTPClient = .init(eventLoopGroupProvider: .createNew), acmeEndpoint: URL = AcmeServer.letsEncrypt, logger: Logger = Logger.init(label: "AcmeSwift")) async throws {
        self.login = login
        self.client = client
        self.server = acmeEndpoint
        self.logger = logger
        
        let format = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSS'Z'"
        let formatter = DateFormatter()
        formatter.dateFormat = format
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(formatter)
        self.decoder = decoder
        
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
            throw AcmeError.noNonceReturned
        }
        return nonce
    }
    
    /// Executes a request to a specific endpoint. The `Endpoint` struct provides all necessary data and parameters for the request.
    /// - Parameter endpoint: `Endpoint` instance with all necessary data and parameters.
    /// - Throws: It can throw an error when encoding the body of the `Endpoint` request to JSON.
    /// - Returns: Returns the expected result defined by the `Endpoint`.
    @discardableResult
    internal func run<T: EndpointProtocol>(_ endpoint: T, privateKey: Crypto.P256.Signing.PrivateKey, accountURL: URL? = nil) async throws -> (result: T.Response, headers: HTTPHeaders) {
        logger.debug("\(Self.self) execute Endpoint: \(endpoint.method) \(endpoint.url)")
        
        var finalHeaders: HTTPHeaders = .init()
        finalHeaders.add(name: "Host", value: endpoint.url.host ?? "localhost")
        finalHeaders.add(contentsOf: self.headers)
        if let additionalHeaders = endpoint.headers {
            finalHeaders.add(contentsOf: additionalHeaders)
        }
        
        var request = HTTPClientRequest(url: /*"https://webhook.site/13b95f20-62a9-41c9-92c7-c535e41144dd"*/ endpoint.url.absoluteString)
        request.method = endpoint.method
        request.headers = finalHeaders
        
        let nonce = try await self.getNonce()
        
        let wrappedBody = try AcmeRequestBody(accountURL: accountURL, privateKey: privateKey, nonce: nonce, payload: endpoint)
        let body = try JSONEncoder().encode(wrappedBody)
        
        let bodyDebug = String(data: body, encoding: .utf8)!
        logger.debug("\(Self.self) Endpoint: \(endpoint.method) \(endpoint.url) request body: \(bodyDebug)")
        
        request.body = .bytes(ByteBuffer(data: body))
        
        let response = try await client.execute(request, deadline: .now() + TimeAmount.seconds(15), logger: self.logger)
        
        /*var respBody = try await response.body.collect(upTo: 2*1024*1024)
        let data = respBody.readData(length: respBody.readableBytes)
        //let data = respBody.getData(at: 0, length: respBody.readableBytes)
        print("\n••••RESPONSE: \(String(data: data ?? Data(), encoding: .utf8)!)")*/
        
        return (result: try await response.decode(as: T.Response.self, decoder: self.decoder), headers: response.headers)
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
        //URL(string: "https://webhook.site/13b95f20-62a9-41c9-92c7-c535e41144dd")!
    }
    
    /// A custom URL to a service compatible with ACMEv2 protocol
    public static func custom(url: URL) -> URL {
        return url
    }
}
