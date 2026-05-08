import CoreGraphics

public struct Insets: Component {
    let content: any Component
    let insets: UIEdgeInsets

    public init(content: any Component, insets: UIEdgeInsets) {
        self.content = content
        self.insets = insets
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> InsetRenderNode {
        let insetConstraint = constraint.inset(by: insets)
        let contentNode = content.layout(context: context, constraint: insetConstraint)

        return InsetRenderNode(
            size: contentNode.size.inset(by: -insets),
            content: contentNode,
            insets: insets
        )
    }
}

public struct InsetRenderNode: RenderNode {
    public let size: CGSize
    private let content: any RenderNode
    let insets: UIEdgeInsets

    public init(size: CGSize, content: any RenderNode, insets: UIEdgeInsets) {
        self.size = size
        self.content = content
        self.insets = insets
    }

    public var children: [any RenderNode] { [content] }
    public var positions: [CGPoint] { [CGPoint(x: insets.left, y: insets.top)] }
}

// MARK: - DirectionalInsets

public struct DirectionalInsets: Component {
    let content: any Component
    let insets: DirectionalEdgeInsets

    public init(content: any Component, insets: DirectionalEdgeInsets) {
        self.content = content
        self.insets = insets
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> InsetRenderNode {
        let physical = insets.resolved(in: context.resolvedDirection())
        let uiInsets = physical.asUIEdgeInsets
        let insetConstraint = constraint.inset(by: uiInsets)
        let contentNode = content.layout(context: context, constraint: insetConstraint)

        return InsetRenderNode(
            size: contentNode.size.inset(by: -uiInsets),
            content: contentNode,
            insets: uiInsets
        )
    }
}

// MARK: - Component Extensions

extension Component {
    public func inset(_ insets: UIEdgeInsets) -> some Component {
        Insets(content: self, insets: insets)
    }

    public func inset(h: CGFloat, v: CGFloat) -> some Component {
        inset(UIEdgeInsets(top: v, left: h, bottom: v, right: h))
    }

    public func inset(_ value: CGFloat) -> some Component {
        inset(UIEdgeInsets(top: value, left: value, bottom: value, right: value))
    }

    public func directionalInset(_ insets: DirectionalEdgeInsets) -> some Component {
        DirectionalInsets(content: self, insets: insets)
    }
}
