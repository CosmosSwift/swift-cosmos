// Gas consumption descriptors.
let gasIterNextCostFlatDescriptor = "IterNextFlat"
let gasValuePerByteDescriptor = "ValuePerByte"
let gasWritePerByteDescriptor = "WritePerByte"
let gasReadPerByteDescriptor = "ReadPerByte"
let gasWriteCostFlatDescriptor = "WriteFlat"
let gasReadCostFlatDescriptor = "ReadFlat"
let gasHasDescriptor = "Has"
let gasDeleteDescriptor = "Delete"

// Gas measured by the SDK
public typealias Gas = UInt64

// ErrorOutOfGas defines an error thrown when an action results in out of gas.
struct OutOfGas: Swift.Error {
    let descriptor: String
}

// ErrorGasOverflow defines an error thrown when an action results gas consumption
// unsigned integer overflow.
struct GasOverflowError: Swift.Error {
    let descriptor: String
}


// GasMeter interface to track gas consumption
public protocol GasMeter {
    var gasConsumed: Gas { get }
    var gasConsumedToLimit: Gas { get }
    var limit: Gas { get }
    mutating func consumeGas(amount: Gas, descriptor: String) throws
    var isPastLimit: Bool { get }
    var isOutOfGas: Bool { get }
}

public struct BasicGasMeter: GasMeter {
    public let limit: Gas
    public var gasConsumed: Gas
    
    // NewGasMeter returns a reference to a new basicGasMeter.
    public init(limit: Gas) {
        self.limit = limit
        self.gasConsumed = 0
    }

    public var gasConsumedToLimit: Gas {
        if isPastLimit {
            return limit
        }
        
        return gasConsumed
    }

    public mutating func consumeGas(amount: Gas, descriptor: String) throws {
        // TODO: Should we set the consumed field after overflow checking?
        let (consumed, overflow) = gasConsumed.addingReportingOverflow(amount)

        if overflow {
            throw Cosmos.Error.gasOverflow(descriptor: descriptor)
        }

        if gasConsumed > limit {
            throw Cosmos.Error.outOfGas(descriptor: descriptor)
        }
        
        self.gasConsumed = consumed
    }

    public var isPastLimit: Bool {
        gasConsumed > limit
    }

    public var isOutOfGas: Bool {
        gasConsumed >= limit
    }
}

// GasConfig defines gas cost for each operation on KVStores
struct GasConfiguration {
    let hasCost: Gas
    let deleteCost: Gas
    let readCostFlat: Gas
    let readCostPerByte: Gas
    let writeCostFlat: Gas
    let writeCostPerByte: Gas
    let iterationNextCostFlat: Gas
}

// KVGasConfig returns a default gas config for KVStores.
extension GasConfiguration {
    static var keyValue: GasConfiguration {
        GasConfiguration(
            hasCost: 1000,
            deleteCost: 1000,
            readCostFlat: 1000,
            readCostPerByte: 3,
            writeCostFlat: 2000,
            writeCostPerByte: 30,
            iterationNextCostFlat: 30
        )
    }
    
    // TransientGasConfig returns a default gas config for TransientStores.
    static var transient: GasConfiguration {
        // TODO: define gasconfig for transient stores
        .keyValue
    }

}



public struct InfiniteGasMeter: GasMeter {
    public var consumed: Gas
    
    public init() {
        self.consumed = 0
    }
    
    public var gasConsumed: Gas {
        consumed
    }
    
    public var gasConsumedToLimit: Gas {
        consumed
    }

    public var limit: Gas {
        0
    }
    
    public mutating func consumeGas(amount: Gas, descriptor: String) {
        // TODO: Should we set the consumed field after overflow checking?
        let (consumed, overflow) = self.consumed.addingReportingOverflow(amount)
        self.consumed = consumed

        if overflow {
            fatalError("ErrorGasOverflow{\(descriptor)}")
        }
    }
    
    public var isPastLimit: Bool {
        false
    }

    public var isOutOfGas: Bool {
        false
    }
}
