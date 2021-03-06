import Foundation

public typealias ValueValidatorFunction = (_ value: AnyEncodable) throws -> Void

// ParamSetPair is used for associating paramsubspace key and field of param
// structs.
public struct ParameterSetPair {
    #warning("TODO JAAP: does this need to be public?")
    public let key: Data
    public let value: AnyEncodable
    public let validatorFunction: ValueValidatorFunction
    
    public init<T: Encodable>(
        key: Data,
        value: T,
        validatorFunction: @escaping ValueValidatorFunction
    ) {
        self.key = key
        self.value = AnyEncodable(value)
        self.validatorFunction = validatorFunction
    }
}

// ParamSetPairs Slice of KeyFieldPair
public typealias ParameterSetPairs = [ParameterSetPair]

// ParamSet defines an interface for structs containing parameters for a module
public protocol ParameterSet {
    var parameterSetPairs: ParameterSetPairs { get }
}

public struct AnyEncodable: Encodable {
    public let value: Encodable
    
    init<T: Encodable>(_ encodable: T) {
        self.value = encodable
    }
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
