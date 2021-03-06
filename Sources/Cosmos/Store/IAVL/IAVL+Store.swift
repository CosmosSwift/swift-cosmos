import Foundation
import ABCIMessages
import Database
import iAVLPlusCore


// Store Implements types.KVStore and CommitKVStore.
final class IAVLStore<Storage: NodeStorageProtocol>: KeyValueStore, CommitStore, CommitKeyValueStore, Queryable where Storage.Key == Data, Storage.Value == Data {
    static var defaultIAVLCacheSize : Int { 10000 }

//    typealias Node = NodeProtocol
    typealias Key = Storage.Key
    typealias Value = Storage.Value
    typealias Hasher = Storage.Hasher
    
    let tree: Storage

    // LoadStore returns an IAVL Store as a CommitKVStore. Internally, it will load the
    // store's version (id) from the provided DB. An error is returned if the version
    // fails to load.
    init(
        database: Storage,
        commitId: CommitID,
        isLazyLoadingEnabled: Bool
    ) throws {
        
        let tree = database
        // TODO: Implement
//        if lazyLoading {
//            try tree.lazyLoadVersion(id.version)
//        } else {
//            try tree.loadVersion(id.version)
//        }

        self.tree = tree
    }

    // UnsafeNewStore returns a reference to a new IAVL Store with a given mutable
    // IAVL tree reference. It should only be used for testing purposes.
    //
    // CONTRACT: The IAVL tree should be fully loaded.
    // CONTRACT: PruningOptions passed in as argument must be the same as pruning options
    // passed into iavl.MutableTree
    init(tree: Storage) {
        self.tree = tree
    }
}

extension IAVLStore {
//    // GetImmutable returns a reference to a new store backed by an immutable IAVL
//    // tree at a specific version (height) without any pruning options. This should
//    // be used for querying and iteration only. If the version does not exist or has
//    // been pruned, an error will be returned. Any mutable operations executed will
//    // result in a panic.
//    func (st *Store) GetImmutable(version int64) (*Store, error) {
//        if !st.VersionExists(version) {
//            return nil, iavl.ErrVersionDoesNotExist
//        }
//
//        iTree, err := st.tree.GetImmutable(version)
//        if err != nil {
//            return nil, err
//        }
//
//        return &Store{
//            tree: &immutableTree{iTree},
//        }, nil
//    }

    // Commit commits the current store state and returns a CommitID with the new
    // version and hash.
    func commit() throws -> CommitID {
        let versionToCommit = tree.version
        try tree.commit()
        
        return CommitID(
            version: versionToCommit,
            hash: Data(tree.root.hash)
        )
    }

    // Implements Committer.
    var lastCommitID: CommitID? {
        CommitID(
            version: tree.version,
            // TODO: Check this optionality
            hash: Data(tree.root.hash)
        )
    }

//    // SetPruning panics as pruning options should be provided at initialization
//    // since IAVl accepts pruning options directly.
//    func (st *Store) SetPruning(_ types.PruningOptions) {
//        panic("cannot set pruning options on an initialized IAVL store")
//    }
//
//    // VersionExists returns whether or not a given version is stored.
//    func (st *Store) VersionExists(version int64) bool {
//        return st.tree.VersionExists(version)
//    }

    // Implements Store.
    var storeType: StoreType {
        .iavlTree
    }

    // Implements Store.
    var cacheWrap: CacheWrap {
        BaseCacheKeyValueStore(parent: self)
    }

    // CacheWrapWithTrace implements the Store interface.
    func cacheWrapWithTrace(writer: Writer, traceContext: TraceContext) -> CacheWrap {
        // TODO: Implement
        fatalError()
//        let parent = TraceKeyValueStore(
//            store: self,
//            writer: writer,
//            traceContext: traceContext
//        )
//
//        return BaseCacheKeyValueStore(parent: parent)
    }

    // Implements types.KVStore.
    func set(key: Key, value: Value) {
        guard let _ = try? tree.set(key: key, value: value) else {
            fatalError("Failed setting {\(key):\(value)}")
        }
    }

    // Implements types.KVStore.
    func get(key: Key) -> Value? {
        if let (_, value) = try? tree.get(key: key) {
            return value
        }
        return nil
    }

    // Implements types.KVStore.
    func has(key: Key) -> Bool {
        if let _ = try? tree.has(key: key) {
            return true
        }
        return false
    }

    // Implements types.KVStore.
    func delete(key: Key) {
        tree.remove(key: key)
    }

//    // DeleteVersions deletes a series of versions from the MutableTree. An error
//    // is returned if any single version is invalid or the delete fails. All writes
//    // happen in a single batch with a single commit.
//    func (st *Store) DeleteVersions(versions ...int64) error {
//        return st.tree.DeleteVersions(versions...)
//    }


