import Foundation
import Logging
import Cosmos

// Keeper defines the capability module's keeper. It is responsible for provisioning,
// tracking, and authenticating capabilities at runtime. During application
// initialization, the keeper can be hooked up to modules through unique function
// references so that it can identify the calling module when later invoked.
//
// When the initial state is loaded from disk, the keeper allows the ability to
// create new capability keys for all previously allocated capability identifiers
// (allocated during execution of past transactions and assigned to particular modes),
// and keep them in a memory-only store while the chain is running.
//
// The keeper allows the ability to create scoped sub-keepers which are tied to
// a single specific module.
public final class CapabilityKeeper {
    let codec: Codec
    let storeKey: StoreKey
    let inMemoryStoreKey: StoreKey
    var capabilities: [UInt64: Capability] = [:]
    var scopedModules: Set<String> = []
    var sealed: Bool = false
    
    // NewKeeper constructs a new CapabilityKeeper instance and initializes maps
    // for capability map and scopedModules map.
    init(codec: Codec, storeKey: StoreKey, inMemoryStoreKey: StoreKey) {
        self.codec = codec
        self.storeKey = storeKey
        self.inMemoryStoreKey = inMemoryStoreKey
    }
}

// ScopedKeeper defines a scoped sub-keeper which is tied to a single specific
// module provisioned by the capability keeper. Scoped keepers must be created
// at application initialization and passed to modules, which can then use them
// to claim capabilities they receive and retrieve capabilities which they own
// by name, in addition to creating new capabilities & authenticating capabilities
// passed by other modules.
public final class ScopedCapabilityKeeper {
    let codec: Codec // TODO: Use codec.BinaryMarshaler
    let storeKey: StoreKey
    let inMemoryStoreKey: StoreKey
    var capabilities: [UInt64: Capability]
    let module: String
    
    init(
        codec: Codec,
        storeKey: StoreKey,
        inMemoryStoreKey: StoreKey,
        capabilities: [UInt64 : Capability],
        module: String
    ) {
        self.codec = codec
        self.storeKey = storeKey
        self.inMemoryStoreKey = inMemoryStoreKey
        self.capabilities = capabilities
        self.module = module
    }
}

extension CapabilityKeeper {
    // ScopeToModule attempts to create and return a ScopedKeeper for a given module
    // by name. It will panic if the keeper is already sealed or if the module name
    // already has a ScopedKeeper.
    public func scope(to moduleName: String) -> ScopedCapabilityKeeper {
        guard !sealed else {
            fatalError("cannot scope to module via a sealed capability keeper")
        }
        
        guard !moduleName.trimmingCharacters(in: .whitespaces).isEmpty else {
            fatalError("cannot scope to an empty module name")
        }

        guard !scopedModules.contains(moduleName) else {
            fatalError("cannot create multiple scoped keepers for the same module name: \(moduleName)")
        }

        scopedModules.insert(moduleName)

        return ScopedCapabilityKeeper(
            codec: codec,
            storeKey: storeKey,
            inMemoryStoreKey: inMemoryStoreKey,
            capabilities: capabilities,
            module: moduleName
        )
    }

    // InitializeAndSeal loads all capabilities from the persistent KVStore into the
    // in-memory store and seals the keeper to prevent further modules from creating
    // a scoped keeper. InitializeAndSeal must be called once after the application
    // state is loaded.
    func initializeAndSeal(request: Request) {
        guard !sealed else {
            fatalError("cannot initialize and seal an already sealed capability keeper")
        }

        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)
        let inMemoryStoreType = inMemoryStore.storeType

        guard inMemoryStoreType == .inMemory else {
            fatalError("invalid memory store type; got \(inMemoryStoreType), expected: \(StoreType.inMemory)")
        }

        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        #warning("I'm unsure about this empty data prefix")
        var iterator = prefixStore.prefixIterator(prefix: Data())

        // initialize the in-memory store for all persisted capabilities
        defer {
            iterator.close()
        }
        
        while iterator.isValid {
            defer {
                iterator.next()
            }
            
            let index = CapabilityKeys.indexFromKey(key: iterator.key)
            let capabilityOwners: CapabilityOwners = codec.mustUnmarshalBinaryBare(data: iterator.value)
            
            initializeCapability(
                request: request,
                index: index,
                owners: capabilityOwners
            )
        }

