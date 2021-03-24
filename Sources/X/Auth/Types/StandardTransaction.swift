import Foundation
import Tendermint
import Cosmos

// StdTx is a standard way to wrap a Msg with Fee and Signatures.
// NOTE: the first signature is the fee payer (Signatures must not be nil).
public struct StandardTransaction: Transaction {
    static public let metaType: MetaType = Self.metaType(key: "cosmos-sdk/StdTx")
    
    static public let maxGasWanted = UInt64((1 << 63) - 1)

    public let messages: [Message]
    public let fee: StandardFee
    public let signatures: [StandardSignature]
    public let memo: String
    
    
    private enum CodingKeys: String, CodingKey {
        case messages
        case fee
        case signatures
        case memo
    }
    
    public init(messages: [Message], fee: StandardFee, signatures: [StandardSignature], memo: String) {
        self.messages = messages
        self.fee = fee
        self.signatures = signatures
        self.memo = memo
    }
    
    public var encoded: Data? {
        return try? JSONEncoder().encode(self)
    }

    // TODO: Find a way to implement Codable for protocols, maybe make StandardTransaction generic?
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fee = try container.decode(StandardFee.self, forKey: .fee)
        
        let messagesCodable = try container.decode([AnyProtocolCodable].self, forKey: .messages)
        
        let messages = messagesCodable.compactMap { $0.value as? Message }
        
        self.messages = messages
        self.signatures = try container.decode([StandardSignature].self, forKey: .signatures)
        self.memo = try container.decode(String.self, forKey: .memo)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fee, forKey: .fee)
        let mgs = messages.map { AnyProtocolCodable($0)}
        try container.encode(mgs, forKey: .messages)
        try container.encode(signatures, forKey: .signatures)
        try container.encode(memo, forKey: .memo)
    }
    // ValidateBasic does a simple and lightweight validation check that doesn't
    // require access to any other information.
    public func validateBasic() throws {
        let standardSignatures = signatures

        if fee.gas > Self.maxGasWanted {
            throw Cosmos.Error.invalidRequest(reason: "invalid gas supplied; \(fee.gas) > \(Self.maxGasWanted)")
        }
        
        if standardSignatures.isEmpty {
            throw Cosmos.Error.noSignatures
        }
        
        if standardSignatures.count != signers.count {
            throw Cosmos.Error.unauthorized(reason: "wrong number of signers; expected \(signers.count), got \(standardSignatures.count)")
        }
    }
    
    // GetSigners returns the addresses that must sign the transaction.
    // Addresses are returned in a deterministic order.
    // They are accumulated from the GetSigners method for each Msg
    // in the order they appear in tx.GetMsgs().
    // Duplicate addresses will be omitted.
    var signers: [AccountAddress] {
        var seen: [String: Bool] = [:]
        var signers: [AccountAddress] = []
       
        for message in messages {
            for address in message.signers {
                if seen[address.description] == false {
                    signers.append(address)
                    seen[address.description] = true
                }
            }
        }
       
        return signers
    }
}

//__________________________________________________________



func standardSignBytes(chainID: String, accountNumber: UInt64, sequence: UInt64, fee: StandardFee, messages: [Message], memo: String) throws -> Data {
    
    var messagesBytes: [Data] = []
    for message in messages {
        #warning("This needs to be properly checked")
        messagesBytes.append(message.toSign)
    }
    
    let sigDoc = StandardSignatureDoc(accountNumber: accountNumber, chainID: chainID, fee: fee, memo: memo, messages: messagesBytes, sequence: sequence)
    
    return try JSONEncoder().encode(sigDoc)
    
    
//    // StdSignBytes returns the bytes to sign for a transaction.
//    func StdSignBytes(chainID string, accnum uint64, sequence uint64, fee StdFee, msgs []sdk.Msg, memo string) []byte {
//        msgsBytes := make([]json.RawMessage, 0, len(msgs))
//        for _, msg := range msgs {
//            msgsBytes = append(msgsBytes, json.RawMessage(msg.GetSignBytes()))
//        }
//        bz, err := ModuleCdc.MarshalJSON(StdSignDoc{
//            AccountNumber: accnum,
//            ChainID:       chainID,
//            Fee:           json.RawMessage(fee.Bytes()),
//            Memo:          memo,
//            Msgs:          msgsBytes,
//            Sequence:      sequence,
//        })
//        if err != nil {
//            panic(err)
//        }
//        return sdk.MustSortJSON(bz)
//    }
}


extension Auth {
    // DefaultTxDecoder logic for standard transaction decoding
    public static func defaultTransactionDecoder(codec: Codec) -> TransactionDecoder {
        return { transactionData in
            if transactionData.isEmpty {
                throw Cosmos.Error.transactionDecode(reason: "transaction data is empty")
            }

            // StdTx.Msg is an interface. The concrete types
            // are registered by MakeTxCodec
            do {
                let transaction: StandardTransaction = try codec.unmarshalBinaryLengthPrefixed(data: transactionData)
                return transaction
            } catch {
                throw Cosmos.Error.transactionDecode(reason: "\(error)")
            }
        }
    }
    
    public static func defaultTransactionEncoder(codec: Codec) -> TransactionEncoder {
        return { transaction in
            #warning("Do we need to handle more than StandardTransaction?")
            do {
                return try codec.marshalBinaryLengthPrefixed(value: transaction as! StandardTransaction)
            } catch {
                throw Cosmos.Error.transactionEncode(reason: "\(error)")
            }
        }
    }
}
