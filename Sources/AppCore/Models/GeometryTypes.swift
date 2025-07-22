import Foundation

// MARK: - Platform-Agnostic Geometry Types

/// Platform-agnostic size representation
public struct CGSize: Sendable, Codable, Hashable {
    public let width: Double
    public let height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public static let zero = CGSize(width: 0, height: 0)

    public var area: Double {
        width * height
    }

    public var aspectRatio: Double {
        guard height != 0 else { return 0 }
        return width / height
    }
}

/// Platform-agnostic point representation
public struct CGPoint: Sendable, Codable, Hashable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = CGPoint(x: 0, y: 0)
}

/// Platform-agnostic rectangle representation
public struct CGRect: Sendable, Codable, Hashable {
    public let origin: CGPoint
    public let size: CGSize

    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        origin = CGPoint(x: x, y: y)
        size = CGSize(width: width, height: height)
    }

    public static let zero = CGRect(origin: .zero, size: .zero)

    public var width: Double { size.width }
    public var height: Double { size.height }
    public var minX: Double { origin.x }
    public var minY: Double { origin.y }
    public var maxX: Double { origin.x + size.width }
    public var maxY: Double { origin.y + size.height }
    public var midX: Double { origin.x + size.width / 2 }
    public var midY: Double { origin.y + size.height / 2 }

    public var area: Double { size.area }
}

// MARK: - Common Size Constants

public extension CGSize {
    static let thumbnail = CGSize(width: 150, height: 150)
    static let preview = CGSize(width: 300, height: 300)
    static let small = CGSize(width: 200, height: 200)
    static let medium = CGSize(width: 400, height: 400)
    static let large = CGSize(width: 800, height: 800)
    static let extraLarge = CGSize(width: 1200, height: 1200)
}
