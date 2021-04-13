import Foundation
import Tendermint
import ABCIMessages

// GasInfo defines tx execution gas context.
struct GasInfo: Codable {
    // GasWanted is the maximum units of work we allow this tx to perform.
    let gasWanted: UInt64

    // GasUsed is the amount of gas actually consumed.
    let gasUsed: UInt64
    
    internal init(gasWanted: UInt64 = 0, gasUsed: UInt64 = 0) {
        self.gasWanted = gasWanted
        self.gasUsed = gasUsed
    }
}

// Result is the union of ResponseFormat and ResponseCheckTx.
public struct Result: Codable {
    // Data is any data returned from message or handler execution. It MUST be length
    // prefixed in order to separate data from multiple message executions.
    let data: Data

    // Log contains the log information from message or handler execution.
    let log: String

    // Events contains a slice of Event objects that were emitted during message or
    // handler execution.
    let events: Events
    
    public init(
        data: Data = Data(),
        log: String = "",
        events: Events = []
    ) {
        self.data = data
        self.log = log
        self.events = events
    }
}

// SimulationResponse defines the response generated when a transaction is successfully
// simulated by the Baseapp.
struct SimulationResponse: Codable {
    let gasInfo: GasInfo
    let result: Result
}

// ABCIMessageLogs represents a slice of ABCIMessageLog.
typealias ABCIMessageLogs = [ABCIMessageLog]

// ABCIMessageLog defines a structure containing an indexed tx ABCI message log.
struct ABCIMessageLog: Codable, CustomStringConvertible {
    let messageIndex: UInt16
    let log: String

    // Events contains a slice of Event objects that were emitted during some
    // execution.
    let events: StringEvents
    
    internal init(messageIndex: UInt16, log: String, events: Events) {
        self.messageIndex = messageIndex
        self.log = log
        self.events = events.stringify()
    }
    
    // String implements the fmt.Stringer interface for the ABCIMessageLogs type.
    var description: String {
        // TODO: Implement
        guard let data = try? JSONEncoder().encode(self) else {
            return ""
        }
        return String(data: data, encoding: .utf8) ?? ""
//        if logs != nil {
//            raw, err := codec.Cdc.MarshalJSON(logs)
//            if err == nil {
//                str = string(raw)
//            }
//        }
//
//        return str
    }
}


public struct TransactionResponse : Codable  {
    let txHash: Data
    let code: UInt32
    let log: String
    
    var isEmpty: Bool {
        // TODO: model this better
        txHash == Data() && log == ""
    }
    
    private let state: TransactionState
    
    enum CodingKeys: String, CodingKey {
        case height
        case txHash = "txhash"
        case codespace
        case code
        case data
        case rawLog = "raw_log"
        case logs // TODO: in go, there is a "parsedLog" item. not sure if we need it
        case info
        case gasWanted = "gas_wanted"
        case gasUsed = "gas_used"
        case tx
        case timestamp
    }
    
    init(_ code: UInt32, _ hash: Data, _ log: String = "") {
        self.code = code
        self.txHash = hash
        self.log = log
        self.state = .broadcast
    }
    
    public init(_ result: Tendermint.TransactionResponse, _ transaction: TransactionBytes, _ timestamp: Date) {
        self.txHash = result.hash
        self.code = result.transactionResult.code
        self.log = result.transactionResult.log
        self.state = .completed(
            result.height,
            result.transactionResult.codespace,
            result.transactionResult.data,
            result.transactionResult.info,
            result.transactionResult.gasWanted,
            result.transactionResult.gasUsed,
            transaction,
            timestamp
        )
    }
    
    init(_ result: Tendermint.BroadcastTransactionResponse) {
        self.txHash = result.hash
        self.code = result.code
        self.log = result.log
        self.state = .broadcast
        
    }
    