    // Implements types.KVStore.
    func iterator(start: Key, end: Key) -> Iterator {
        return IAVLIterator(tree, start, end, true)
        
        //var iTree: ImmutableTree

//        switch self.tree {
//        case let immutableTree as ImmutableTree:
//            iTree = immutableTree
//        case let mutableTree as MutableTree:
//            iTree = mutableTree
//        default:
//            break
//        }

        // TODO: Implement
        //fatalError()
//        return IAVLIterator(iTree, start, end, true)
    }

    // Implements types.KVStore.
    func reverseIterator(start: Key, end: Key) -> Iterator {
        return IAVLIterator(tree, start, end, false)
        // TODO: Implement
        //fatalError()
//        var iTree *iavl.ImmutableTree
//
//        switch tree := st.tree.(type) {
//        case *immutableTree:
//            iTree = tree.ImmutableTree
//        case *iavl.MutableTree:
//            iTree = tree.ImmutableTree
//        }
//
//        return newIAVLIterator(iTree, start, end, false)
    }

//    // Handle gatest the latest height, if height is 0
//    func getHeight(tree Tree, req abci.RequestQuery) int64 {
//        height := req.Height
//        if height == 0 {
//            latest := tree.Version()
//            if tree.VersionExists(latest - 1) {
//                height = latest - 1
//            } else {
//                height = latest
//            }
//        }
//        return height
//    }

