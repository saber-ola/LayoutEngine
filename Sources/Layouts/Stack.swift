import CoreGraphics

// MARK: - Stack Protocol

/// Protocol for stack layouts (HStack, VStack)
public protocol Stack: BaseLayoutProtocol {
    /// The space between adjacent children in the stack.
    var spacing: CGFloat { get }
    /// The distribution of children along the main axis.
    var justifyContent: MainAxisAlignment { get }
    /// The alignment of children along the cross axis.
    var alignItems: CrossAxisAlignment { get }
    /// The child components within the stack.
    var children: [any Component] { get }
}

extension Stack {
    public func layout(_ constraint: Constraint) -> R {
        var renderNodes = getRenderNodes(constraint)
        let crossMax = renderNodes.reduce(CGFloat(0).clamp(cross(constraint.minSize), cross(constraint.maxSize))) {
            max($0, cross($1.size))
        }
        
        // If stretching and unbounded, relayout children to stretch
        if cross(constraint.maxSize) == .infinity, alignItems == .stretch {
            renderNodes = getRenderNodes(
                Constraint(
                    minSize: constraint.minSize,
                    maxSize: size(main: main(constraint.maxSize), cross: crossMax)
                )
            )
        }
        
        let mainTotal = renderNodes.reduce(0) { $0 + main($1.size) }
        let maxPrimary = main(constraint.maxSize)
        let minPrimary = main(constraint.minSize)
        let primaryBound = minPrimary > 0 ? minPrimary : maxPrimary
        
        let (offset, distributedSpacing) = LayoutHelper.distribute(
            justifyContent: justifyContent,
            maxPrimary: primaryBound,
            totalPrimary: mainTotal,
            minimumSpacing: spacing,
            numberOfItems: renderNodes.count
        )
        
        var primaryOffset = offset
        var positions: [CGPoint] = []
        
        for child in renderNodes {
            var crossValue: CGFloat = 0
            switch alignItems {
            case .start, .stretch, .baselineFirst:
                crossValue = 0
            case .end, .baselineLast:
                crossValue = crossMax - cross(child.size)
            case .center:
                crossValue = (crossMax - cross(child.size)) / 2
            }
            positions.append(point(main: primaryOffset, cross: crossValue))
            primaryOffset += main(child.size) + distributedSpacing
        }
        
        let intrinsicMain = primaryOffset - distributedSpacing
        let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
        let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)
        let finalSize = size(main: finalMain, cross: crossMax)
        
        return renderNode(size: finalSize, children: renderNodes, positions: positions)
    }
    
    private func getRenderNodes(_ constraint: Constraint) -> [any RenderNode] {
        var renderNodes: [any RenderNode] = []
        
        let childConstraint = Constraint(
            minSize: size(main: -.infinity, cross: alignItems == .stretch && cross(constraint.maxSize) != .infinity ? cross(constraint.maxSize) : 0),
            maxSize: size(main: .infinity, cross: cross(constraint.maxSize))
        )
        
        for child in children {
            renderNodes.append(child.layout(childConstraint))
        }
        
        return renderNodes
    }
    
    private func renderNode(size: CGSize, children: [any RenderNode], positions: [CGPoint]) -> R {
        fatalError("Subclass must implement renderNode")
    }
}

// MARK: - HStack

/// A horizontal stack component that lays out its children in a horizontal line.
public struct HStack: Component, Stack, HorizontalLayoutProtocol {
    public let spacing: CGFloat
    public let justifyContent: MainAxisAlignment
    public let alignItems: CrossAxisAlignment
    public let children: [any Component]
    
    public init(
        spacing: CGFloat = 0,
        justifyContent: MainAxisAlignment = .start,
        alignItems: CrossAxisAlignment = .start,
        @ComponentBuilder _ content: () -> [any Component] = { [] }
    ) {
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.children = content()
    }
    
    public init(
        spacing: CGFloat = 0,
        justifyContent: MainAxisAlignment = .start,
        alignItems: CrossAxisAlignment = .start,
        children: [any Component] = []
    ) {
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.children = children
    }
    
