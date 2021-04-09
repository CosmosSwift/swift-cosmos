import ABCIMessages
import Foundation

extension CosmosError {
    // SuccessABCICode declares an ABCI response use 0 to signal that the
    // processing was successful and no error is returned.
    static let successABCICode = 0

    // All unclassified errors that do not provide an ABCI code are clubbed
    // under an internal error code and a generic message instead of
    // detailed error string.
    static let internalABCICodespace = undefinedCodespace
    
    static let internalABCICode: UInt32 = 1
    

     // errInternal should never be exposed, but we reserve this code for non-specified errors
     //nolint
    static let errInternal = register(codespace: undefinedCodespace, code: 1, description: "internal")

     // ErrTxDecode is returned if we cannot parse a transaction
    static let errTxDecode = register(codespace: rootCodespace, code: 2, description: "tx parse error")

     // ErrInvalidSequence is used the sequence number (nonce) is incorrect
     // for the signature
    static let errInvalidSequence = register(codespace: rootCodespace, code: 3, description: "invalid sequence")

     // ErrUnauthorized is used whenever a request without sufficient
     // authorization is handled.
    static let errUnauthorized = register(codespace: rootCodespace, code: 4, description: "unauthorized")

     // ErrInsufficientFunds is used when the account cannot pay requested amount.
    static let errInsufficientFunds = register(codespace: rootCodespace, code: 5, description: "insufficient funds")

     // ErrUnknownRequest to doc
    static let errUnknownRequest = register(codespace: rootCodespace, code: 6, description: "unknown request")

     // ErrInvalidAddress to doc
    static let errInvalidAddress = register(codespace: rootCodespace, code: 7, description: "invalid address")

     // ErrInvalidPubKey to doc
    static let errInvalidPubKey = register(codespace: rootCodespace, code: 8, description: "invalid pubkey")

     // ErrUnknownAddress to doc
    static let errUnknownAddress = register(codespace: rootCodespace, code: 9, description: "unknown address")

     // ErrInvalidCoins to doc
    static let errInvalidCoins = register(codespace: rootCodespace, code: 10, description: "invalid coins")

     // ErrOutOfGas to doc
    static let errOutOfGas = register(codespace: rootCodespace, code: 11, description: "out of gas")

     // ErrMemoTooLarge to doc
    static let errMemoTooLarge = register(codespace: rootCodespace, code: 12, description: "memo too large")

     // ErrInsufficientFee to doc
    static let errInsufficientFee = register(codespace: rootCodespace, code: 13, description: "insufficient fee")

     // ErrTooManySignatures to doc
    static let errTooManySignatures = register(codespace: rootCodespace, code: 14, description: "maximum number of signatures exceeded")

     // ErrNoSignatures to doc
    static let errNoSignatures = register(codespace: rootCodespace, code: 15, description: "no signatures supplied")

     // ErrJSONMarshal defines an ABCI typed JSON marshalling error
    static let errJSONMarshal = register(codespace: rootCodespace, code: 16, description: "failed to marshal JSON bytes")

     // ErrJSONUnmarshal defines an ABCI typed JSON unmarshalling error
    static let errJSONUnmarshal = register(codespace: rootCodespace, code: 17, description: "failed to unmarshal JSON bytes")

     // ErrInvalidRequest defines an ABCI typed error where the request contains
     // invalid data.
    static let errInvalidRequest = register(codespace: rootCodespace, code: 18, description: "invalid request")

     // ErrTxInMempoolCache defines an ABCI typed error where a tx already exists
     // in the mempool.
    static let errTxInMempoolCache = register(codespace: rootCodespace, code: 19, description: "tx already in mempool")

     // ErrMempoolIsFull defines an ABCI typed error where the mempool is full.
    static let errMempoolIsFull = register(codespace: rootCodespace, code: 20, description: "mempool is full")

     // ErrTxTooLarge defines an ABCI typed error where tx is too large.
    static let errTxTooLarge = register(codespace: rootCodespace, code: 21, description: "tx too large")

     // ErrPanic is only set when we recover from a panic, so we know to
     // redact potentially sensitive system info
    static let errPanic = register(codespace: undefinedCodespace, code: 111222, description: "panic")
}

