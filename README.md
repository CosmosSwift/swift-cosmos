# swift-cosmos  [ALPHA]

![Swift5.4+](https://img.shields.io/badge/Swift-5.4+-blue.svg)
![platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20linux-orange.svg)

Build blockchain applications in Swift on top of the Tendermint consensus using [SwiftNIO](https://github.com/apple/swift-nio) as the server core.

This project shows the work in progress for the port of the [Cosmos SDK](https://github.com/cosmos/cosmos-sdk) to Swift. It is originally based on version [0.39.1](https://github.com/cosmos/cosmos-sdk/tree/v0.39.1) of the SDK, but during the development, we also incorporated implementations from 0.40.x and later, as we relaxed the requirements for the earlier version required by the go implementation of the nameservice.

## Work in progress
The current state of the repo allows us to implement all nameservice commands. The focus of the implementation has so far been to clone features and not to diverge too much from the Go implementation until the Swift framework was a bit more mature. We will now allow some divergence to start using more "Swifty" paradigms in the code.

We have followed the split of the repo into a cosmos one and an ibc one (https://github.com/cosmosswift/swift-ibc). In addition to the base framework, this repo contains the core modules (still organized partly as the 0.39.1 structure, but slowly moving to the more recent organisation where some modules have been merged) except for ibc. 

## Requirements
- Swift version: 5.4.x
- SwiftNIO version: 2.0.x
- Tendermint/ABCI version: 0.34.0 (tendermint 0.34.0)

## Installation

Requires macOS or a variant of Linux with the Swift 5.4.x toolchain installed.

When running on an Apple M1 from XCode, you need to set the minimum macOS version to 11 in `Package.swift` as such:
```
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "swift-cosmos",
    platforms: [
        //.macOS(.v10_15),
        .macOS("11.0")
    ],
...
)
```

## Getting Started

1. Checkout the code from github:
```
git clone https://github.com/cosmosswift/swift-cosmos.git
```

2. Compile

```bash
swift build
```

## Documentation

The docs for the latest tagged release are always available at the [wiki](https://github.com/CosmosSwift/swift-cosmos/wiki).

## Questions

For bugs or feature requests, file a new [issue](https://github.com/cosmosswift/swift-cosmos/issues).

For all other support requests, please email [opensource@katalysis.io](mailto:opensource@katalysis.io).

## Changelog

[SemVer](https://semver.org/) changes are documented for each release on the [releases page](https://github.com/cosmosswift/swift-cosmos/-/releases).

## Contributing

Since the software is still under heavy development, our current focus is first and foremost to reach parity with version 0.39.1 of the Cosmos SDK. In the meantime, we still welcome any contribution, however, we apologize in advance if we are slow to respond.

Should you want contribute, check out [CONTRIBUTING.md](https://github.com/cosmosswift/swift-cosmos/blob/main/CONTRIBUTING.md) for more information on how to help with **swift-cosmos**.

## Contributors

Check out [CONTRIBUTORS.txt](https://github.com/cosmosswift/swift-cosmos/blob/main/CONTRIBUTORS.txt) to see the full list. This list is updated for each release.
