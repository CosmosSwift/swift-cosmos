extension CapabilityGenesisState {
    // DefaultIndex is the default capability global index
    static let defaultIndex: UInt64 = 1
    
    // DefaultGenesis returns the default Capability genesis state
    static let `default` = CapabilityGenesisState(
        index: defaultIndex,
        owners: []
    )
    
    // Validate performs basic genesis state validation returning an error upon any
    // failure.
    func validate() throws {
        struct ValidationError: Error, CustomStringConvertible {
            let description: String
        }
        
        // NOTE: index must be greater than 0
        guard index > 0 else {
            throw ValidationError(description: "capability index must be non-zero")
        }

        for genesisOwner in owners {
            guard !genesisOwner.indexOwners.owners.isEmpty else {
                throw ValidationError(description: "empty owners in genesis")
            }

            // all exported existing indices must be between [1, gs.Index)
            guard genesisOwner.index != 0 && genesisOwner.index < index else {
                throw ValidationError(
                    description: "owners exist for index \(genesisOwner.index) outside of valid range: \(1)-\(index - 1)"
                )
            }

            for owner in genesisOwner.indexOwners.owners {
                guard !owner.module.trimmingCharacters(in: .whitespaces).isEmpty else {
                    throw ValidationError(description: "owner's module cannot be blank: \(owner)")
                }

                guard !owner.name.trimmingCharacters(in: .whitespaces).isEmpty else {
                    throw ValidationError(description: "owner's name cannot be blank: \(owner)")
                }
            }
        }
    }
}


