# AcmeSwift
[![Language](https://img.shields.io/badge/Swift-5.5-brightgreen.svg)](http://swift.org)
[![Platforms](https://img.shields.io/badge/platform-linux--64%20%7C%20osx--64-blue)]()

This is an ACME v2 client written in Swift.


## Note
- This library doesn't handle any ACME challenge at all by itself. Publishing the challenge, either by creating DNS record or exposing the value over HTTP, is out of scope. 
- It's currently tested with Let's Encrypt. While it may work with other certificate authorities, there is currently no support for External Account Binding (EAB) which is required by some of them. 


## Installation
```swift
import PackageDescription

let package = Package(
    dependencies: [
        ...
        .package(url: "https://github.com/m-barthelemy/AcmeSwift.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "App", dependencies: [
            ...
            .product(name: "AcmeSwift", package: "AcmeSwift")
        ]),
    ...
    ]
)
```

## Usage

Create an instance of the client:
```swift
import AcmeSwift

let acme = try await AcmeSwift()

```

When testing, preferably use the Let's Encrypt staging endpoint:
```swift
import AcmeSwift

let acme = try await AcmeSwift(acmeEndpoint: .letsEncryptStaging)

```

<br/>


### Account

#### Create a new Let's Encrypt account:

```swift
let account = acme.account.create(contacts: ["my.email@domain.com"], validateTOS: true)
```

The information returned by this method is an `AcmeAccountInfo` object that can be directly reused for authentication. 
For example, you can encode it to JSON, save it somewhere and then decode it in order to log into your account later.

> [!WARNING]
> This Account information contains a private key and as such, **must** be stored securely.
> This is especially important if you are using [`dns-persist-01`](https://letsencrypt.org/2026/02/18/dns-persist-01#dns-persist-01-authorizes-persistently) challenges, who can grant permanent permissions to generate certificates for a given DNS record or even a whole domain to your ACME account.

<br/>

#### Reuse a previously created account:

Option 1: Directly use the object returned by `account.create(...)`
```swift
try acme.account.use(account)
```

Option 2: Pass credentials "manually"
```swift
let credentials = try AccountCredentials(contacts: ["my.email@domain.tld"], pemKey: "private key in PEM format")
try acme.account.use(credentials)
```

If you created your account using AcmeSwift, the private key in PEM format is stored into the `AccountInfo.privateKeyPem` property.

<br/>

#### Deactivate an existing account:

> [!CAUTION]
> Only use this if you are absolutely certain that the account needs to be permanently deactivated. There is no going back!

```swift

try await acme.account.deactivate()
```

<br/>


### Orders (certificate requests)

#### Fetch an Order by its URL:
```swift
let latest = try await acme.orders.get(url: order.url!)
```

<br/>


#### Refresh an Order instance with latest information from the server:
```swift
try await acme.orders.refresh(&order)
```

<br/>


#### Create an Order for a new certificate:
```swift
 
var order = try await acme.orders.create(domains: ["mydomain.com", "www.mydomain.com"])
```

<br/>

#### Get the Order authorizations and challenges: 
```swift
let authorizations = try await acme.orders.getAuthorizations(from: order)
```

<br/>

You will need to publish the challenges. AcmeSwift provides a way to list the pending HTTP or DNS challenges:
```swift
let challengeDescs = try await acme.orders.describePendingChallenges(from: order, preferring: .http)
for desc in challengeDescs {
    if desc.type == .http {
        print("\n • The URL \(desc.endpoint) needs to return \(desc.value)")
    }
    else if desc.type == .dns {
        print("\n • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
    }
}
```
Achieving this depends on your DNS provider and/or web hosting solution and is outside the scope of AcmeSwift.
> Note: if you are requesting a wildcard certificate and choose `.http` as the preferred validation method, you will still get a DNS challenge to complete.
Let's Encrypt only allows DNS validation for wildcard certificates.

<br/>

#### Ask Let's Encrypt to validate the challenges:
```swift
let updatedChallenges = try await acme.orders.validateChallenges(from: order, preferring: .http)
```

<br/>

#### Finalize the order
Once all the authorizations/challenges are valid, we can finalize the Order by sending the CSR in PEM format.

If you already have a CSR:
```swift
try await acme.orders.finalize(order: &order, withPemCsr: "...")
```


If you want AcmeSwift to generate a private key and CSR for you:
```swift
// ECDSA key and certificate
let key = try await acme.orders.finalize(order: &order) // Defaults to ECDSA P-384
let key = try await acme.orders.finalize(order: &order, type: .ecdsa(.p256)) // Custom: ECDSA P-256
// .. or, good old RSA
let key = try await acme.orders.finalize(order: &order, type: .rsa(.`2048`))

// You can access the private key used to generate the CSR (and to use once you get the certificate)
print("\n• Private key: \(try privateKey.serializeAsPEM().pemString)")
```

<br/>

> [!NOTE]  
> The CSR must contain all the DNS names requested by the Order in its SAN (subjectAltName) field.


<br/>

After that you can [download your certificate](#download-a-certificate)

### Renewals (ARI)
Historically, the ACMEv2 protocol had no such concept, and renewing a certificate was just a matter of creating a new order. 
While this is still a valid option, a new order counts against Let's Encrypt rate limits, and does not allow to know if certificate should be renewed earlier than anticipated due to an issue on the CA side. 
[RFC9773](https://www.rfc-editor.org/rfc/rfc9773.html) adds support for certificates renewals, and for obtaining information about the suggested renewal window.

To renew a certificate:

```swift
var renewOrder = try await acme.orders.replace(certificate: x509)

```

Then treat `renewOrder` as a regular order: grab the challenges, publish them, request their validation, and finalize the order.

<br/>


### Certificates

#### Download a certificate:

> This assumes that the corresponding Order has been finalized successfully, meaning that the Order `status` field is `valid`.

```swift
let certs = try await acme.certificates.download(for: finalizedOrder)
for var cert in certs {
    print("\n • cert: \(cert)")
}
```

This return a list of PEM-encoded certificates. The first item is the actual, leaf certificate for the requested domains.
The following items are the other certificates required to establish the full certification chain (issuing CA, root CA...).

The order of the items in the list is directly compatible with the way SwiftNIO and Nginx expects them; you can concatenate all the items into a single file and pass this file to the `ssl_certificate` directive:
```swift
try certs.joined(separator: "\n")
    .write(to: URL(fileURLWithPath: "cert.pem"), atomically: true, encoding: .utf8)
```

<br/>

#### Revoke a certificate:
```swift
try await acme.certificates.revoke(certificatePem: "....")
```

<br/>

#### Check if/when a certificate should be renewed

```swift
let renewalInfo = try await acme.certificates.getRenewalInfo(certificatePem: ...)
if renewalInfo.suggestedWindow.start < Date() {
    print("It's time to renew!")
}
else if let nextCheck = renewalInfo.nextCheck {
    print("We should be checking again at \(Date().addingTimeInterval(nextCheck))")
}
```

See how to [make a renewal order](#renewals-ari).

> [!NOTE]  
> If you trigger the renewal within the renewal window, Let's Encrypt rate limits do not apply.

<br/>

## Example

Let's suppose that we own the `ponies.com` domain and that we want a wildcard certificate for it.
We also assume that we have an existing Let's Encrypt account.

```swift
import AcmeSwift

// Create the client and load Let's Encrypt credentials
let acme = try await AcmeSwift()
let accountKey = try String(contentsOf: URL(fileURLWithPath: "letsEncryptAccountKey.pem"), encoding: .utf8)
let credentials = try AccountCredentials(contacts: ["email@domain.tld"], pemKey: accountKey)
try acme.account.use(credentials)

let domains: [String] = ["*.ponies.com", "ponies.com"]

// Create a certificate order for *.ponies.com
var order = try await acme.orders.create(domains: domains)

// ... after that, now we can fetch the challenges we need to complete
for desc in try await acme.orders.describePendingChallenges(from: order, preferring: .dns) {
    if desc.type == .http {
        print("\n • The URL \(desc.endpoint) needs to return \(desc.value)")
    }
    else if desc.type == .dns {
        print("\n • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
    }
}
 
// At this point, we could programmatically create the challenge DNS records using our DNS provider's API
[.... publish the DNS challenge records ....]


// Assuming the challenges have been published, we can now ask Let's Encrypt to validate them.
// If some challenges fail to validate, it is safe to call validateChallenges() again after fixing the underlying issue. Note that challenges may take a while to complete, and the ACME specification recommends polling as soon as you recieve a request or know the challenge can be verified: https://www.rfc-editor.org/rfc/rfc8555.html#section-7.5.1
var remainingChallenges = try await acme.orders.validateChallenges(from: order, preferring: .dns)
// Poll with progressively longer timeouts. These are arbitrary and may be modified to suit your needs (certbot tries every second, but this seems more kind if there is no rush).
for timeout in [5, 10, 10, 10, 30] {
    guard !remainingChallenges.isEmpty else { break }
    try await Task.sleep(for: .seconds(timeout))
    remainingChallenges = try await acme.orders.validateChallenges(from: order, preferring: .dns)
}
// Give up if we still haven't satisfied the request:
guard remainingChallenges.isEmpty else {
    struct ChallengeValidationError: Error {}
    throw ChallengeValidationError()
}

// Let's create a private key, a CSR and send it all at once.
// If the validation didn't throw any error, we can now send our Certificate Signing Request...
let key = try await acme.orders.finalize(order: &order, type: .ecdsa())

// ... and the certificate is ready to download!
let certs = try await acme.certificates.download(for: finalizedOrder)

// Let's save the full certificates chain to a file 
try certs.joined(separator: "\n").write(to: URL(fileURLWithPath: "cert.pem"), atomically: true, encoding: .utf8)

// Now we also need to export the private key, encoded as PEM
// If your server doesn't accept it, append a line return to it.
try privateKey.serializeAsPEM().pemString.write(to: URL(fileURLWithPath: "key.pem"), atomically: true, encoding: .utf8)
``` 

