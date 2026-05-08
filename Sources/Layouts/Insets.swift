import CoreGraphics

/// A component that applies insets (padding) to its content
public struct Insets: Component {
    let content: any Component
    let insets: UIEdgeInsets
    
    public init(content: any Component, insets: UIEdgeInsets) {
        self.content = content
        self.insets = insets
    }
    
    public func layout(_ constraint: Constraint) -> InsetRenderNode {
        let insetConstraint = constraint.inset(by: insets)
        let contentNode = content.layout(insetConstraint)
        
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
    
    public var children: [any RenderNode] { [content] }
    public var positions: [CGPoint] { [CGPoint(x: insets.left, y: insets.top)] }
}

// MARK: - Component Extension

extension Component {
    /// Applies insets to this component
    public func inset(_ insets: UIEdgeInsets) -> some Component {
        Insets(content: self, insets: insets)
    }
    
    /// Applies horizontal and vertical insets
    public func inset(h: CGFloat, v: CGFloat) -> some Component {
        inset(UIEdgeInsets(top: v, left: h, bottom: v, right: h))
    }
    
    /// Applies equal insets on all sides
    public func inset(_ value: CGFloat) -> some Component {
        inset(UIEdgeInsets(top: value, left: value, bottom: value, right: value))
    }
}
