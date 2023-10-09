//
//  AtomicDictionary.swift
//
//  Created by John T Ingato on 10/5/23.
//

import Foundation

public final class AtomicDictionary<Key: Hashable, Value>: CustomDebugStringConvertible {
    private var dictionary = [Key: Value]()
    
    private let queue = DispatchQueue(
        label: "AtomicDictionary.\(UUID().uuidString)",
        qos: .default,
        attributes: .concurrent,
        autoreleaseFrequency: .inherit,
        target: .global()
    )
    
    public init() {}

    public init(_ dictionary: [Key: Value]) {
        self.dictionary = dictionary
    }

    public subscript(key: Key) -> Value? {
        get {
            queue.sync {
                dictionary[key]
            }
        }
        set {
            queue.sync(flags: .barrier) {
                dictionary[key] = newValue
            }
        }
    }
    
    public var values: Dictionary<Key, Value>.Values {
        queue.sync {
            dictionary.values
        }
    }
    
    public var keys: Dictionary<Key, Value>.Keys {
        queue.sync {
            dictionary.keys
        }
    }

    /// Adopted from Dictionary.merge(_ other:).
    ///
    /// This is a simplified version that only takes the first
    /// value in the case of any duplicates
    public func merge(_ other: [Key: Value]) {
        queue.sync(flags: .barrier) {
            dictionary.merge(other) { first, _ in
                first
            }
        }
    }

    public var debugDescription: String {
        queue.sync {
            dictionary.debugDescription
        }
    }

    @discardableResult
    public func removeValue(forKey key: Key) -> Value? {
        queue.sync(flags: .barrier) {
            dictionary.removeValue(forKey: key)
        }
    }

    public func removeAll() {
        queue.sync(flags: .barrier) {
            dictionary.removeAll()
        }
    }

    public func copy() -> AtomicDictionary<Key, Value> {
        AtomicDictionary(dictionary)
    }
}

extension AtomicDictionary: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Key, Value)...) {
        self.init()
        elements.forEach { key, value in
            dictionary[key] = value
        }
    }
}
