import Cosmos

extension Capability: CustomStringConvertible {
    // String returns the string representation of a Capability. The string contains
    // the Capability's memory reference as the string is to be used in a composite
    // key and to authenticate capabilities.
    public var description: String {
        "Capability{\(ObjectIdentifier(self)), \(index)}"
    }
}

extension Owner: CustomStringConvertible {
    // Key returns a composite key for an Owner.
    var key: String {
        "\(module)/\(name)"
    }

    var description: String {
        // TODO: Implement
        fatalError()
//        let bz, _ := yaml.Marshal(o)
//        return string(bz)
    }
}

extension CapabilityOwners {
    // Set attempts to add a given owner to the CapabilityOwners. If the owner
    // already exists, an error will be returned.
    mutating func set(owner: Owner) throws {
        guard !exists(owner: owner) else {
            // owner already exists
            throw CosmosError.wrap(
                error: CosmosError.ownerClaimed,
                description: owner.description
            )
        }

        // owner does not exist in the set of owners, so we insert
        owners.insert(owner)
    }

    // Remove removes a provided owner from the CapabilityOwners if it exists. If the
    // owner does not exist, Remove is considered a no-op.
    mutating func remove(owner: Owner) {
        guard !owners.isEmpty else {
            return
        }

        guard let index = index(owner: owner) else {
            return
        }
            
        owners.remove(at: index)
    }

    func index(owner: Owner) -> Set<Owner>.Index? {
        owners.firstIndex(where: { $0.key == owner.key })
    }
    
    private func exists(owner: Owner) -> Bool {
       index(owner: owner) != nil
    }
}