// ABCIInfo returns the ABCI error information as consumed by the tendermint
// client. Returned codespace, code, and log message should be used as a ABCI response.
// Any error that does not provide ABCICode information is categorized as error
// with code 1, codespace UndefinedCodespace
// When not running in a debug mode all messages of errors that do not provide
// ABCICode information are replaced with generic "internal error". Errors
// without an ABCICode information as considered internal.
func abciInfo(error: Swift.Error, debug: Bool) -> (codespace: String, code: UInt32, log: String) {
    // TODO: Check if we really need this
//    if errIsNil(err) {
//        return "", SuccessABCICode, ""
//    }

    let encode: (Swift.Error) -> String
    
    if debug {
        encode = debugErrorEncoder
    } else {
        encode = defaultErrorEncoder
    }

    return (abciCodespace(error: error), abciCode(error: error), encode(error))
}


// ResponseCheckTx returns an ABCI ResponseCheckTx object with fields filled in
// from the given error and gas values.
extension ResponseCheckTx {
    init(
        error: Swift.Error,
        gasWanted: UInt64,
        gasUsed: UInt64,
        debug: Bool
    ) {
        let (codespace, code, log) = abciInfo(error: error, debug: debug)
        
        self.init(
            code: code,
            log: log,
            gasWanted: Int64(gasWanted),
            gasUsed: Int64(gasUsed),
            codespace: codespace
        )
    }
}

extension ResponseDeliverTx {
    // ResponseDeliverTx returns an ABCI ResponseDeliverTx object with fields filled in
    // from the given error and gas values.
    init(
        error: Swift.Error,
        gasWanted: UInt64,
        gasUsed: UInt64,
        debug: Bool
    ) {
        let (space, code, log) = abciInfo(error: error, debug: debug)
        
        self.init(
            code:      code,
            log:       log,
            gasWanted: Int64(gasWanted),
            gasUsed:   Int64(gasUsed),
            codespace: space
        )
    }
}

extension ResponseQuery where Payload == Data {
    // QueryResult returns a ResponseQuery from an error. It will try to parse ABCI
    // info from the error.
    init(error: Swift.Error) {
        let (space, code, log) = abciInfo(error: error, debug: false)
        
        self.init(
            code: code,
            log: log,
            codespace: space
        )
    }
}



// The debugErrEncoder encodes the error with a stacktrace.
func debugErrorEncoder(error: Swift.Error) -> String {
    "\(error)"
}

// The defaultErrEncoder applies Redact on the error before encoding it with its internal error message.
func defaultErrorEncoder(error: Swift.Error) -> String {
    redact(error: error).localizedDescription
}

protocol ABCICoder {
    var abciCode: UInt32 { get }
}

// abciCode test if given error contains an ABCI code and returns the value of
// it if available. This function is testing for the causer interface as well
// and unwraps the error.
func abciCode(error: Swift.Error) -> UInt32 {
    // TODO: Check if it makes sense for us
//    if errIsNil(err) {
//        return SuccessABCICode
//    }
    var error = error
    
    while true {
        if let coder = error as? ABCICoder {
            return coder.abciCode
        }

        if let causer = error as? Causer {
            error = causer.cause
        } else {
            return CosmosError.internalABCICode
        }
    }
}

protocol Codespacer {
    var codespace: String { get }
}

// abciCodespace tests if given error contains a codespace and returns the value of
// it if available. This function is testing for the causer interface as well
// and unwraps the error.
func abciCodespace(error: Swift.Error) -> String {
    // TODO: Check if we need this
//    if errIsNil(err) {
//        return ""
//    }
    var error = error

    while true {
        if let codespacer = error as? Codespacer {
            return codespacer.codespace
        }
        
        if let causer = error as? Causer {
            error = causer.cause
        } else {
            return CosmosError.internalABCICodespace
        }
    }
}

// causer is an interface implemented by an error that supports wrapping. Use
// it to test if an error wraps another error instance.
protocol Causer {
    var cause: Swift.Error { get }
}

// Redact replace all errors that do not initialize with a weave error with a
// generic internal error instance. This function is supposed to hide
// implementation details errors and leave only those that weave framework
// originates.
func redact(error: Swift.Error) -> Swift.Error {
    // TODO: Check if this makes sense for us
//    if ErrPanic.Is(err) {
//        return ErrPanic
//    }
    
    if abciCode(error: error) == CosmosError.internalABCICode {
        return CosmosError.internal
    }
    
    return error
}

