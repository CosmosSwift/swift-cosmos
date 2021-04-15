import Cosmos

extension CapabilityKeeper {
    // InitGenesis initializes the capability module's state from a provided genesis
    // state.
    func initGenesis(request: Request, state: CapabilityGenesisState) {
        try! initializeIndex(request: request, index: state.index)

        // set owners for each index and initialize capability
        for genesisOwner in state.owners {
            setOwners(
                request: request,
                index: genesisOwner.index,
                owners: genesisOwner.indexOwners
            )
            
            initializeCapability(
                request: request,
                index: genesisOwner.index,
                owners: genesisOwner.indexOwners
            )
        }
    }

    // ExportGenesis returns the capability module's exported genesis.
    func exportGenesis(request: Request) -> CapabilityGenesisState {
        let index = latestIndex(request: request)
        var owners: [GenesisOwners] = []

        for i in 1 ..< index {
            guard let capabilityOwners = self.owners(request: request, index: i) else {
                continue
            }
            
            guard !capabilityOwners.owners.isEmpty else {
                continue
            }

            let genesisOwner = GenesisOwners(
                index: i,
                indexOwners: capabilityOwners
            )
            
            owners.append(genesisOwner)
        }

        return CapabilityGenesisState(
            index: index,
            owners: owners
        )
    }
}
