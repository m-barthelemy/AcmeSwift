# AcmeSwift

This is a **work in progress** Let's Encrypt (ACME v2) client written in Swift. 

It fully uses the Swift concurrency features introduced with Swift 5.5 (`async`/`await`).

Although it _might_ work with other certificate providers implementing ACMEv2, this has not been tested at all.


## Note
This library doesn't handle any ACME challenge at all by itself.
Publishing the challenge, either by creating DNS record or exposing the value over HTTP, is your full responsibility. 


## Installation
```swift
import PackageDescription

let package = Package(
    dependencies: [
        ...
        .package(url: "https://github.com/m-barthelemy/AcmeSwift.git", .branch("master")),
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

- Create a new Let's Encrypt account:

```swift
let account = acme.account.create(contacts: ["my.email@domain.com"], validateTOS: true)
```

The information returned by this method is an `AcmeAccountInfo` object that can be directly reused for authentication. 
For example, you can encode it to JSON, save it somwewhere and then decode it in order to log into your account later.

⚠️ This Account information contains a private key and as such, **must** be stored securely.


<br/>

- Reuse a previously created account:

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

- Deactivate an existing account:

⚠️ Only use this if you are absolutely certain that the account needs to be permanently deactivated. There is no going back!

```swift

try await acme.account.deactivate()
```

<br/>


### Orders (certificate requests)

Fetch an Order by its URL:
```swift
let latest = try await acme.orders.get(order: order.url!)
```

<br/>


Refresh an Order instance with latest information from the server:
```swift
try await acme.orders.refresh(order: &order)
```

<br/>


Create an Order for a new certificate:
```swift
 
let order = try await acme.orders.create(domains: ["mydomain.com", "www.mydomain.com"])
```

<br/>

Get the Order authorizations and challenges: 
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

Once the challenges are published, we can ask Let's Encrypt to validate them:
```swift
let updatedChallenges = try await acme.orders.validateChallenges(from: order, preferring: .http)
```

<br/>

Once all the authorizations/challenges are valid, we can finalize the Order by sending the CSR in PEM format.
If you already have a CSR:
```swift
let finalizedOrder = try await acme.orders.finalize(order: order, withPemCsr: "...")
```


If you want AcmeSwift to generate one for you:
```swift
// ECDSA key and certificate
let csr = try AcmeX509Csr.ecdsa(domains: ["mydomain.com", "www.mydomain.com"])
// .. or, good old RSA
let csr = try AcmeX509Csr.rsa(domains: ["mydomain.com", "www.mydomain.com"])

let finalizedOrder = try await acme.orders.finalize(order: order, withCsr: csr)
// You can access the private key used to generate the CSR (and to use once you get the certificate)
print("\n• Private key: \(csr.privateKeyPem)")
```

<br/>

> **NOTE**: The CSR must contain all the DNS names requested by the Order in its SAN (subjectAltName) field.


<br/>

### Certificates

- Download a certificate:

> This assumes that the corresponding Order has been finalized successfully, meaning that the Order `status` field is `valid`.

```swift
let certs = try await acme.certificates.download(for: finalizedOrder)
for var cert in certs {
    print("\n • cert: \(cert)")
}
```

This return a list of PEM-encoded certificates. The first item is the actual certificate for the requested domains.
The following items are the other certificates required to establish the full certification chain (issuing CA, root CA...).

The order of the items in the list is directly compatible with the way Nginx expects them; you can concatenate all the items into a single file and pass this file to the `ssl_certificate` directive:
```swift
try certs.joined(separator: "\n")
    .write(to: URL(fileURLWithPath: "cert.pem"), atomically: true, encoding: .utf8)
```

<br/>

- Revoke a certificate:
```swift
try await acme.certificates.revoke(certificatePem: "....")
```


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

let domains: [String] = ["ponies.com", "www.ponies.com"]

// Create a certificate order for *.ponies.com
let order = try await acme.orders.create(domains: domains)

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
// If some challenges fail to validate, it is safe to call validateChallenges() again after fixing the underlying issue.
let failed = try await acme.orders.validateChallenges(from: order, preferring: .dns)
guard failed.count == 0 else {
    fatalError("Some validations failed! \(failed)")
}

// Let's create a private key and CSR using the rudimentary feature provided by AcmeSwift
let csr = try AcmeX509Csr.ecdsa(domains: domains)

// If the validation didn't throw any error, we can now send our Certificate Signing Request...
let finalized = try await acme.orders.finalize(order: order, withCsr: csr)

// ... and the certificate is ready to download!
let certs = try await acme.certificates.download(for: finalized)

// Let's save the full certificates chain to a file 
try certs.joined(separator: "\n").write(to: URL(fileURLWithPath: "cert.pem"), atomically: true, encoding: .utf8)

// Now we also need to export the private key, encoded as PEM
// If your server doesn't accept it, append a line return to it.
try csr.privateKeyPem.write(to: URL(fileURLWithPath: "key.pem"), atomically: true, encoding: .utf8)
``` 



## Credits
Part of the CSR feature is inspired by and/or taken from the excellent Shield project (https://github.com/outfoxx/Shield)