        sealed = true
    }

    // InitializeIndex sets the index to one (or greater) in InitChain according
    // to the GenesisState. It must only be called once.
    // It will panic if the provided index is 0, or if the index is already set.
    func initializeIndex(request: Request, index: UInt64) throws {
        guard index > 0 else {
            fatalError("SetIndex requires index > 0")
        }
    
        let latest = latestIndex(request: request)
        
        guard latest == 0 else {
            fatalError("SetIndex requires index to not be set")
        }

        // set the global index to the passed index
        let store = request.keyValueStore(key: storeKey)
        store.set(key: CapabilityKeys.keyIndex, value: CapabilityKeys.indexToKey(index: index))
    }

    // GetLatestIndex returns the latest index of the CapabilityKeeper
    func latestIndex(request: Request) -> UInt64 {
        let store = request.keyValueStore(key: storeKey)
        
        guard let key = store.get(key: CapabilityKeys.keyIndex) else {
            return 0
        }
        
        return CapabilityKeys.indexFromKey(key: key)
    }

    // SetOwners set the capability owners to the store
    func setOwners(request: Request, index: UInt64, owners: CapabilityOwners) {
        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        let indexKey = CapabilityKeys.indexToKey(index: index)

        // set owners in persistent store
        prefixStore.set(
            key: indexKey,
            value: codec.mustMarshalBinaryBare(value: owners)
        )
    }

    // GetOwners returns the capability owners with a given index.
    func owners(request: Request, index: UInt64) -> CapabilityOwners? {
        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        let indexKey = CapabilityKeys.indexToKey(index: index)

        // get owners for index from persistent store
        guard let ownerData = prefixStore.get(key: indexKey) else {
            return nil
        }
        
        return codec.mustUnmarshalBinaryBare(data: ownerData)
    }

    // InitializeCapability takes in an index and an owners array. It creates the capability in memory
    // and sets the fwd and reverse keys for each owner in the memstore.
    // It is used during initialization from genesis.
    func initializeCapability(request: Request, index: UInt64, owners: CapabilityOwners) {
        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)
        let capability = Capability(index: index)
        
        for owner in owners.owners {
            // Set the forward mapping between the module and capability tuple and the
            // capability name in the memKVStore
            inMemoryStore.set(
                key: CapabilityKeys.forwardCapabilityKey(module: owner.module, capability: capability),
                value: owner.name.data
            )

            // Set the reverse mapping between the module and capability name and the
            // index in the in-memory store. Since marshalling and unmarshalling into a store
            // will change memory address of capability, we simply store index as value here
            // and retrieve the in-memory pointer to the capability from our map
            inMemoryStore.set(
                key: CapabilityKeys.reverseCapabilityKey(module: owner.module, name: owner.name),
                // TODO: Check if .data takes endianess into account. Should encode big endian.
                value: index.data
            )

            // Set the mapping from index from index to in-memory capability in the go map
            capabilities[index] = capability
        }

    }
}

extension ScopedCapabilityKeeper {
    // NewCapability attempts to create a new capability with a given name. If the
    // capability already exists in the in-memory store, an error will be returned.
    // Otherwise, a new capability is created with the current global unique index.
    // The newly created capability has the scoped module name and capability name
    // tuple set as the initial owner. Finally, the global index is incremented along
    // with forward and reverse indexes set in the in-memory store.
    //
    // Note, namespacing is completely local, which is safe since records are prefixed
    // with the module name and no two ScopedKeeper can have the same module name.
    func makeCapability(request: Request, name: String) throws -> Capability {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CosmosError.wrap(
                error: CapabilityError.invalidCapabilityName,
                description: "capability name cannot be empty"
            )
        }
        
        let store = request.keyValueStore(key: storeKey)

        guard capability(name: name, request: request) == nil else {
            throw CosmosError.wrap(
                error: CapabilityError.capabilityTaken,
                description: "module: \(module), name: \(name)"
            )
        }

        // create new capability with the current global index
        guard let key = store.get(key: CapabilityKeys.keyIndex) else {
            #warning("It's not clear from the go code what should we do here. Throw or fatalError?")
            fatalError()
        }
        
        let index = CapabilityKeys.indexFromKey(key: key)
        let capability = Capability(index: index)

        // update capability owner set
        try addOwner(
            capability: capability,
            name: name,
            request: request
        )

