import Foundation
import Logging
import ABCIMessages

/// Request is an immutable object contains all information needed to
/// process a request.
public final class Request {
    var multiStore: MultiStore
    public var header: Header
    let chainID: String
    var transactionData: Data = Data()
    public let logger: Logger
    var voteInfo: [VoteInfo] = []
    public var gasMeter: GasMeter
    var blockGasMeter: GasMeter? = nil
    var checkTransaction: Bool
    
    var recheckTransaction: Bool = false {
        // if recheckTx == true, then checkTx must also be true
        didSet {
            if recheckTransaction {
                checkTransaction = true
            }
        }
    }
    
    var minGasPrices: [DecimalCoin]
    var consensusParams: ConsensusParams? = nil
    public var eventManager:  EventManager
    
    // create a new context
    init(
        multiStore: MultiStore,
        header: Header,
        isCheckTransaction: Bool,
        gasMeter: GasMeter = InfiniteGasMeter(),
        logger: Logger
    ) {
        self.multiStore = multiStore
        self.header = header
        self.chainID = header.chainID
        self.checkTransaction = isCheckTransaction
        self.logger = logger
        self.gasMeter = gasMeter
        self.minGasPrices = [DecimalCoin]()
        self.eventManager = EventManager()
    }
}

// ----------------------------------------------------------------------------
// Store / Caching
// ----------------------------------------------------------------------------

extension Request {
    // KVStore fetches a KVStore from the MultiStore.
    public func keyValueStore(key: StoreKey) -> KeyValueStore {
        GasKeyValueStore(
            parent: multiStore.keyValueStore(key: key),
            gasMeter: gasMeter,
            gasConfiguration: .keyValue
        )
    }
    
    // TransientStore fetches a TransientStore from the MultiStore.
    public func transientStore(key: StoreKey) -> KeyValueStore {
        GasKeyValueStore(
            parent: multiStore.keyValueStore(key: key),
            gasMeter: gasMeter,
            gasConfiguration: .transient
        )
    }

    
    // CacheContext returns a new Context with the multi-store cached and a new
    // EventManager. The cached context is written to the context when writeCache
    // is called.
    @discardableResult
    func cacheContext() -> () -> Void {
        let commitMultiStore = multiStore.cacheMultiStore
        multiStore = commitMultiStore
        eventManager = EventManager()
        return commitMultiStore.write
    }

}
