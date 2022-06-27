# AcmeSwift

This is a Let's Encrypt (ACME v2) client written in Swift. 

It fully uses the Swift concurrency features introduced with Swift 5.5 (`async`/`await`).


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


### Orders (certificate requests)

 
