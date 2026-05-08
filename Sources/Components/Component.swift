import CoreGraphics

public protocol Component {
    associatedtype R: RenderNode

    func layout(context: LayoutContext, constraint: Constraint) -> R
}

public struct AnyComponent: Component {
    private let layoutFn: (LayoutContext, Constraint) -> AnyRenderNode

    public init<C: Component>(_ component: C) {
        self.layoutFn = { context, constraint in
            let node = component.layout(context: context, constraint: constraint)
            return AnyRenderNode(node)
        }
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> AnyRenderNode {
        layoutFn(context, constraint)
    }
}

public struct AnyRenderNode: RenderNode {
    private let wrapped: any RenderNode

    public init(_ node: any RenderNode) {
        self.wrapped = node
    }

    public var size: CGSize { wrapped.size }
    public var children: [any RenderNode] { wrapped.children }
    public var positions: [CGPoint] { wrapped.positions }
    public var ascender: CGFloat { wrapped.ascender }
    public var descender: CGFloat { wrapped.descender }
}

@resultBuilder
public struct ComponentBuilder {
    public static func buildBlock(_ components: any Component...) -> [any Component] {
        components
    }

    public static func buildOptional(_ component: [any Component]?) -> [any Component] {
        component ?? []
    }

    public static func buildEither(first: [any Component]) -> [any Component] {
        first
    }

    public static func buildEither(second: [any Component]) -> [any Component] {
        second
    }
}
