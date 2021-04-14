import CosmosProto

// GenesisState defines the capability module's genesis state.
struct CapabilityGenesisState: Codable {
    // index is the capability global index.
    let index: UInt64
    // owners represents a map from index to owners of the capability index
    // index key is string to allow amino marshalling.
    let owners: [GenesisOwners]
}

// GenesisOwners defines the capability owners with their corresponding index.
struct GenesisOwners: Codable {
    // index is the index of the capability owner.
    let index: UInt64
    // index_owners are the owners at the given index.
    let indexOwners: CapabilityOwners
    
    private enum CodingKeys: String, CodingKey {
        case index
        case indexOwners = "index_owners"
    }
}
