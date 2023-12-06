// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AcmeSwift",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AcmeSwift",
            targets: ["AcmeSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.10.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "2.1.0" ..< "4.0.0"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.13.1"),
        .package(url: "https://github.com/apple/swift-certificates.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-asn1.git", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AcmeSwift",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "X509", package: "swift-certificates"),
                .product(name: "SwiftASN1", package: "swift-asn1")
            ]),
        .testTarget(
            name: "AcmeSwiftTests",
            dependencies: [
                "AcmeSwift"
            ]
        ),
    ]
)
