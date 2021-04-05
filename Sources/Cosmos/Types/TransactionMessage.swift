import Foundation
import Tendermint

// StdFee includes the amount of coins paid in fees and the maximum
// gas to be used by the transaction. The ratio yields an effective "gasprice",
// which must be above some miminum to be accepted into the mempool.
public struct StandardFee {
    public let amount: Coins
    public let gas: UInt64
    
    public init(amount: Coins, gas: UInt64) {
        self.amount = amount
        self.gas = gas
    }
}

extension StandardFee: Codable {}


// StdSignature represents a sig
public struct StandardSignature {
    public let publicKey: PublicKeyProtocol? // TODO: not sure when this can be nil. the Go code specifies this s optional.
    public let signature: Data
    
    private enum CodingKeys: String, CodingKey {
        case publicKey = "pubkey"
        case signature
    }
    
    public init(publicKey: PublicKeyProtocol, signature: Data) {
        self.publicKey = publicKey
        self.signature = signature
    }
}

extension StandardSignature: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let publicKeyCodable = try container.decodeIfPresent(AnyProtocolCodable.self, forKey: .publicKey)
        
        guard let publicKey = publicKeyCodable?.value as? PublicKeyProtocol else {
            throw DecodingError.dataCorruptedError(
                forKey: .publicKey,
                in: container,
                debugDescription: "Invalid public key type"
            )
        }
        
        self.publicKey = publicKey
        self.signature = try container.decode(Data.self, forKey: .signature)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let publicKey = self.publicKey {
            try container.encode(AnyProtocolCodable(publicKey), forKey: .publicKey)
        }
        try container.encode(signature, forKey: .signature)
    }
}


// StdSignDoc is replay-prevention structure.
// It includes the result of msg.GetSignBytes(),
// as well as the ChainID (prevent cross chain replay)
// and the Sequence numbers for each signature (prevent
// inchain replay and enforce tx ordering per account).
public struct StandardSignatureDoc {
    let accountNumber: UInt64
    let chainID: String
    let fee: StandardFee // json.RawMessage
    let memo: String
    let messages: [Data] // json.RawMessage
    let sequence: UInt64
    
    private enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case chainID = "chain_id"
        case fee
        case memo
        case messages = "msgs"
        case sequence
    }
    
    public init(accountNumber: UInt64, chainID: String, fee: StandardFee, memo: String, messages: [Data], sequence: UInt64) {
        self.accountNumber = accountNumber
        self.chainID = chainID
        self.fee = fee
        self.memo = memo
        self.messages = messages
        self.sequence = sequence
    }
}


extension StandardSignatureDoc: Codable {
    
}

/*
 // StdSignDoc is replay-prevention structure.
 // It includes the result of msg.GetSignBytes(),
 // as well as the ChainID (prevent cross chain replay)
 // and the Sequence numbers for each signature (prevent
 // inchain replay and enforce tx ordering per account).
 type StdSignDoc struct {
     AccountNumber uint64            `json:"account_number" yaml:"account_number"`
     ChainID       string            `json:"chain_id" yaml:"chain_id"`
     Fee           json.RawMessage   `json:"fee" yaml:"fee"`
     Memo          string            `json:"memo" yaml:"memo"`
     Msgs          []json.RawMessage `json:"msgs" yaml:"msgs"`
     Sequence      uint64            `json:"sequence" yaml:"sequence"`
 }

 // StdSignBytes returns the bytes to sign for a transaction.
 func StdSignBytes(chainID string, accnum uint64, sequence uint64, fee StdFee, msgs []sdk.Msg, memo string) []byte {
     msgsBytes := make([]json.RawMessage, 0, len(msgs))
     for _, msg := range msgs {
         msgsBytes = append(msgsBytes, json.RawMessage(msg.GetSignBytes()))
     }
     bz, err := ModuleCdc.MarshalJSON(StdSignDoc{
         AccountNumber: accnum,
         ChainID:       chainID,
         Fee:           json.RawMessage(fee.Bytes()),
         Memo:          memo,
         Msgs:          msgsBytes,
         Sequence:      sequence,
     })
     if err != nil {
         panic(err)
     }
     return sdk.MustSortJSON(bz)
 }
 */












// Transactions messages must fulfill the `Message`
public protocol Message: ProtocolCodable {
    // Return the message type.
    // Must be alphanumeric or empty.
    var route: String { get }

    // Returns a human-readable string for the message, intended for utilization
    // within tags
    var type: String { get }

    // ValidateBasic does a simple validation check that
    // doesn't require access to any other information.
    func validateBasic() throws

    // Get the canonical byte representation of the Msg.
    var toSign: Data { get }

    // Returns the addresses of signers that must sign.
    // CONTRACT: All signatures must be present to be valid.
    // CONTRACT: Returns addrs in some deterministic order.
    var signers: [AccountAddress] { get }
}

//__________________________________________________________

// Transactions objects must fulfill the Tx
public protocol Transaction: ProtocolCodable {
    
    
    init(messages: [Message], fee: StandardFee, signatures: [StandardSignature], memo: String)
    
    var encoded: Data? { get }
    
    // Gets the all the transaction's messages.
    var messages: [Message] { get }

    // ValidateBasic does a simple and lightweight validation check that doesn't
    // require access to any other information.
    func validateBasic() throws
    
}

//__________________________________________________________

// TxDecoder unmarshals transaction bytes
public typealias TransactionDecoder = (_ transactionBytes: Data) throws -> Transaction

// TxEncoder marshals transaction to bytes
public typealias TransactionEncoder = (_ transaction: Transaction) throws -> Data
