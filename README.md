# AcmeSwift

This is a **work in progress** Let's Encrypt (ACME v2) client written in Swift. 

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

Deactivate an existing account:

⚠️ Only use this if you are absolutely certain that the account needs to be permanently deactivated. There is no going back!

```swift

try await acme.account.deactivate()
```

### Orders (certificate requests)

 Create an order for a new certificate:
 
 ```swift
 
 let order = try await acme.order.create(domains: ["mydomain.com", "www.mydomain.com"])
 ```
 
