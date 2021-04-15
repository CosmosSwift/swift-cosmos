import Database

// Store implements an in-memory only KVStore. Entries are persisted between
// commits and thus between blocks. State in Memory store is not committed as part of app state but maintained privately by each node
final class InMemoryStore: DatabaseAdapterStore, CommitKeyValueStore {
    init() {
        super.init(database: InMemoryDatabase())
    }
    
    // GetStoreType returns the Store's type.
    override var storeType: StoreType {
        .inMemory
    }
    
    // CacheWrap branches the underlying store.
    override var cacheWrap: CacheWrap {
        #warning("I'm not sure this is the correct type we should be returning here.")
        return BaseCacheKeyValueStore(parent: self)
    }
    
    // CacheWrapWithTrace implements KVStore.
    override func cacheWrapWithTrace(writer: Writer, traceContext: TraceContext) -> CacheWrap {
        #warning("TODO: Implement TraceKeyValueStore")
        fatalError()
//        BaseCacheKeyValueStore(parent: TraceKeyValueStore())
    }
    
    // Commit performs a no-op as entries are persistent between commitments.
    func commit() throws -> CommitID {
        #warning("Maybe we should return nil here?")
        return CommitID()
    }
    
    #warning("TODO: Implement")
//    func (s *Store) SetPruning(pruning types.PruningOptions) {}

    #warning("TODO: Implement")
    // GetPruning is a no-op as pruning options cannot be directly set on this store.
    // They must be set on the root commit multi-store.
//    func (s *Store) GetPruning() types.PruningOptions { return types.PruningOptions{} }

    var lastCommitID: CommitID? {
        nil
    }
}
