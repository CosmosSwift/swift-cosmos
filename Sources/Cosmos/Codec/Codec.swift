import Foundation
import Tendermint

public class Codec {
    private var sealed = false
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    public init() {
        Ed25519PrivateKey.registerMetaType()
        Ed25519PublicKey.registerMetaType()
    }
    
    public static let codec = Codec()

    public func marshalJSON<T: Encodable>(value: T) throws -> Data {
        try encoder.encode(value)
    }

    // MustMarshalJSON panics if an error occurs. Besides tha behaves exactly like MarshalJSON.
    public func mustMarshalJSON<T: Encodable>(value: T) -> Data {
        try! marshalJSON(value: value)
    }
    
    // MarshalBinaryLengthPrefixed encodes the object o according to the Amino spec,
    // but prefixed by a uvarint encoding of the object to encode.
    // Use MarshalBinaryBare if you don't want byte-length prefixing.
    //
    // For consistency, MarshalBinaryLengthPrefixed will first dereference pointers
    // before encoding.  MarshalBinaryLengthPrefixed will panic if o is a nil-pointer,
    // or if o is invalid.
    public func marshalBinaryLengthPrefixed<T: Encodable>(value: T) throws -> Data {
        
        let data = try marshalBinaryBare(value: value)
        
        let size = Data(varintEncode(data.count))
        print(value)
        print(data.count)
        print(size.hex)
        print(data.hex)
        return size + data
    }

    public func mustMarshalBinaryLengthPrefixed<T: Encodable>(value: T) -> Data {
        try! marshalBinaryLengthPrefixed(value: value)
    }
    
    // MarshalBinaryBare encodes the object o according to the Amino spec.
    // MarshalBinaryBare doesn't prefix the byte-length of the encoding,
    // so the caller must handle framing.
    public func marshalBinaryBare<T: Encodable>(value: T) throws -> Data {
        let encoded = try encoder.encode(value)
        print(String(data: encoded, encoding: .utf8))
        return encoded

//        // Dereference value if pointer.
//        var rv, _, isNilPtr = derefPointers(reflect.ValueOf(o))
//        if isNilPtr {
//            // NOTE: You can still do so by calling
//            // `.MarshalBinaryLengthPrefixed(struct{ *SomeType })` or so on.
//            panic("MarshalBinaryBare cannot marshal a nil pointer directly. Try wrapping in a struct?")
//        }
//
//        // Encode Amino:binary bytes.
//        var bz []byte
//        buf := new(bytes.Buffer)
//        rt := rv.Type()
//        info, err := cdc.getTypeInfo_wlock(rt)
//        if err != nil {
//            return nil, err
//        }
//        err = cdc.encodeReflectBinary(buf, info, rv, FieldOptions{BinFieldNum: 1}, true)
//        if err != nil {
//            return nil, err
//        }
//        bz = buf.Bytes()
//
//        // If registered concrete, prepend prefix bytes.
//        if info.Registered {
//            pb := info.Prefix.Bytes()
//            bz = append(pb, bz...)
//        }
//
//        return bz, nil
    }

    // Panics if error.
    public func mustMarshalBinaryBare<T: Encodable>(value: T) -> Data {
        try! marshalBinaryBare(value: value)
    }

    // Like UnmarshalBinaryBare, but will first decode the byte-length prefix.
    // UnmarshalBinaryLengthPrefixed will panic if ptr is a nil-pointer.
    // Returns an error if not all of bz is consumed.
    public func unmarshalBinaryLengthPrefixed<T: Decodable>(data: Data) throws -> T {
        if data.isEmpty {
            throw Cosmos.Error.decodingError(reason: "UnmarshalBinaryLengthPrefixed cannot decode empty bytes")
        }

        // Read byte-length prefix.
        let (u64, n) = data.uvarint()

        if n < 0 {
            throw Cosmos.Error.decodingError(reason: "Error reading msg byte-length prefix: got code \(n)")
        }

        if u64 > UInt64(data.count - n) {
            throw Cosmos.Error.decodingError(reason: "Not enough bytes to read in UnmarshalBinaryLengthPrefixed, want \(u64) more bytes but only have \(data.count - n)")
        } else if u64 < UInt64(data.count - n) {
            throw Cosmos.Error.decodingError(reason: "Bytes left over in UnmarshalBinaryLengthPrefixed, should read \(u64) more bytes but have \(data.count - n)")
        }

        let data = data.suffix(from: n)

        // Decode.
        return try unmarshalBinaryBare(data: data)
    }
    
    public func unmarshalJSON<T: Decodable>(data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }
    
    public func mustUnmarshalJSON<T: Decodable>(data: Data) -> T {
        try! decoder.decode(T.self, from: data)
    }
    
    // UnmarshalBinaryBare will panic if ptr is a nil-pointer.
    public func unmarshalBinaryBare<T: Decodable>(data: Data) throws -> T {
        print(T.self)
        return try decoder.decode(T.self, from: data)
    }
    
    public func mustUnmarshalBinaryBare<T: Decodable>(data: Data) -> T {
        try! unmarshalBinaryBare(data: data)
    }

    // attempt to make some pretty json
    public func marshalJSONIndent<T: Encodable>(value: T) throws -> Data {
        try encoder.encode(value)
    }
    
    // Panics if error.
    public func mustUnmarshalBinaryLength<T: Decodable>(data: Data) -> T {
        try! decoder.decode(T.self, from: data)
    }
    
    public func mustUnmarshalBinaryLengthPrefixed<T: Decodable>(data: Data) -> T {
        try! decoder.decode(T.self, from: data)
    }

    
    // MustMarshalJSONIndent executes MarshalJSONIndent except it fatal errors upon failure.
    public func mustMarshalJSONIndent<T: Encodable>(value: T) -> Data {
        do {
            return try marshalJSONIndent(value: value)
        } catch {
            fatalError("failed to marshal JSON: \(error)")
        }
    }

}

extension Data {
    // uvarint decodes a uint64 from buf and returns that value and the
    // number of bytes read (> 0). If an error occurred, the value is 0
    // and the number of bytes n is <= 0 meaning:
    //
    //     n == 0: buf too small
    //     n  < 0: value larger than 64 bits (overflow)
    //             and -n is the number of bytes read
    //
    func uvarint() -> (UInt64, Int) {
        var x: UInt64 = 0
        var s: UInt = 0
        
        for (i, b) in self.enumerated() {
            if b < 0x80 {
                if i > 9 || i == 9 && b > 1 {
                    return (0, -(i + 1)) // overflow
                }
                return (x | UInt64(b) << s, i + 1)
            }
            
            x |= UInt64(b & 0x7f) << s
            s += 7
        }
        
        return (0, 0)
    }
}


internal func varintEncode<T: FixedWidthInteger>(_ n: T) -> [UInt8] {
    var u = UInt64(n)
    var a = [UInt8]()
    while (u != 0) {
        a.append(UInt8(u % 128))
        u = u >> 7
    }
    if (a.count == 0) { a.append(0x0) }
    for i in 0..<a.count - 1 {
        a[i] = a[i] ^ (1 << 7)
    }
    return a
}

// VarintDecode
internal func varintDecode(_ array: [UInt8]) -> UInt64 {
    assert(array.count < 11)
    var res: UInt64 = 0
    for i in 0..<array.count {
        res = res << 7  + UInt64(array[array.count-i-1] & 127)
    }
    return res
}
