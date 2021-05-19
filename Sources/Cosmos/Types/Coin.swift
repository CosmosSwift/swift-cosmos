import Foundation
import CosmosProto

// Coin hold some amount of one currency.
//
// CONTRACT: A coin will never hold a negative amount of any denomination.
public struct Coin: Codable {
    public let denomination: String
    public let amount: UInt
    
    public init(denomination: String, amount: UInt) {
        self.denomination = denomination
        self.amount = amount
    }
    
    enum CodingKeys: String, CodingKey {
        case denomination = "denom"
        case amount
    }
}

public extension Coin {
    init(_ coin: Cosmos_Base_V1beta1_Coin) {
        self.denomination = coin.denom
        self.amount = UInt(coin.amount)!
    }
}

public extension Cosmos_Base_V1beta1_Coin {
    init(_ coin: Coin) {
        self.init()
        self.denom = coin.denomination
        self.amount = "\(coin.amount)"
    }
}

extension Coin {
    public init?(string: String) {
        // get the first char which is not number (or . when we handle DecCoin)
        // from there, it's the denom
        // the denom should be btw 3 and 16 char long, start with a lowercase letter, and the rest should be lowercase or number
        //
        let pattern = "[0-9]+"
        guard let amountRange = string.range(of: pattern, options:.regularExpression) else {
            return nil
        }
        
        let amount = UInt(string[amountRange]) ?? 0
        var denomination = string
        denomination.removeSubrange(amountRange)
        self.init(denomination: denomination, amount: amount)
    }
    
    // This si required because Tendermint 0.33.9 ser/deser UInt64 as strings
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.denomination = try container.decode(String.self, forKey: .denomination)
        let amountStr = try container.decode(String.self, forKey: .amount)
        guard let amount = UInt(amountStr) else {
            throw Cosmos.Error.generic(reason: "Decoding: Invalid amount: \(amountStr)")
        }
        self.amount = amount
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(denomination, forKey: .denomination)
        try container.encode("\(amount)", forKey: .amount)
    }
    
    // Validate returns an error if the Coin has a negative amount or if
    // the denom is invalid.
    func validate() throws {
        try Coins.validate(denomination: denomination)
    }

    // IsValid returns true if the Coin has a non-negative amount and the denom is valid.
    public var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }

    var isZero: Bool {
        amount == 0
    }
}

extension Coin: CustomStringConvertible {
    public var description: String {
        "\(amount)\(denomination)"
    }
}

// Adds amounts of two coins with same denom. If the coins differ in denom then
// it panics.
extension Coin {
    #warning("operations should not lead to fatalError()")
    public static func - (lhs: Coin, rhs: Coin) -> Coin {
        if lhs.denomination != rhs.denomination {
            fatalError("invalid coin denominations; \(lhs.denomination), \(rhs.denomination)")
        }
        
        if lhs.amount < rhs.amount {
            fatalError("coins substraction leading to negative amount ; \(lhs.amount) < \(rhs.amount)")
        }
        
        return Coin(
            denomination: lhs.denomination,
            amount: lhs.amount - rhs.amount
        )
    }

    #warning("operations should not lead to fatalError()")
    public static func + (lhs: Coin, rhs: Coin) -> Coin {
        if lhs.denomination != rhs.denomination {
            fatalError("invalid coin denominations; \(lhs.denomination), \(rhs.denomination)")
        }
        
        return Coin(
            denomination: lhs.denomination,
            amount: lhs.amount + rhs.amount
        )
    }
}

extension Coin: Comparable {
    public static func < (lhs: Coin, rhs: Coin) -> Bool {
        lhs.amount < rhs.amount
    }
}

public typealias Coins = [Coin]

extension Coins {
    public init(_ coin: Coin) {
        self.init([coin])
    }
    
    public init(_ coins: Coins) {
        let newCoins = coins.sanitized()
        
        do {
            try newCoins.validate()
        } catch {
            fatalError("invalid coin set \(newCoins): \(error)")
        }
        
        self = newCoins
    }
    
    private func sanitized() -> Coins {
        let newCoins = self.removingZeroCoins()
        
        guard !newCoins.isEmpty else {
            return []
        }
        
        return newCoins.sorted()
    }
}

extension Coins {
    public static func == (lhs: Coins, rhs: Coins) -> Bool {
        if lhs.count != rhs.count {
            return false
        }
        
        let a = lhs.sorted()
        let b = rhs.sorted()
        
        for (coinA, coinB) in zip(a, b) {
            if coinA != coinB { return false }
        }
        
        return true
    }
    
    public init?(string: String) {
        let coinStrArray = string.split(separator: ",")
        var coins: Coins = []
        
        for coinStr in coinStrArray {
            guard let coin = Coin(string: String(coinStr)) else {
                return nil
            }
            coins.append(coin)
        }
        self = coins
    }
}

struct ValidationError: Swift.Error, CustomStringConvertible {
    let description: String
}

extension Array where Element == Coin {
    // TODO: Implement this correctly
    // MarshalJSON implements a custom JSON marshaller for the Coins type to allow
    // nil Coins to be encoded as an empty array.
    public func marshalJSON() throws -> Data {
        let encoder = JSONEncoder()

        if self.isEmpty {
            return try encoder.encode(Coins())
        }

        return try encoder.encode(self)
    }

