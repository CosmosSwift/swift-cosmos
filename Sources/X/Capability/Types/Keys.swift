import Foundation

enum CapabilityKeys {
    // ModuleName defines the module name
    static let moduleName = "capability"

    // StoreKey defines the primary module store key
    static let storeKey = moduleName

    // MemStoreKey defines the in-memory store key
    static let inMemoryStoreKey = "mem_capability"
}

extension CapabilityKeys {
    // KeyIndex defines the key that stores the current globally unique capability
    // index.
    static let keyIndex = "index".data

    // KeyPrefixIndexCapability defines a key prefix that stores index to capability
    // name mappings.
    static let keyPrefixIndexCapability = "capability_index".data
}

extension CapabilityKeys {
    // RevCapabilityKey returns a reverse lookup key for a given module and capability
    // name.
    static func reverseCapabilityKey(module: String, name: String) -> Data {
        "\(module)/rev/\(name)".data
    }

    // FwdCapabilityKey returns a forward lookup key for a given module and capability
    // reference.
    static func forwardCapabilityKey(module: String, capability: Capability) -> Data {
        // TODO: Capability is a reference type and the key uses its address as an identifier.
        "\(module)/fwd/\(ObjectIdentifier(capability))".data
    }
    
    // IndexToKey returns bytes to be used as a key for a given capability index.
    static func indexToKey(index: UInt64) -> Data {
        // TODO: Make sure conversio is big endian.
        index.data
    }
    
    // IndexFromKey returns an index from a call to IndexToKey for a given capability
    // index.
    static func indexFromKey(key: Data) -> UInt64 {
        UInt64(data: key)!
    }
}