    init(_ result: Tendermint.BroadcastTransactionCommitResponse) {
        self.txHash = result.hash
        if result.checkTransaction.code != 0 {
            // TODO: checking that the checkTx is ok is a crappy way to check that the TX has completed the check process
            self.code = result.checkTransaction.code
            self.log = result.checkTransaction.log
            self.state = .processed(
                result.height,
                result.checkTransaction.codespace,
                result.checkTransaction.data,
                result.checkTransaction.info,
                result.checkTransaction.gasWanted,
                result.checkTransaction.gasUsed
            )
        } else {
            self.code = result.deliverTransaction.code
            self.log = result.deliverTransaction.log
            self.state = .processed(
                result.height,
                result.deliverTransaction.codespace,
                result.deliverTransaction.data,
                result.deliverTransaction.info,
                result.deliverTransaction.gasWanted,
                result.deliverTransaction.gasUsed
            )
        }
    }
    
    init(transactionResponse: Tendermint.TransactionResponse, transaction: TransactionBytes, timestamp: Date) {
        self.txHash = transactionResponse.hash
        self.code = transactionResponse.transactionResult.code
        self.log = transactionResponse.transactionResult.log
        self.state = .completed(
            transactionResponse.height,
            transactionResponse.transactionResult.codespace,
            transactionResponse.transactionResult.data,
            transactionResponse.transactionResult.info,
            transactionResponse.transactionResult.gasWanted,
            transactionResponse.transactionResult.gasUsed,
            transaction,
            timestamp
        )
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.txHash = try values.decode(Data.self, forKey: .txHash)
        self.code = try values.decode(UInt32.self, forKey: .code)
        self.log = try values.decode(String.self, forKey: .rawLog)
        // TODO: properly decode
        
        #warning("Not sure if propertywrapper is applied here or not!")
        let height = try values.decodeIfPresent(Int64.self, forKey: .height)
        let codespace = try values.decodeIfPresent(String.self, forKey: .codespace)
        let data = try values.decodeIfPresent(Data.self, forKey: .data)
        let info = try values.decodeIfPresent(String.self, forKey: .info)
        let gasWanted = try values.decodeIfPresent(Int64.self, forKey: .gasWanted)
        let gasUsed = try values.decodeIfPresent(Int64.self, forKey: .gasUsed)
        
        let transaction = try values.decodeIfPresent(TransactionBytes.self, forKey: .tx)
        let timestamp = try values.decodeIfPresent(Date.self, forKey: .timestamp)

        if let h = height, let cs = codespace, let d = data, let i = info, let gw = gasWanted, let gu = gasUsed {
            if let tx = transaction, let t = timestamp {
                self.state = .completed(h, cs, d, i, gw, gu, tx, t)
            } else {
                self.state = .processed(h, cs, d, i, gw, gu)
            }
        } else {
            self.state = .broadcast //try values.decode(Data.self, forKey: .rawLog)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(txHash, forKey: .txHash)
        try container.encode(log, forKey: .rawLog)
        try container.encode(code, forKey: .code)
        switch state {
        case .broadcast:
            break
        case let .processed(height, codeSpace, data, info, gasWanted, gasUsed):
            try container.encode(height, forKey: .height)
            try container.encode(codeSpace, forKey: .codespace)
            try container.encode(data, forKey: .data)
            try container.encode(info, forKey: .info)
            try container.encode(gasWanted, forKey: .gasWanted)
            try container.encode(gasUsed, forKey: .gasUsed)
        case let .completed(height, codeSpace, data, info, gasWanted, gasUsed, transaction, timestamp):
            try container.encode(height, forKey: .height)
            try container.encode(codeSpace, forKey: .codespace)
            try container.encode(data, forKey: .data)
            try container.encode(info, forKey: .info)
            try container.encode(gasWanted, forKey: .gasWanted)
            try container.encode(gasUsed, forKey: .gasUsed)
            try container.encode(transaction, forKey: .tx)
            try container.encode(timestamp, forKey: .timestamp)
        }
    }
 
}

enum TransactionState {
    // just sent
    case broadcast
    // either checked or delivered
    case processed(_ height: Int64, _ codeSpace: String, _ data: Data, _ info: String, _ gasWanted: Int64, _ gasUsed: Int64)
    // NewResponseResultTx
    case completed(_ height: Int64, _ codeSpace: String, _ data: Data, _ info: String, _ gasWanted: Int64, _ gasUsed: Int64, _ transaction: TransactionBytes, _ timestamp: Date)
}


/*
 
 // TxResponse defines a structure containing relevant tx data and metadata. The
 // tags are stringified and the log is JSON decoded.
 type TxResponse struct {
     Height    int64           `json:"height"`
     TxHash    string          `json:"txhash"`
     Codespace string          `json:"codespace,omitempty"`
     Code      uint32          `json:"code,omitempty"`
     Data      string          `json:"data,omitempty"`
     RawLog    string          `json:"raw_log,omitempty"`
     Logs      ABCIMessageLogs `json:"logs,omitempty"`
     Info      string          `json:"info,omitempty"`
     GasWanted int64           `json:"gas_wanted,omitempty"`
     GasUsed   int64           `json:"gas_used,omitempty"`
     Tx        Tx              `json:"tx,omitempty"`
     Timestamp string          `json:"timestamp,omitempty"`
 }

 // NewResponseResultTx returns a TxResponse given a ResultTx from tendermint
 func NewResponseResultTx(res *ctypes.ResultTx, tx Tx, timestamp string) TxResponse {
     if res == nil {
         return TxResponse{}
     }

     parsedLogs, _ := ParseABCILogs(res.TxResult.Log)

     return TxResponse{
         TxHash:    res.Hash.String(),
         Height:    res.Height,
         Codespace: res.TxResult.Codespace,
         Code:      res.TxResult.Code,
         Data:      strings.ToUpper(hex.EncodeToString(res.TxResult.Data)),
         RawLog:    res.TxResult.Log,
         Logs:      parsedLogs,
         Info:      res.TxResult.Info,
         GasWanted: res.TxResult.GasWanted,
         GasUsed:   res.TxResult.GasUsed,
         Tx:        tx,
         Timestamp: timestamp,
     }
 }

 // NewResponseFormatBroadcastTxCommit returns a TxResponse given a
 // ResultBroadcastTxCommit from tendermint.
 func NewResponseFormatBroadcastTxCommit(res *ctypes.ResultBroadcastTxCommit) TxResponse {
     if res == nil {
         return TxResponse{}
     }

     if !res.CheckTx.IsOK() {
         return newTxResponseCheckTx(res)
     }

     return newTxResponseDeliverTx(res)
 }

 func newTxResponseCheckTx(res *ctypes.ResultBroadcastTxCommit) TxResponse {
     if res == nil {
         return TxResponse{}
     }

     var txHash string
     if res.Hash != nil {
         txHash = res.Hash.String()
     }

     parsedLogs, _ := ParseABCILogs(res.CheckTx.Log)

     return TxResponse{
         Height:    res.Height,
         TxHash:    txHash,
         Codespace: res.CheckTx.Codespace,
         Code:      res.CheckTx.Code,
         Data:      strings.ToUpper(hex.EncodeToString(res.CheckTx.Data)),
         RawLog:    res.CheckTx.Log,
         Logs:      parsedLogs,
         Info:      res.CheckTx.Info,
         GasWanted: res.CheckTx.GasWanted,
         GasUsed:   res.CheckTx.GasUsed,
     }
 }

 func newTxResponseDeliverTx(res *ctypes.ResultBroadcastTxCommit) TxResponse {
     if res == nil {
         return TxResponse{}
     }

     var txHash string
     if res.Hash != nil {
         txHash = res.Hash.String()
     }

     parsedLogs, _ := ParseABCILogs(res.DeliverTx.Log)

     return TxResponse{
         Height:    res.Height,
         TxHash:    txHash,
         Codespace: res.DeliverTx.Codespace,
         Code:      res.DeliverTx.Code,
         Data:      strings.ToUpper(hex.EncodeToString(res.DeliverTx.Data)),
         RawLog:    res.DeliverTx.Log,
         Logs:      parsedLogs,
         Info:      res.DeliverTx.Info,
         GasWanted: res.DeliverTx.GasWanted,
         GasUsed:   res.DeliverTx.GasUsed,
     }
 }

 // NewResponseFormatBroadcastTx returns a TxResponse given a ResultBroadcastTx from tendermint
 func NewResponseFormatBroadcastTx(res *ctypes.ResultBroadcastTx) TxResponse {
     if res == nil {
         return TxResponse{}
     }

     parsedLogs, _ := ParseABCILogs(res.Log)

     return TxResponse{
         Code:   res.Code,
         Data:   res.Data.String(),
         RawLog: res.Log,
         Logs:   parsedLogs,
         TxHash: res.Hash.String(),
     }
 }

 func (r TxResponse) String() string {
     var sb strings.Builder
     sb.WriteString("Response:\n")

     if r.Height > 0 {
         sb.WriteString(fmt.Sprintf("  Height: %d\n", r.Height))
     }
     if r.TxHash != "" {
         sb.WriteString(fmt.Sprintf("  TxHash: %s\n", r.TxHash))
     }
     if r.Code > 0 {
         sb.WriteString(fmt.Sprintf("  Code: %d\n", r.Code))
     }
     if r.Data != "" {
         sb.WriteString(fmt.Sprintf("  Data: %s\n", r.Data))
     }
     if r.RawLog != "" {
         sb.WriteString(fmt.Sprintf("  Raw Log: %s\n", r.RawLog))
     }
     if r.Logs != nil {
         sb.WriteString(fmt.Sprintf("  Logs: %s\n", r.Logs))
     }
     if r.Info != "" {
         sb.WriteString(fmt.Sprintf("  Info: %s\n", r.Info))
     }
     if r.GasWanted != 0 {
         sb.WriteString(fmt.Sprintf("  GasWanted: %d\n", r.GasWanted))
     }
     if r.GasUsed != 0 {
         sb.WriteString(fmt.Sprintf("  GasUsed: %d\n", r.GasUsed))
     }
     if r.Codespace != "" {
         sb.WriteString(fmt.Sprintf("  Codespace: %s\n", r.Codespace))
     }
     if r.Timestamp != "" {
         sb.WriteString(fmt.Sprintf("  Timestamp: %s\n", r.Timestamp))
     }

     return strings.TrimSpace(sb.String())
 }

 // Empty returns true if the response is empty
 func (r TxResponse) Empty() bool {
     return r.TxHash == "" && r.Logs == nil
 }

 // SearchTxsResult defines a structure for querying txs pageable
 type SearchTxsResult struct {
     TotalCount int          `json:"total_count"` // Count of all txs
     Count      int          `json:"count"`       // Count of txs in current page
     PageNumber int          `json:"page_number"` // Index of current page, start from 1
     PageTotal  int          `json:"page_total"`  // Count of total pages
     Limit      int          `json:"limit"`       // Max count txs per page
     Txs        []TxResponse `json:"txs"`         // List of txs in current page
 }

 func NewSearchTxsResult(totalCount, count, page, limit int, txs []TxResponse) SearchTxsResult {
     return SearchTxsResult{
         TotalCount: totalCount,
         Count:      count,
         PageNumber: page,
         PageTotal:  int(math.Ceil(float64(totalCount) / float64(limit))),
         Limit:      limit,
         Txs:        txs,
     }
 }

 // ParseABCILogs attempts to parse a stringified ABCI tx log into a slice of
 // ABCIMessageLog types. It returns an error upon JSON decoding failure.
 func ParseABCILogs(logs string) (res ABCIMessageLogs, err error) {
     err = json.Unmarshal([]byte(logs), &res)
     return res, err
 }

 */
