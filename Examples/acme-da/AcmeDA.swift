// The Swift Programming Language
// https://docs.swift.org/swift-book

import AcmeSwift
import ArgumentParser
import AsyncHTTPClient
import Foundation
import Logging
import NIOSSL
import X509

let processName = ProcessInfo.processInfo.processName

@main
struct AcmeDA: AsyncParsableCommand {  
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            abstract: "An example of usage of ACME-DA with step-ca.",
            usage: "STTY=-icanon \(processName) <permanent-identifier> <csr-file> <directory> --cacert <cacert>",
            discussion: """
            To be able to run this example, we need to use a key that can be attested,
            "step-ca" [1], for example, supports attestation using YubiKey 5 Series.

            To configure "step-ca" with device-attest-01 support, you need to create an ACME
            provisioner with the device-attest-01 challenge enabled. In the ca.json the
            provisioner looks like this:

            {
                "type": "ACME",
                "name": "attestation",
                "challenges": [ "device-attest-01" ]
            }

            After configuring "step-ca" the first thing that we need is to create a key in
            one of the YubiKey slots. We're picking 82 in this example. To do this, we will
            use "step" [2] with the "step-kms-plugin" [2], and we will run the following:

            step kms create "yubikey:slot-id=82?pin-value=123456"

            Then we need to create a CSR signed by this new key. This CSR must include the
            serial number in the Permanent Identifier Subject Alternative Name extension.
            The serial number of a YubiKey is printed on the key, but it is also available
            in an attestation certificate. You can see it running:

            step kms attest "yubikey:slot-id=82?pin-value=123456" | \
            step certificate inspect

            To add the permanent identifier, we will need to use the following template:

            {
                "subject": {{ toJson .Subject }},
                "sans": [{
                    "type": "permanentIdentifier",
                    "value": {{ toJson .Subject}}
                }]
            }

            Having the template in "attestation.tpl", and assuming the serial number is
            123456789, we can get the proper CSR running:

            step certificate create --csr --template attestation.tpl \
            --kms "yubikey:?pin-value=123456" --key "yubikey:slot-id=82" \
            123456789 att.csr

            With this we can run this program with the new CSR:

            STTY=-icanon \(processName) 123456789 att.csr https://localhost:9000/acme/attestation/directory

            The program will ask you to create an attestation of the ACME Key Authorization,
            running:

            echo -n <key-authorization> | \
            step kms attest --format step "yubikey:slot-id=82?pin-value=123456"

            Note that because the input that we need to paste is usually more than 1024
            characters, the "STTY=-icanon" environment variable is required.

            [1] step-ca         - https://github.com/smallstep/certificates
            [2] step            - https://github.com/smallstep/cli
            [3] step-kms-plugin - https://github.com/smallstep/step-kms-plugin
            """)
    }

    @Argument(help: "The permanent identifier to use.")
    public var permanentIdentifier: String

    @Argument(help: "The path of the CSR file to use.")
    public var csrFile: String

    @Argument(help: "The URL of the ACME directory to use.")
    public var directory: String

    @Option(help: "The path to the CA certificate to verify peer against.")
    public var cacert: String

    
    public func run() async throws {
        if ProcessInfo.processInfo.environment["STTY"] != "-icanon" {
            print("Please run this program with the environment variable STTY=-icanon")
            return
        }

        let logger = Logger.init(label: "acme-da")

        let directoryURL = URL(string: directory)!
        let csrFileURL = URL(fileURLWithPath: csrFile)

        // Parse CSR
        let csrPem = try String(contentsOf: csrFileURL, encoding: .utf8)
        let csr = try CertificateSigningRequest(pemEncoded: csrPem)

        // Initialize HTTP client with optional root
        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        if cacert != "" {
            tlsConfiguration.trustRoots = .file(cacert)
        }
        var config = HTTPClient.Configuration(
            certificateVerification: .fullVerification, backgroundActivityLogger: logger)
        config.tlsConfiguration = tlsConfiguration
        let client = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: config,
        )

        // Initialize ACME client
        let acme = try await AcmeSwift(
            client: client, acmeEndpoint: .custom(directoryURL), logger: logger)
        defer { try? acme.syncShutdown() }

        // Initialize ACME account
        let contacts: [String] = ["mailto:you@example.com"]
        let account = try await acme.account.create(contacts: contacts, acceptTOS: true)
        try acme.account.use(account)

        var attObj: String = ""
        var order = try await acme.orders.create(permanentIdentifier: permanentIdentifier)
        for desc in try await acme.orders.describePendingChallenges(
            from: order, preferring: .deviceAttest)
        {
            print("Now you need to sign following keyAuthorization:")
            print(desc.value)
            print()
            print("To do this you can use step-kms-plugin running:")
            print(
                "echo -n \(desc.value) | step kms attest --format step \"yubikey:slot-id=82?pin-value=123456\""
            )
            print()
            print("Please enter the base64 output and press Enter:")
            if let str = readLine() {
                attObj = str
            } else {
                print("No input was provided.")
                return
            }
        }

        let payload = acme.orders.createAttestationPayload(attObj: attObj)
        let updatedChallenges = try await acme.orders.validateChallenges(
            from: order, preferring: .deviceAttest, payload: payload)
        if updatedChallenges.count == 0 {
            fatalError("Challenged failed")
        }
        try await acme.orders.refresh(&order)

        let info = try await acme.orders.finalize(order: order, withCsr: csr)
        let certs = try await acme.certificates.download(for: info)
        print()
        for crt in certs {
            print(crt)
        }
    }
}

struct AcmeAttestationSpec: Codable {
    init(attObj: String) {
        self.attObj = attObj
    }
    
    var attObj: String
}
