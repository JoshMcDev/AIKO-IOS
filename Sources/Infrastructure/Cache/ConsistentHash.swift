import CryptoKit
import Foundation

/// Consistent hashing implementation for distributed cache
public actor ConsistentHash {
    // MARK: - Properties

    private let virtualNodes: Int
    private var ring: [UInt32: String] = [:]
    private var sortedKeys: [UInt32] = []
    private var nodeMap: [String: Set<UInt32>] = [:]

    // MARK: - Initialization

    public init(virtualNodes: Int = 150) {
        self.virtualNodes = virtualNodes
    }

    // MARK: - Public Methods

    /// Add a node to the hash ring
    public func addNode(_ nodeId: String) {
        var positions = Set<UInt32>()

        for i in 0 ..< virtualNodes {
            let virtualKey = "\(nodeId):\(i)"
            let hash = hashValue(virtualKey)
            ring[hash] = nodeId
            positions.insert(hash)
        }

        nodeMap[nodeId] = positions
        updateSortedKeys()
    }

    /// Remove a node from the hash ring
    public func removeNode(_ nodeId: String) {
        guard let positions = nodeMap[nodeId] else { return }

        for position in positions {
            ring.removeValue(forKey: position)
        }

        nodeMap.removeValue(forKey: nodeId)
        updateSortedKeys()
    }

    /// Get the node responsible for a given key
    public func getNode(for key: String) -> String {
        guard !ring.isEmpty else {
            fatalError("No nodes available in consistent hash ring")
        }

        let hash = hashValue(key)

        // Find the first node with hash >= key hash
        let index = findInsertionPoint(hash)

        // Wrap around if necessary
        let position = index < sortedKeys.count ? sortedKeys[index] : sortedKeys[0]

        guard let node = ring[position] else {
<<<<<<< HEAD
            // This should never happen if the ring is properly maintained
            fatalError("Ring inconsistency detected: position \(position) not found")
=======
            fatalError("Inconsistent hash ring state: position not found")
>>>>>>> Main
        }
        return node
    }

    /// Get replica nodes for a key
    public func getReplicaNodes(for key: String, count: Int) -> [String] {
        guard !ring.isEmpty else { return [] }

        let hash = hashValue(key)
        var replicas: [String] = []
        var seenNodes = Set<String>()

        // Start from the primary node position
        var index = findInsertionPoint(hash)

        // Find unique nodes
        while replicas.count < count, seenNodes.count < nodeMap.count {
            let position = sortedKeys[index % sortedKeys.count]
            guard let nodeId = ring[position] else {
<<<<<<< HEAD
                index += 1
                continue // Skip invalid positions
=======
                fatalError("Inconsistent hash ring state: position not found in replica lookup")
>>>>>>> Main
            }

            if !seenNodes.contains(nodeId) {
                seenNodes.insert(nodeId)
                if !replicas.isEmpty || nodeId != getNode(for: key) {
                    replicas.append(nodeId)
                }
            }

            index += 1
        }

        return replicas
    }

    /// Get all nodes in the ring
    public func getAllNodes() -> [String] {
        Array(nodeMap.keys)
    }

    /// Get the number of nodes
    public func nodeCount() -> Int {
        nodeMap.count
    }

    /// Check if a node exists
    public func hasNode(_ nodeId: String) -> Bool {
        nodeMap[nodeId] != nil
    }

    /// Get keys that would be affected by removing a node
    public func getAffectedKeys(for nodeId: String, from keys: [String]) -> [String] {
        guard hasNode(nodeId) else { return [] }

        // Temporarily remove the node
<<<<<<< HEAD
        guard let positions = nodeMap[nodeId] else {
            return [] // Node not found
        }
=======
        guard let positions = nodeMap[nodeId] else { return [] }
>>>>>>> Main
        for position in positions {
            ring.removeValue(forKey: position)
        }
        updateSortedKeys()

        // Find keys that would move to a different node
        var affectedKeys: [String] = []
        for key in keys {
            let newNode = getNode(for: key)

            // Re-add the node temporarily to check original assignment
            for position in positions {
                ring[position] = nodeId
            }
            updateSortedKeys()

            let originalNode = getNode(for: key)

            // Remove again for next iteration
            for position in positions {
                ring.removeValue(forKey: position)
            }
            updateSortedKeys()

            if originalNode == nodeId, newNode != nodeId {
                affectedKeys.append(key)
            }
        }

        // Restore the node
        for position in positions {
            ring[position] = nodeId
        }
        updateSortedKeys()

        return affectedKeys
    }

    /// Get load distribution statistics
    public func getLoadDistribution(keyCount: Int = 10000) -> [String: Double] {
        var distribution: [String: Int] = [:]

        // Initialize counters
        for nodeId in nodeMap.keys {
            distribution[nodeId] = 0
        }

        // Simulate key distribution
        for i in 0 ..< keyCount {
            let key = "test-key-\(i)"
            let nodeId = getNode(for: key)
            distribution[nodeId, default: 0] += 1
        }

        // Convert to percentages
        var percentages: [String: Double] = [:]
        for (nodeId, count) in distribution {
            percentages[nodeId] = Double(count) / Double(keyCount) * 100
        }

        return percentages
    }

    // MARK: - Private Methods

    private func hashValue(_ key: String) -> UInt32 {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)

        // Take first 4 bytes and convert to UInt32
        let bytes = Array(hash.makeIterator().prefix(4))
        let value = bytes.withUnsafeBytes { $0.load(as: UInt32.self) }

        return value
    }

    private func updateSortedKeys() {
        sortedKeys = ring.keys.sorted()
    }

    private func findInsertionPoint(_ hash: UInt32) -> Int {
        var left = 0
        var right = sortedKeys.count

        while left < right {
            let mid = (left + right) / 2
            if sortedKeys[mid] < hash {
                left = mid + 1
            } else {
                right = mid
            }
        }

        return left
    }
}

// MARK: - Testing Support

#if DEBUG
    public extension ConsistentHash {
        /// Visualize the hash ring distribution
        func visualizeRing() -> String {
            var output = "Consistent Hash Ring:\n"
            output += "Total Nodes: \(nodeMap.count)\n"
            output += "Virtual Nodes per Node: \(virtualNodes)\n"
            output += "Total Positions: \(ring.count)\n\n"

            // Show first 10 positions
            let positions = sortedKeys.prefix(10)
            for position in positions {
<<<<<<< HEAD
                guard let nodeId = ring[position] else {
                    continue // Skip invalid positions
                }
=======
                guard let nodeId = ring[position] else { continue }
>>>>>>> Main
                output += String(format: "Position %010u -> Node: %@\n", position, nodeId)
            }

            if sortedKeys.count > 10 {
                output += "... (\(sortedKeys.count - 10) more positions)\n"
            }

            return output
        }
    }
#endif
