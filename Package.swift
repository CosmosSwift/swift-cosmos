// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "swift-cosmos",
    platforms: [
        .macos(.v10_15),
    ],
    products: [
        .library(name: "Database", targets: ["Database"]),
        .library(name: "Cosmos", targets: ["Cosmos"]),

        // X Modules
        .library(name: "Auth", targets: ["Auth"]),
        .library(name: "Bank", targets: ["Bank"]),
        .library(name: "GenUtil", targets: ["GenUtil"]),
        .library(name: "Governance", targets: ["Governance"]),
        .library(name: "Params", targets: ["Params"]),
        .library(name: "Simulation", targets: ["Simulation"]),
        .library(name: "Staking", targets: ["Staking"]),
        .library(name: "Supply", targets: ["Supply"]),
        
        .library(name: "AuthAnte", targets: ["AuthAnte"]),
        .library(name: "JSON", targets: ["JSON"]),
    ],
    dependencies: [
        .package(name: "ABCI", url: "https://github.com/CosmosSwift/swift-abci", .upToNextMajor(from: "0.50.0")),
        .package(name: "Tendermint", url: "https://github.com/CosmosSwift/swift-tendermint", .branch("main")),
        .package(name: "iAVLPlus", url: "https://github.com/CosmosSwift/swift-iavlplus", .branch("master")),
        .package(name: "swift-log", url: "https://github.com/apple/swift-log.git", .upToNextMajor(from: "1.0.0")),
        .package(name: "swift-crypto", url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.3.8")),
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.1")),
        .package(name: "BigInt", url: "https://github.com/attaswift/BigInt", .upToNextMajor(from: "5.2.1")),
        .package(name: "swift-cosmos-proto", url: "https://github.com/cosmosswift/swift-cosmos-proto.git", .branch( "main")),
        .package(name: "swift-nio", url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Cosmos",
            dependencies: [
                .target(name: "Database"),
                .target(name: "BIP39"),
                .target(name: "Bcrypt"),
                .target(name: "JSON"),
                .product(name: "iAVLPlus", package: "iAVLPlus"),
                .product(name: "InMemoryNodeDB", package: "iAVLPlus"),
                .product(name: "ABCIMessages", package: "ABCI"),
                .product(name: "ABCIServer", package: "ABCI"),
                .product(name: "ABCINIO", package: "ABCI"),
                .product(name: "DataConvertible", package: "ABCI"),
                .product(name: "Tendermint", package: "Tendermint"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "CosmosProto", package: "swift-cosmos-proto"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"),
                .product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
                .product(name: "NIOTLS", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        .target(
            name: "Auth",
            dependencies: [
                .target(name: "Cosmos"),
                .target(name: "Params"),
                .product(name: "ABCIMessages", package: "ABCI"),
                .product(name: "Tendermint", package: "Tendermint"),
                .product(name: "CosmosProto", package: "swift-cosmos-proto"),
                .product(name: "NIO", package: "swift-nio"),
            ],
            path: "./Sources/X/Auth"
        ),
        .target(
            name: "AuthAnte",
            dependencies: [
                .target(name: "Auth"),
                .target(name: "Supply"),
            ],
            path: "./Sources/X/AuthAnte"
        ),
        .target(
            name: "Bank",
            dependencies: [
                .target(name: "Cosmos"),
                .target(name: "Auth"),
                .target(name: "Params"),
            ],
            path: "./Sources/X/Bank"
        ),
        .target(
            name: "GenUtil",
            dependencies: [
                .target(name: "Cosmos"),
                .target(name: "Auth"),
                .target(name: "Staking"),
            ],
            path: "./Sources/X/GenUtil"
        ),
        .target(
            name: "Governance",
            dependencies: [
                .target(name: "Cosmos"),
            ],
            path: "./Sources/X/Governance"
        ),
        .target(
            name: "Params",
            dependencies: [
                .target(name: "Cosmos"),
            ],
            path: "./Sources/X/Params"
        ),
        .target(
            name: "Simulation",
            dependencies: [
                .target(name: "Cosmos"),
            ],
            path: "./Sources/X/Simulation"
        ),
        .target(
            name: "Staking",
            dependencies: [
                .target(name: "Cosmos"),
                .target(name: "Params"),
                .target(name: "Auth"),
                .target(name: "Supply"),
            ],
            path: "./Sources/X/Staking"
        ),
        .target(
            name: "Supply",
            dependencies: [
                .target(name: "Cosmos"),
                .target(name: "Auth"),
                .target(name: "Bank"),
            ],
            path: "./Sources/X/Supply"
        ),
        .target(name: "Database"),
        .target(
            name: "BIP39",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "BigInt", package: "BigInt"),
            ]
        ),
        .target(name: "JSON"),
        .target(name: "CBcrypt"),
        .target(
            name: "Bcrypt",
            dependencies: [
                .target(name: "CBcrypt"),
            ]
        ),
        .testTarget(name: "CosmosTests"),
    ]
)
