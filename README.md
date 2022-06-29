# AcmeSwift

This is a **work in progress** Let's Encrypt (ACME v2) client written in Swift. 

It fully uses the Swift concurrency features introduced with Swift 5.5 (`async`/`await`).

Although it _might_ work with other certificate providers implementing ACMEv2, this has not been tested at all.


## Note
This library doesn't handle any ACME challenge at all by itself.
Publishing the challenge, either by creating DNS record or exposing the value over HTTP, is your full responsibility. 


## Usage

Create an instance of the client:
```swift
let acme = try await AcmeSwift()

```

When testing, preferably use the Let's Encrypt staging endpoint:
```swift
let acme = try await AcmeSwift(acmeEndpoint: AcmeServer.letsEncryptStaging)

```


### Account

Create a new Let's Encrypt account:

```swift
let account = acme.account.create(contacts: ["my.email@domain.com"], validateTOS: true)
```

Reuse a previously created account:

```swift
let account = acme.account.use(.......)
```

Deactivate an existing account:

⚠️ Only use this if you are absolutely certain that the account needs to be permanently deactivated. There is no going back!

```swift

try await acme.account.deactivate()
```

### Orders (certificate requests)

 Create an order for a new certificate:
 
 ```swift
 
 let order = try await acme.orders.create(domains: ["mydomain.com", "www.mydomain.com"])
 ```
 

Finalize an order:
```swift
let finalizedOrder = try await acme.orders.finalize(order: order, withCsr: "...")
```


### Certificates

Download a certificate:
This assumes that the corresponding Order has been finalized successfully, meaning that the Order `status` field is `valid`.

```swift
let certs = try await acme.certificates.download(order: finalizedOrder)
```
