import Foundation

// Coin hold some amount of one currency.
//
// CONTRACT: A coin will never hold a negative amount of any denomination.
public struct Coin: Codable {
    let denomination: String
    let amount: Int
    
    public init(denomination: String, amount: Int) {
        self.denomination = denomination
        self.amount = amount
    }
    
    enum CodingKeys: String, CodingKey {
        case denomination = "denom"
        case amount
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
        
        let amount = Int(string[amountRange]) ?? 0
        var denomination = string
        denomination.removeSubrange(amountRange)
        self.init(denomination: denomination, amount: amount)
    }
    
    // This si required because Tendermint 0.33.9 ser/deser UInt64 as strings
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.denomination = try container.decode(String.self, forKey: .denomination)
        let amountStr = try container.decode(String.self, forKey: .amount)
        guard let amount = Int(amountStr) else {
            throw Cosmos.Error.generic(reason: "Decoding: Invalid amount: \(amountStr)")
        }
        self.amount = amount
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(denomination, forKey: .denomination)
        try container.encode("\(amount)", forKey: .amount)
    }
    
    var isZero: Bool {
        amount == 0
    }
}


// Adds amounts of two coins with same denom. If the coins differ in denom then
// it panics.
extension Coin {
    public static func - (lhs: Coin, rhs: Coin) -> Coin {
        if lhs.denomination != rhs.denomination {
            fatalError("invalid coin denominations; \(lhs.denomination), \(rhs.denomination)")
        }
        
        return Coin(
            denomination: lhs.denomination,
            amount: lhs.amount - rhs.amount
        )
    }


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

extension Array where Element == Coin {
    public static func == (lhs: [Coin], rhs: [Coin]) -> Bool {
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
        
        var coins: [Coin] = []
        
        for coinStr in coinStrArray {
            guard let coin = Coin(string: String(coinStr)) else {
                return nil
            }
            coins.append(coin)
        }
        self = coins
    }
}

extension Array where Element == Coin {
    // TODO: Implement this correctly
    // MarshalJSON implements a custom JSON marshaller for the Coins type to allow
    // nil Coins to be encoded as an empty array.
    public func marshalJSON() throws -> Data {
        let encoder = JSONEncoder()

        if self.isEmpty {
            return try encoder.encode([Coin]())
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
    
    // IsValid asserts the Coins are sorted, have positive amount,
    // and Denom does not contain upper case characters.
    public var isValid: Bool {
        switch self.count {
        case 0:
            return true
        case 1:
            do {
                try Self.validate(denomination: self[0].denomination)
                return true
            } catch {
                return false
            }
        default:
            // check single coin case
            
            if ![self[0]].isValid {
                return false
            }

            var lowDenomination = self[0].denomination
            
            for coin in self.suffix(1) {
                if coin.denomination.lowercased() != coin.denomination {
                    return false
                }
                
                if coin.denomination <= lowDenomination {
                    return false
                }

                // we compare each coin against the last denom
                lowDenomination = coin.denomination
            }

            return true
        }
    }

    
    // IsAllGT returns true if for every denom in coinsB,
    // the denom is present at a greater amount in coins.
    public func isAllGreaterThan(coins: [Coin]) -> Bool {
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
    public static func +(lhs: [Coin], rhs: [Coin]) -> [Coin] {
        var dict = lhs.reduce(into: [String:Int](), { $0[$1.denomination] = $1.amount } )
        
        for coin in rhs {
            dict[coin.denomination, default: 0] += coin.amount
        }
        
        return dict.keys.map { Coin(denomination: $0, amount: dict[$0]!) }
    }
        
    public static func - (lhs: [Coin], rhs: [Coin]) -> [Coin] {
        
        var dict = lhs.reduce(into: [String:Int](), { $0[$1.denomination] = $1.amount } )
        
        for coin in rhs {
            dict[coin.denomination, default: 0] -= coin.amount
        }
        
        return dict.keys.map { Coin(denomination: $0, amount: dict[$0]!) }
    }

    
    // removeZeroCoins removes all zero coins from the given coin set
    func removingZeroCoins() -> [Coin] {
        return self.filter({ !$0.isZero })
    }

    // DenomsSubsetOf returns true if receiver's denom set
    // is subset of coinsB's denoms.
    func denominationIsSubset(of coins: [Coin]) -> Bool {
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
    public func amountOf(denomination: String) -> Int {
        [Coin].mustValidate(denomination: denomination)

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
    
    static let denominationRegex = "[a-z][a-z0-9]{2,15}"

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
