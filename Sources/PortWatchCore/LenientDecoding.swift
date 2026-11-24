import Foundation

/// Helpers for decoding a feed that evolves frequently without breaking the whole document.
enum LenientDecoding {
    static func optionalString<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> String? {
        guard container.contains(key) else { return nil }
        if (try? container.decodeNil(forKey: key)) == true { return nil }
        if let value = try? container.decode(String.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return String(value) }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(value)
        }
        if let value = try? container.decode(Bool.self, forKey: key) { return value ? "true" : "false" }
        return nil
    }

    static func optionalDouble<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Double? {
        guard container.contains(key) else { return nil }
        if (try? container.decodeNil(forKey: key)) == true { return nil }
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        if let text = try? container.decode(String.self, forKey: key), let value = Double(text) {
            return value
        }
        return nil
    }

    static func optionalInt<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> Int? {
        guard container.contains(key) else { return nil }
        if (try? container.decodeNil(forKey: key)) == true { return nil }
        if let value = try? container.decode(Int.self, forKey: key) { return value }
        if let value = try? container.decode(Double.self, forKey: key) { return Int(value) }
        if let text = try? container.decode(String.self, forKey: key), let value = Int(text) {
            return value
        }
        return nil
    }

    static func decodeNuked<K: CodingKey>(
        from container: KeyedDecodingContainer<K>,
        forKey key: K
    ) -> NukedInfo? {
        guard container.contains(key) else { return nil }
        if (try? container.decodeNil(forKey: key)) == true { return nil }
        if let info = try? container.decode(NukedInfo.self, forKey: key) { return info }
        if let truthy = try? container.decode(Bool.self, forKey: key) {
            return truthy ? NukedInfo() : nil
        }
        // Any other non-null value (unknown shape) still means "nuked" like truthy `e.nuked` in JS.
        return NukedInfo()
    }
}