    // isAllPositive returns true if there is at least one coin.
    public var isAllPositive: Bool {
        if isEmpty {
            return false
        }

        return true
    }
    
    // Validate checks that the Coins are sorted, have positive amount, with a valid and unique
    // denomination (i.e no duplicates). Otherwise, it returns an error.
    func validate() throws {
        switch self.count {
        case 0:
            return

        case 1:
            try Self.validate(denomination: self[0].denomination)
            return

        default:
            // check single coin case
            try [self[0]].validate()

            var lowDenomination = self[0].denomination
            var seenDenominations: [String: Void] = [:]
            seenDenominations[lowDenomination] = ()
            
            for coin in self.suffix(1) {
                if seenDenominations[coin.denomination] != nil {
                    throw ValidationError(description: "duplicate denomination \(coin.denomination)")
                }
                
                try Self.validate(denomination: coin.denomination)
                
                guard coin.denomination > lowDenomination else {
                    throw ValidationError(description: "denomination \(coin.denomination) is not sorted")
                }

                // we compare each coin against the last denom
                lowDenomination = coin.denomination
                seenDenominations[coin.denomination] = ()
            }
        }
    }

    // IsValid asserts the Coins are sorted, have positive amount,
    // and Denom does not contain upper case characters.
    public var isValid: Bool {
        do {
            try validate()
            return true
        } catch {
            return false
        }
    }

    // IsAllGT returns true if for every denom in coinsB,
    // the denom is present at a greater amount in coins.
    public func isAllGreaterThan(coins: Coins) -> Bool {
        if isEmpty {
            return false
        }

        if coins.isEmpty {
            return true
        }

        if !coins.denominationIsSubset(of: self) {
            return false
        }

        for coin in self {
            let amountA = amountOf(denomination: coin.denomination)
            let amountB = coin.amount
            
            if !(amountA > amountB) {
                return false
            }
        }

        return true
    }
    
    // Add adds two sets of coins.
    //
    // e.g.
    // {2A} + {A, 2B} = {3A, 2B}
    // {2A} + {0B} = {2A}
    //
    // NOTE: Add operates under the invariant that coins are sorted by
    // denominations.
    //
    // CONTRACT: Add will never return Coins where one Coin has a non-positive
    // amount. In otherwords, IsValid will always return true.
    public static func +(lhs: Coins, rhs: Coins) -> Coins {
        var dict = lhs.reduce(into: [String:UInt](), { $0[$1.denomination] = $1.amount } )
        
        for coin in rhs {
            dict[coin.denomination, default: 0] += coin.amount
        }
        
        return dict.keys.map { Coin(denomination: $0, amount: dict[$0]!) }
    }
        
    public static func substract(from lhs: Coins, this rhs: Coins) throws -> Coins {
        
        var dict = lhs.reduce(into: [String:UInt](), { $0[$1.denomination] = $1.amount } )
        
        for coin in rhs {
            let value = dict[coin.denomination, default: 0]
            if value < coin.amount {
                throw CosmosError.errInvalidCoins
            } else {
                dict[coin.denomination] = value - coin.amount
            }
        }
        
        return dict.keys.map { Coin(denomination: $0, amount: dict[$0]!) }
    }

    
    // removeZeroCoins removes all zero coins from the given coin set
    func removingZeroCoins() -> Coins {
        return self.filter({ !$0.isZero })
    }

    // DenomsSubsetOf returns true if receiver's denom set
    // is subset of coinsB's denoms.
    func denominationIsSubset(of coins: Coins) -> Bool {
        // more denoms in B than in receiver
        if count > coins.count {
            return false
        }

        for coin in self {
            if coins.amountOf(denomination: coin.denomination) == 0 {
                return false
            }
        }

        return true
    }
     
    // Returns the amount of a denom from coins
    public func amountOf(denomination: String) -> UInt {
    Coins.mustValidate(denomination: denomination)

        switch count {
        case 0:
            return 0

        case 1:
            let coin = self[0]
            
            if denomination == coin.denomination {
                return coin.amount
            }
            
            return 0

        default:
            let midIdx = count / 2 // 2:1, 3:1, 4:2
            let coin = self[midIdx]
            
            if denomination < coin.denomination {
                return Array(prefix(midIdx)).amountOf(denomination: denomination)
            } else if denomination == coin.denomination {
                return coin.amount
            } else {
                return Array(suffix(from: midIdx + 1)).amountOf(denomination: denomination)
            }
        }
    }
}

let denominationRegex = "[a-z][a-z0-9]{2,15}"

extension Coins {
    // ValidateDenom validates a denomination string returning an error if it is
    // invalid.
    public static func validate(denomination: String) throws {
        if denomination.range(of: denominationRegex, options: .regularExpression) == nil {
            throw Cosmos.Error.invalidDenomination(denomination: denomination)
        }
    }

    static func mustValidate(denomination: String) {
        try! validate(denomination: denomination)
    }
}
