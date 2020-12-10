import Foundation
import Cosmos

// MsgSetName defines a SetName message
struct SetNameMessage: Codable, Message {
    let name: String
    let value: String
    let owner: AccountAddress

    // NewMsgSetName is a constructor function for MsgSetName
    init(name: String, value: String, owner: AccountAddress) {
        self.name = name
        self.value = value
        self.owner = owner
    }

    // Route should return the name of the module
    var route: String {
        routerKey
    }

    // Type should return the action
    var type: String {
        "set_name"
    }

    // ValidateBasic runs stateless checks on the message
    func validateBasic() throws {
        if owner.isEmpty {
            throw Cosmos.Error.invalidAddress(address: owner.string())
        }
        
        if name.isEmpty || value.isEmpty {
            throw Cosmos.Error.unknownRequest(reason: "Name and/or Value cannot be empty")
        }
    }

    // GetSignBytes encodes the message for signing
    func getSignBytes() -> Data {
        mustSortJSON(data: moduleCodec.mustMarshalJSON(value: self))
    }

    // GetSigners defines whose signature is required
    func getSigners() -> [AccountAddress] {
        [owner]
    }
}
