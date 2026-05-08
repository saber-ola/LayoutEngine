import Foundation

public struct LayoutContext {
    public var direction: LayoutDirection

    public init(direction: LayoutDirection = .auto) {
        self.direction = direction
    }

    public static var system: LayoutContext {
        LayoutContext(direction: .current)
    }

    public func resolvedDirection() -> LayoutDirection {
        direction == .auto ? .current : direction
    }
}
