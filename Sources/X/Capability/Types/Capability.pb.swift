/*

TODO: substitute with the relevant proto generated file

*/

import CosmosProto

// Capability defines an implementation of an object capability. The index
// provided to a Capability must be globally unique.
public class Capability: Codable {
    let index: UInt64
    
    // NewCapability returns a reference to a new Capability to be used as an
    // actual capability.
    init(index: UInt64) {
        self.index = index
    }
}

extension Capability {
    convenience init(_ capability: Cosmos_Capability_V1beta1_Capability) {
        self.init(index: capability.index)
    }
}

extension Cosmos_Capability_V1beta1_Capability {
    init(_ capability: Capability) {
        self.init()
        self.index = capability.index
    }
}

// CapabilityOwners defines a set of owners of a single Capability. The set of
// owners must be unique.
struct CapabilityOwners: Codable, Hashable {
    var owners: Set<Owner> = []
}

extension CapabilityOwners {
    init(_ capabilityOwners: Cosmos_Capability_V1beta1_CapabilityOwners) {
        self.owners = Set(capabilityOwners.owners.map(Owner.init))
    }
}

extension Cosmos_Capability_V1beta1_CapabilityOwners {
    init(_ capabilityOwners: CapabilityOwners) {
        self.init()
        self.owners = capabilityOwners.owners.map(Cosmos_Capability_V1beta1_Owner.init)
    }
}

// Owner defines a single capability owner. An owner is defined by the name of
// capability and the module name.
struct Owner: Codable, Hashable {
    let module: String
    let name: String
}

extension Owner {
    init(_ owner: Cosmos_Capability_V1beta1_Owner) {
        self.module = owner.module
        self.name = owner.name
    }
}

extension Cosmos_Capability_V1beta1_Owner {
    init(_ owner: Owner) {
        self.init()
        self.module = owner.module
        self.name = owner.name
    }
}

