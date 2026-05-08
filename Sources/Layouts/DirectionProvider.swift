import CoreGraphics

public struct DirectionProvider: Component {
    public let direction: LayoutDirection
    public let children: [any Component]

    public init(
        direction: LayoutDirection,
        @ComponentBuilder _ content: () -> [any Component] = { [] }
    ) {
        self.direction = direction
        self.children = content()
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> DirectionProviderRenderNode {
        var childContext = context
        let resolved = direction.resolved(fallback: context.resolvedDirection())
        childContext.direction = resolved

        var childNodes: [any RenderNode] = []
        var positions: [CGPoint] = []
        var maxWidth: CGFloat = 0
        var yOffset: CGFloat = 0

        for child in children {
            let node = child.layout(context: childContext, constraint: constraint)
            childNodes.append(node)
            positions.append(CGPoint(x: 0, y: yOffset))
            maxWidth = max(maxWidth, node.size.width)
            yOffset += node.size.height
        }

        return DirectionProviderRenderNode(
            size: CGSize(width: maxWidth, height: yOffset),
            children: childNodes,
            positions: positions
        )
    }
}

public struct DirectionProviderRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
}