    // Query implements ABCI interface, allows queries
    //
    // by default we will return from (latest height -1),
    // as we will have merkle proofs immediately (header height = data height + 1)
    // If latest-1 is not present, use latest (which must be present)
    // if you care to have the latest data to see a tx results, you must
    // explicitly set the height you want to see
    func query(queryRequest: RequestQuery<Data>) -> ResponseQuery<Data> {
        // TODO: Implement
        fatalError()
//        if len(req.Data) == 0 {
//            return sdkerrors.QueryResult(sdkerrors.Wrap(sdkerrors.ErrTxDecode, "query cannot be zero length"))
//        }
//
//        tree := st.tree
//
//        // store the height we chose in the response, with 0 being changed to the
//        // latest height
//        res.Height = getHeight(tree, req)
//
//        switch req.Path {
//        case "/key": // get by key
//            key := req.Data // data holds the key bytes
//
//            res.Key = key
//            if !st.VersionExists(res.Height) {
//                res.Log = iavl.ErrVersionDoesNotExist.Error()
//                break
//            }
//
//            if req.Prove {
//                value, proof, err := tree.GetVersionedWithProof(key, res.Height)
//                if err != nil {
//                    res.Log = err.Error()
//                    break
//                }
//                if proof == nil {
//                    // Proof == nil implies that the store is empty.
//                    if value != nil {
//                        panic("unexpected value for an empty proof")
//                    }
//                }
//                if value != nil {
//                    // value was found
//                    res.Value = value
//                    res.Proof = &merkle.Proof{Ops: []merkle.ProofOp{iavl.NewValueOp(key, proof).ProofOp()}}
//                } else {
//                    // value wasn't found
//                    res.Value = nil
//                    res.Proof = &merkle.Proof{Ops: []merkle.ProofOp{iavl.NewAbsenceOp(key, proof).ProofOp()}}
//                }
//            } else {
//                _, res.Value = tree.GetVersioned(key, res.Height)
//            }
//
//        case "/subspace":
//            var KVs []types.KVPair
//
//            subspace := req.Data
//            res.Key = subspace
//
//            iterator := types.KVStorePrefixIterator(st, subspace)
//            for ; iterator.Valid(); iterator.Next() {
//                KVs = append(KVs, types.KVPair{Key: iterator.Key(), Value: iterator.Value()})
//            }
//
//            iterator.Close()
//            res.Value = cdc.MustMarshalBinaryLengthPrefixed(KVs)
//
//        default:
//            return sdkerrors.QueryResult(sdkerrors.Wrapf(sdkerrors.ErrUnknownRequest, "unexpected query path: %v", req.Path))
//        }
//
//        return res
    }
//
//    //----------------------------------------
//
//    // Implements types.Iterator.
//    type iavlIterator struct {
//        // Domain
//        start, end []byte
//
//        key   []byte // The current key (mutable)
//        value []byte // The current value (mutable)
//
//        // Underlying store
//        tree *iavl.ImmutableTree
//
//        // Channel to push iteration values.
//        iterCh chan tmkv.Pair
//
//        // Close this to release goroutine.
//        quitCh chan struct{}
//
//        // Close this to signal that state is initialized.
//        initCh chan struct{}
//
//        mtx sync.Mutex
//
//        ascending bool // Iteration order
//
//        invalid bool // True once, true forever (mutable)
//    }
//
//    var _ types.Iterator = (*iavlIterator)(nil)
//
//    // newIAVLIterator will create a new iavlIterator.
//    // CONTRACT: Caller must release the iavlIterator, as each one creates a new
//    // goroutine.
//    func newIAVLIterator(tree *iavl.ImmutableTree, start, end []byte, ascending bool) *iavlIterator {
//        iter := &iavlIterator{
//            tree:      tree,
//            start:     types.Cp(start),
//            end:       types.Cp(end),
//            ascending: ascending,
//            iterCh:    make(chan tmkv.Pair), // Set capacity > 0?
//            quitCh:    make(chan struct{}),
//            initCh:    make(chan struct{}),
//        }
//        go iter.iterateRoutine()
//        go iter.initRoutine()
//        return iter
//    }
//
//    // Run this to funnel items from the tree to iterCh.
//    func (iter *iavlIterator) iterateRoutine() {
//        iter.tree.IterateRange(
//            iter.start, iter.end, iter.ascending,
//            func(key, value []byte) bool {
//                select {
//                case <-iter.quitCh:
//                    return true // done with iteration.
//                case iter.iterCh <- tmkv.Pair{Key: key, Value: value}:
//                    return false // yay.
//                }
//            },
//        )
//        close(iter.iterCh) // done.
//    }
//
//    // Run this to fetch the first item.
//    func (iter *iavlIterator) initRoutine() {
//        iter.receiveNext()
//        close(iter.initCh)
//    }
//
//    // Implements types.Iterator.
//    func (iter *iavlIterator) Domain() (start, end []byte) {
//        return iter.start, iter.end
//    }
//
//    // Implements types.Iterator.
//    func (iter *iavlIterator) Valid() bool {
//        iter.waitInit()
//        iter.mtx.Lock()
//
//        validity := !iter.invalid
//        iter.mtx.Unlock()
//        return validity
//    }
//
//    // Implements types.Iterator.
//    func (iter *iavlIterator) Next() {
//        iter.waitInit()
//        iter.mtx.Lock()
//        iter.assertIsValid(true)
//
//        iter.receiveNext()
//        iter.mtx.Unlock()
//    }
//
//    // Implements types.Iterator.
//    func (iter *iavlIterator) Key() []byte {
//        iter.waitInit()
//        iter.mtx.Lock()
//        iter.assertIsValid(true)
//
//        key := iter.key
//        iter.mtx.Unlock()
//        return key
//    }
//
//    // Implements types.Iterator.
//    func (iter *iavlIterator) Value() []byte {
//        iter.waitInit()
//        iter.mtx.Lock()
//        iter.assertIsValid(true)
//
//        val := iter.value
//        iter.mtx.Unlock()
//        return val
//    }
//
//    // Close closes the IAVL iterator by closing the quit channel and waiting for
//    // the iterCh to finish/close.
//    func (iter *iavlIterator) Close() {
//        close(iter.quitCh)
//        // wait iterCh to close
//        for range iter.iterCh {
//        }
//    }
//
//    // Error performs a no-op.
//    func (iter *iavlIterator) Error() error {
//        return nil
//    }
//
//    //----------------------------------------
//
//    func (iter *iavlIterator) setNext(key, value []byte) {
//        iter.assertIsValid(false)
//
//        iter.key = key
//        iter.value = value
//    }
//
//    func (iter *iavlIterator) setInvalid() {
//        iter.assertIsValid(false)
//
//        iter.invalid = true
//    }
//
//    func (iter *iavlIterator) waitInit() {
//        <-iter.initCh
//    }
//
//    func (iter *iavlIterator) receiveNext() {
//        kvPair, ok := <-iter.iterCh
//        if ok {
//            iter.setNext(kvPair.Key, kvPair.Value)
//        } else {
//            iter.setInvalid()
//        }
//    }
//
//    // assertIsValid panics if the iterator is invalid. If unlockMutex is true,
//    // it also unlocks the mutex before panicing, to prevent deadlocks in code that
//    // recovers from panics
//    func (iter *iavlIterator) assertIsValid(unlockMutex bool) {
//        if iter.invalid {
//            if unlockMutex {
//                iter.mtx.Unlock()
//            }
//            panic("invalid iterator")
//        }
//    }
}