    public func layout(_ constraint: Constraint) -> HStackRenderNode {
        var renderNodes: [any RenderNode] = []
        
        let childConstraint = Constraint(
            minSize: CGSize(width: -.infinity, height: alignItems == .stretch ? constraint.maxSize.height : 0),
            maxSize: CGSize(width: .infinity, height: constraint.maxSize.height)
        )
        
        for child in children {
            renderNodes.append(child.layout(childConstraint))
        }
        
        let crossMax = renderNodes.reduce(0) { max($0, $1.size.height) }
        let mainTotal = renderNodes.reduce(0) { $0 + $1.size.width }
        let maxPrimary = constraint.maxSize.width
        let minPrimary = constraint.minSize.width
        let primaryBound = minPrimary > 0 ? minPrimary : maxPrimary
        
        let (offset, distributedSpacing) = LayoutHelper.distribute(
            justifyContent: justifyContent,
            maxPrimary: primaryBound,
            totalPrimary: mainTotal,
            minimumSpacing: spacing,
            numberOfItems: children.count
        )
        
        var positions: [CGPoint] = []
        var primaryOffset = offset
        
        for node in renderNodes {
            var crossValue: CGFloat = 0
            switch alignItems {
            case .start, .baselineFirst:
                crossValue = 0
            case .end, .baselineLast:
                crossValue = crossMax - node.size.height
            case .center:
                crossValue = (crossMax - node.size.height) / 2
            case .stretch:
                crossValue = 0
            }
            positions.append(CGPoint(x: primaryOffset, y: crossValue))
            primaryOffset += node.size.width + distributedSpacing
        }
        
        let intrinsicMain = primaryOffset - distributedSpacing
        let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
        let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)
        
        return HStackRenderNode(
            size: CGSize(width: finalMain, height: crossMax),
            children: renderNodes,
            positions: positions
        )
    }
}

public struct HStackRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
}

// MARK: - VStack

/// A vertical stack component that lays out its children in a vertical line.
public struct VStack: Component, Stack, VerticalLayoutProtocol {
    public let spacing: CGFloat
    public let justifyContent: MainAxisAlignment
    public let alignItems: CrossAxisAlignment
    public let children: [any Component]
    
    public init(
        spacing: CGFloat = 0,
        justifyContent: MainAxisAlignment = .start,
        alignItems: CrossAxisAlignment = .start,
        @ComponentBuilder _ content: () -> [any Component] = { [] }
    ) {
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.children = content()
    }
    
    public init(
        spacing: CGFloat = 0,
        justifyContent: MainAxisAlignment = .start,
        alignItems: CrossAxisAlignment = .start,
        children: [any Component] = []
    ) {
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.children = children
    }
    
    public func layout(_ constraint: Constraint) -> VStackRenderNode {
        var renderNodes: [any RenderNode] = []
        
        let childConstraint = Constraint(
            minSize: CGSize(width: alignItems == .stretch ? constraint.maxSize.width : 0, height: -.infinity),
            maxSize: CGSize(width: constraint.maxSize.width, height: .infinity)
        )
        
        for child in children {
            renderNodes.append(child.layout(childConstraint))
        }
        
        let crossMax = renderNodes.reduce(0) { max($0, $1.size.width) }
        let mainTotal = renderNodes.reduce(0) { $0 + $1.size.height }
        let maxPrimary = constraint.maxSize.height
        let minPrimary = constraint.minSize.height
        let primaryBound = minPrimary > 0 ? minPrimary : maxPrimary
        
        let (offset, distributedSpacing) = LayoutHelper.distribute(
            justifyContent: justifyContent,
            maxPrimary: primaryBound,
            totalPrimary: mainTotal,
            minimumSpacing: spacing,
            numberOfItems: children.count
        )
        
        var positions: [CGPoint] = []
        var primaryOffset = offset
        
        for node in renderNodes {
            var crossValue: CGFloat = 0
            switch alignItems {
            case .start, .baselineFirst:
                crossValue = 0
            case .end, .baselineLast:
                crossValue = crossMax - node.size.width
            case .center:
                crossValue = (crossMax - node.size.width) / 2
            case .stretch:
                crossValue = 0
            }
            positions.append(CGPoint(x: crossValue, y: primaryOffset))
            primaryOffset += node.size.height + distributedSpacing
        }
        
        let intrinsicMain = primaryOffset - distributedSpacing
        let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
        let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)
        
        return VStackRenderNode(
            size: CGSize(width: crossMax, height: finalMain),
            children: renderNodes,
            positions: positions
        )
    }
}

public struct VStackRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
}

// MARK: - Spacer

/// A flexible component that expands to fill remaining space
public struct Spacer: Component {
    public init() {}
    
    public func layout(_ constraint: Constraint) -> SpacerRenderNode {
        let size = CGSize(
            width: constraint.maxSize.width,
            height: constraint.maxSize.height
        )
        return SpacerRenderNode(size: size)
    }
}

public struct SpacerRenderNode: RenderNode {
    public let size: CGSize
    public var children: [any RenderNode] { [] }
    public var positions: [CGPoint] { [] }
}
