import CoreGraphics

// MARK: - Base Layout Protocol

public protocol BaseLayoutProtocol {
    associatedtype R: RenderNode
    func layout(context: LayoutContext, constraint: Constraint) -> R
}

// MARK: - Axis Protocols

public protocol HorizontalLayoutProtocol: BaseLayoutProtocol {
    func main(_ size: CGSize) -> CGFloat
    func cross(_ size: CGSize) -> CGFloat
    func size(main: CGFloat, cross: CGFloat) -> CGSize
    func point(main: CGFloat, cross: CGFloat) -> CGPoint
}

extension HorizontalLayoutProtocol {
    public func main(_ size: CGSize) -> CGFloat { size.width }
    public func cross(_ size: CGSize) -> CGFloat { size.height }
    public func size(main: CGFloat, cross: CGFloat) -> CGSize { CGSize(width: main, height: cross) }
    public func point(main: CGFloat, cross: CGFloat) -> CGPoint { CGPoint(x: main, y: cross) }
}

public protocol VerticalLayoutProtocol: BaseLayoutProtocol {
    func main(_ size: CGSize) -> CGFloat
    func cross(_ size: CGSize) -> CGFloat
    func size(main: CGFloat, cross: CGFloat) -> CGSize
    func point(main: CGFloat, cross: CGFloat) -> CGPoint
}

extension VerticalLayoutProtocol {
    public func main(_ size: CGSize) -> CGFloat { size.height }
    public func cross(_ size: CGSize) -> CGFloat { size.width }
    public func size(main: CGFloat, cross: CGFloat) -> CGSize { CGSize(width: cross, height: main) }
    public func point(main: CGFloat, cross: CGFloat) -> CGPoint { CGPoint(x: cross, y: main) }
}

// MARK: - Alignment Enums

public enum MainAxisAlignment: CaseIterable {
    case start
    case end
    case center
    case spaceBetween
    case spaceAround
    case spaceEvenly
}

extension MainAxisAlignment {
    public var mirrored: MainAxisAlignment {
        switch self {
        case .start: return .end
        case .end: return .start
        case .center: return .center
        case .spaceBetween: return .spaceBetween
        case .spaceAround: return .spaceAround
        case .spaceEvenly: return .spaceEvenly
        }
    }
}

public enum CrossAxisAlignment: CaseIterable {
    case start
    case end
    case center
    case stretch
    case baselineFirst
    case baselineLast
}

extension CrossAxisAlignment {
    public var mirrored: CrossAxisAlignment {
        switch self {
        case .start: return .end
        case .end: return .start
        case .center: return .center
        case .stretch: return .stretch
        case .baselineFirst: return .baselineFirst
        case .baselineLast: return .baselineLast
        }
    }
}

// MARK: - Layout Helper

public struct LayoutHelper {
    public static func distribute(
        justifyContent: MainAxisAlignment,
        maxPrimary: CGFloat,
        totalPrimary: CGFloat,
        minimumSpacing: CGFloat,
        numberOfItems: Int
    ) -> (offset: CGFloat, spacing: CGFloat) {
        guard numberOfItems > 0 else { return (0, minimumSpacing) }

        let availableSpace = maxPrimary - totalPrimary
        let gaps = numberOfItems - 1

        switch justifyContent {
        case .start:
            return (0, minimumSpacing)
        case .end:
            return (availableSpace, minimumSpacing)
        case .center:
            return (availableSpace / 2, minimumSpacing)
        case .spaceBetween:
            let spacing = gaps > 0 ? minimumSpacing + availableSpace / CGFloat(gaps) : minimumSpacing
            return (0, spacing)
        case .spaceAround:
            let spacing = gaps > 0 ? availableSpace / CGFloat(numberOfItems) : minimumSpacing
            return (spacing / 2, minimumSpacing + spacing)
        case .spaceEvenly:
            let spacing = gaps > 0 ? availableSpace / CGFloat(numberOfItems + 1) : minimumSpacing
            return (spacing, minimumSpacing + spacing)
        }
    }
}