        // increment global index
        store.set(
            key: CapabilityKeys.keyIndex,
            value: CapabilityKeys.indexToKey(index: index + 1)
        )

        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)

        // Set the forward mapping between the module and capability tuple and the
        // capability name in the memKVStore
        inMemoryStore.set(
            key: CapabilityKeys.forwardCapabilityKey(module: module, capability: capability),
            value: name.data
        )

        // Set the reverse mapping between the module and capability name and the
        // index in the in-memory store. Since marshalling and unmarshalling into a store
        // will change memory address of capability, we simply store index as value here
        // and retrieve the in-memory pointer to the capability from our map
        #warning("TODO: Make sure .data returns big endian")
        inMemoryStore.set(
            key: CapabilityKeys.reverseCapabilityKey(module: module, name: name),
            value: index.data
        )

        // Set the mapping from index from index to in-memory capability in the go map
        capabilities[index] = capability
        
        log(
            level: .info,
            message: "created new capability\nmodule: \(module)\nname: \(name)",
            request: request
        )
        
        return capability
    }

    // AuthenticateCapability attempts to authenticate a given capability and name
    // from a caller. It allows for a caller to check that a capability does in fact
    // correspond to a particular name. The scoped keeper will lookup the capability
    // from the internal in-memory store and check against the provided name. It returns
    // true upon success and false upon failure.
    //
    // Note, the capability's forward mapping is indexed by a string which should
    // contain its unique memory reference.
    public func authenticate(capability: Capability, name: String, request: Request) -> Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        
        return self.name(capability: capability, request: request) == name
    }

    // ClaimCapability attempts to claim a given Capability. The provided name and
    // the scoped module's name tuple are treated as the owner. It will attempt
    // to add the owner to the persistent set of capability owners for the capability
    // index. If the owner already exists, it will return an error. Otherwise, it will
    // also set a forward and reverse index for the capability and capability name.
    public func claim(capability: Capability, name: String, request: Request) throws {
        #warning("Capability can't ever be nil")
//        if cap == nil {
//            return sdkerrors.Wrap(types.ErrNilCapability, "cannot claim nil capability")
//        }

        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CosmosError.wrap(
                error: CapabilityError.invalidCapabilityName,
                description: "capability name cannot be empty"
            )
        }
        
        // update capability owner set
        try addOwner(capability: capability, name: name, request: request)
        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)

        // Set the forward mapping between the module and capability tuple and the
        // capability name in the memKVStore
        inMemoryStore.set(
            key: CapabilityKeys.forwardCapabilityKey(module: module, capability: capability),
            value: name.data
        )

        // Set the reverse mapping between the module and capability name and the
        // index in the in-memory store. Since marshalling and unmarshalling into a store
        // will change memory address of capability, we simply store index as value here
        // and retrieve the in-memory pointer to the capability from our map
        // TODO: Make sure conversion from UInt64 to Data in `capability.index.data` uses big endian.
        inMemoryStore.set(
            key: CapabilityKeys.reverseCapabilityKey(module: module, name: name),
            value: capability.index.data
        )
       
        log(
            level: .info,
            message: "claimed capability. module: \(module), name: \(name), capability: \(capability.index)",
            request: request
        )
    }

    // ReleaseCapability allows a scoped module to release a capability which it had
    // previously claimed or created. After releasing the capability, if no more
    // owners exist, the capability will be globally removed.
    func release(capability: Capability, request: Request) throws {
        #warning("Capability can't ever be nil")
//        if cap == nil {
//            return sdkerrors.Wrap(types.ErrNilCapability, "cannot release nil capability")
//        }
        
        guard let name = name(capability: capability, request: request) else {
             throw CosmosError.wrap(
                error: CapabilityError.capabilityNotOwned,
                description: module
             )
        }

        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)

        // Delete the forward mapping between the module and capability tuple and the
        // capability name in the memKVStore
        inMemoryStore.delete(
            key: CapabilityKeys.forwardCapabilityKey(module: module, capability: capability)
        )

        // Delete the reverse mapping between the module and capability name and the
        // index in the in-memory store.
        inMemoryStore.delete(
            key: CapabilityKeys.reverseCapabilityKey(module: module, name: name)
        )

        // remove owner
        var capabilityOwners = owners(capability: capability, request: request)
        capabilityOwners.remove(owner: Owner(module: module, name: name))

        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        let indexKey = CapabilityKeys.indexToKey(index: capability.index)

        if capabilityOwners.owners.isEmpty {
            // remove capability owner set
            prefixStore.delete(key: indexKey)
            // since no one owns capability, we can delete capability from map
            capabilities[capability.index] = nil
        } else {
            // update capability owner set
            prefixStore.set(
                key: indexKey,
                value: codec.mustMarshalBinaryBare(value: capabilityOwners)
            )
        }
    }

    // GetCapability allows a module to fetch a capability which it previously claimed
    // by name. The module is not allowed to retrieve capabilities which it does not
    // own.
    public func capability(name: String, request: Request) -> Capability? {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        
        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)

        let key = CapabilityKeys.reverseCapabilityKey(module: module, name: name)
        let indexData = inMemoryStore.get(key: key)!
        // TODO: Check if UInt64.init takes endianess into account. Should decode big endian.
        let index = UInt64(data: indexData)!

        guard !indexData.isEmpty else {
            // If a tx failed and NewCapability got reverted, it is possible
            // to still have the capability in the go map since changes to
            // go map do not automatically get reverted on tx failure,
            // so we delete here to remove unnecessary values in map
            // TODO: Delete index correctly from capMap by storing some reverse lookup
            // in-memory map. Issue: https://github.com/cosmos/cosmos-sdk/issues/7805
            return nil
        }

        guard let capability = capabilities[index] else {
            fatalError("capability found in memstore is missing from map")
        }

        return capability
    }

    // GetCapabilityName allows a module to retrieve the name under which it stored a given
    // capability given the capability
    func name(capability: Capability, request: Request) -> String? {
        let inMemoryStore = request.keyValueStore(key: inMemoryStoreKey)
        
        return inMemoryStore.get(
            key: CapabilityKeys.forwardCapabilityKey(
                module: module,
                capability: capability
            )
        )?.string
    }

    // GetOwners all the Owners that own the capability associated with the name this ScopedKeeper uses
    // to refer to the capability
    func owners(name: String, request: Request) -> CapabilityOwners? {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        
        guard let capability = capability(name: name, request: request) else {
            return nil
        }

        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        let indexKey = CapabilityKeys.indexToKey(index: capability.index)

        guard let data = prefixStore.get(key: indexKey) else {
            return nil
        }

        return codec.mustUnmarshalBinaryBare(data: data)
    }

    // LookupModules returns all the module owners for a given capability
    // as a string array and the capability itself.
    // The method returns an error if either the capability or the owners cannot be
    // retreived from the memstore.
    func lookupModules(name: String, request: Request) throws -> ([String], Capability) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CosmosError.wrap(
                error: CapabilityError.invalidCapabilityName,
                description: "cannot lookup modules with empty capability name"
            )
        }
        
        guard let capability = capability(name: name, request: request) else {
            throw CosmosError.wrap(
                error: CapabilityError.capabilityNotFound,
                description: name
            )
        }

        guard let capabilityOwners = owners(name: name, request: request) else {
            throw CosmosError.wrap(
                error: CapabilityError.capabilityOwnersNotFound,
                description: name
            )
        }

        let modules = capabilityOwners.owners.map(\.module)
        return (modules, capability)
    }

    private func addOwner(capability: Capability, name: String, request: Request) throws {
        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        let indexKey = CapabilityKeys.indexToKey(index: capability.index)

        var capabilityOwners = owners(capability: capability, request: request)
        try capabilityOwners.set(owner: Owner(module: module, name: name))

        // update capability owner set
        prefixStore.set(
            key: indexKey,
            value: codec.mustMarshalBinaryBare(value: capabilityOwners)
        )
    }

    func owners(capability: Capability, request: Request) -> CapabilityOwners {
        let prefixStore = PrefixStore(
            parent: request.keyValueStore(key: storeKey),
            prefix: CapabilityKeys.keyPrefixIndexCapability
        )
        
        let indexKey = CapabilityKeys.indexToKey(index: capability.index)
        
        guard let data = prefixStore.get(key: indexKey) else {
            return CapabilityOwners()
        }

        return codec.mustUnmarshalBinaryBare(data: data)
    }

    func log(level: Logger.Level, message: Logger.Message, request: Request) {
        request.logger.log(level: level, message, metadata: ["module": "x/\(CapabilityKeys.moduleName)"])
    }
}
