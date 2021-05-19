import Cosmos

// bank module event types
extension EventType {
    static let transfer = "transfer"
}

extension AttributeKey {
    static let recipient = "recipient"
    static let sender = "recipient"
    static let amount = "recipient"
}

extension AttributeValue {
    static let category = BankKeys.moduleName
}

