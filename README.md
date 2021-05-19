# swift-cosmos  [ALPHA]

![Swift5.4+](https://img.shields.io/badge/Swift-5.4+-blue.svg)
![platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20linux-orange.svg)

Build blockchain applications in Swift on top of the Tendermint consensus using [SwiftNIO](https://github.com/apple/swift-nio) as the server core.

This project shows the work in progress for the port of the [Cosmos SDK](https://github.com/cosmos/cosmos-sdk) to Swift. It is based on version [0.39.1](https://github.com/cosmos/cosmos-sdk/tree/v0.39.1) of the SDK.

The primary focus is to get to parity with the Cosmos-SDK version 0.40. We are currently tracking version 0.33.9 because the Go nameservice still requires it.

## Work in progress
This is work in progress. What we currrently have is the following:

| Module/App  |  completion  |  notes
|:-----------|:---------:|:-------
| Framework  | ✔️ |   Framework mimics the CosmosSDK framework, including the directory structure.
| Store  | ✔️ |  Currently using in memory version of iAVLPlus.
| Bech32 | ✔️    |
| Auth   | ✔️    | Staking, Governance, Bank requirements in progress (see respective Modules)
| Params |   ✔️|    
| Nameservice  | 70%| Allows us to test modules.
| GenUtils | 80%|
| Supply  |  50%  |  
| Governance  |  0% |   
| Staking | 50%    |
| Simulation  |  50%|    
| Bank |   70% |   
| IBC | 0% |

We currently bundle the nameservice, all modules and the framework as one repository, however, we will redistribute this into decoupled libraries when we get closer to parity with the Cosmos-sdk.

## Requirements
- Swift version: 5.4.x
- SwiftNIO version: 2.0.x
- Tendermint/ABCI version: 0.33.9 (tendermint 0.33.9)

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
