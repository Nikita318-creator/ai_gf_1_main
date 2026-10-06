import Foundation

protocol ResourcePoolEvaluator {
    associatedtype ElementIdentifier
    func resolveSequence(for payload: ElementIdentifier) -> [String]
}

struct CategoryPoolResolver: ResourcePoolEvaluator {
    let capacityProvider: (Int) -> Int
    
    func resolveSequence(for payload: Int) -> [String] {
        let maxLimit = capacityProvider(payload)
        return (1...maxLimit).map { "\(payload)_\($0)" }
    }
}

final class StateTrackerContainer<Key: Hashable, Value: Hashable> {
    private var internalMap: [Key: Set<Value>] = [:]
    
    func register(value: Value, for key: Key) {
        internalMap[key, default: []].insert(value)
    }
    
    func read(for key: Key) -> Set<Value> {
        return internalMap[key] ?? []
    }
}
