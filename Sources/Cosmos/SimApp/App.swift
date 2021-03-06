import JSON
import Tendermint
import ABCIMessages

// App implements the common methods for a Cosmos SDK-based application
// specific blockchain.
public protocol App {
    /// The assigned name of the app.
    var name: String { get }

    // The application types codec.
    // NOTE: This should be sealed before being returned.
    var codec: Codec { get }

    // Application updates every begin block.
    func beginBlocker(request: Request, beginBlockRequest: RequestBeginBlock) -> ResponseBeginBlock

    // Application updates every end block.
    func endBlocker(request: Request, endBlockRequest: RequestEndBlock) -> ResponseEndBlock

    // Application update at chain (i.e app) initialization.
    func initChainer(request: Request, initChainRequest: RequestInitChain) -> ResponseInitChain

    // Loads the app at a given height.
    func load(height: Int64) throws

    // Exports the state of the application for a genesis file.
    func exportAppStateAndValidators(
        forZeroHeight: Bool,
        jailWhiteList: [String]
    ) throws -> (JSON, [GenesisValidator])

    // All the registered module account addreses.
    static var moduleAccountAddresses: [String: Bool] { get }

    // Helper for the simulation framework.
    var simulationManager: SimulationManager? { get }
}
