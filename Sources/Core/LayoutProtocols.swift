import CoreGraphics

// MARK: - Base Layout Protocol

/// Base protocol for layout components
public protocol BaseLayoutProtocol {
    /// The type of render node this layout produces
    associatedtype R: RenderNode
    
    /// Performs the layout with the given constraint
    func layout(_ constraint: Constraint) -> R
}

// MARK: - Axis Protocols

/// Protocol for horizontal layout calculations
public protocol HorizontalLayoutProtocol: BaseLayoutProtocol {
    /// Returns the main (horizontal) value from a CGSize
    func main(_ size: CGSize) -> CGFloat
    /// Returns the cross (vertical) value from a CGSize
    func cross(_ size: CGSize) -> CGFloat
    /// Creates a CGSize from main and cross values
    func size(main: CGFloat, cross: CGFloat) -> CGSize
    /// Creates a CGPoint from main and cross values
    func point(main: CGFloat, cross: CGFloat) -> CGPoint
}

extension HorizontalLayoutProtocol {
    public func main(_ size: CGSize) -> CGFloat { size.width }
    public func cross(_ size: CGSize) -> CGFloat { size.height }
    public func size(main: CGFloat, cross: CGFloat) -> CGSize { CGSize(width: main, height: cross) }
    public func point(main: CGFloat, cross: CGFloat) -> CGPoint { CGPoint(x: main, y: cross) }
}

/// Protocol for vertical layout calculations
public protocol VerticalLayoutProtocol: BaseLayoutProtocol {
    /// Returns the main (vertical) value from a CGSize
    func main(_ size: CGSize) -> CGFloat
    /// Returns the cross (horizontal) value from a CGSize
    func cross(_ size: CGSize) -> CGFloat
    /// Creates a CGSize from main and cross values
    func size(main: CGFloat, cross: CGFloat) -> CGSize
    /// Creates a CGPoint from main and cross values
    func point(main: CGFloat, cross: CGFloat) -> CGPoint
}

extension VerticalLayoutProtocol {
    public func main(_ size: CGSize) -> CGFloat { size.height }
    public func cross(_ size: CGSize) -> CGFloat { size.width }
    public func size(main: CGFloat, cross: CGFloat) -> CGSize { CGSize(width: cross, height: main) }
    public func point(main: CGFloat, cross: CGFloat) -> CGPoint { CGPoint(x: cross, y: main) }
}

// MARK: - Alignment Enums

/// Alignment options for the main axis
public enum MainAxisAlignment: CaseIterable {
    case start
    case end
    case center
    case spaceBetween
    case spaceAround
    case spaceEvenly
}

/// Alignment options for the cross axis
public enum CrossAxisAlignment: CaseIterable {
    case start
    case end
    case center
    case stretch
    case baselineFirst
    case baselineLast
}

// MARK: - Layout Helper

public struct LayoutHelper {
    /// Calculates the offset and spacing for items based on justifyContent alignment
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
