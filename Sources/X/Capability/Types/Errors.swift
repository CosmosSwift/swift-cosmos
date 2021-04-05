import Cosmos

// x/capability module sentinel errors
extension CosmosError {
    static let invalidCapabilityName    = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 2, description: "capability name not valid")
    static let nilCapability            = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 3, description: "provided capability is nil")
    static let capabilityTaken          = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 4, description: "capability name already taken")
    static let ownerClaimed             = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 5, description: "given owner already claimed capability")
    static let capabilityNotOwned       = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 6, description: "capability not owned by module")
    static let capabilityNotFound       = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 7, description: "capability not found")
    static let capabilityOwnersNotFound = CosmosError.register(codespace: CapabilityKeys.moduleName, code: 8, description: "owners not found for capability")
}

