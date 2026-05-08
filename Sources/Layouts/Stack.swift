import CoreGraphics

// MARK: - Stack Protocol

public protocol Stack: BaseLayoutProtocol {
    var spacing: CGFloat { get }
    var justifyContent: MainAxisAlignment { get }
    var alignItems: CrossAxisAlignment { get }
    var children: [any Component] { get }
}

// MARK: - HStack

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

    public func layout(context: LayoutContext, constraint: Constraint) -> HStackRenderNode {
        var renderNodes: [any RenderNode] = []

        let childConstraint = Constraint(
            minSize: CGSize(width: -.infinity, height: alignItems == .stretch ? constraint.maxSize.height : 0),
            maxSize: CGSize(width: .infinity, height: constraint.maxSize.height)
        )

        for child in children {
            renderNodes.append(child.layout(context: context, constraint: childConstraint))
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

    public func layout(context: LayoutContext, constraint: Constraint) -> VStackRenderNode {
        var renderNodes: [any RenderNode] = []

        let childConstraint = Constraint(
            minSize: CGSize(width: alignItems == .stretch ? constraint.maxSize.width : 0, height: -.infinity),
            maxSize: CGSize(width: constraint.maxSize.width, height: .infinity)
        )

        for child in children {
            renderNodes.append(child.layout(context: context, constraint: childConstraint))
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

public struct Spacer: Component {
    public init() {}

    public func layout(context: LayoutContext, constraint: Constraint) -> SpacerRenderNode {
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
