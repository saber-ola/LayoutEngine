import CoreGraphics

/// Basic building block of LayoutEngine.
/// The only method required is `layout(_:)` which calculates
/// the layout and generates a `RenderNode`
public protocol Component {
    /// The type of `RenderNode` that this component produces.
    associatedtype R: RenderNode
    
    /// Calculates the layout of the component within the given constraints and
    /// returns a `RenderNode` representing the result.
    ///
    /// - Parameter constraint: The constraints within which the component must lay itself out.
    /// - Returns: A `RenderNode` representing the laid out component.
    func layout(_ constraint: Constraint) -> R
}

// MARK: - Type-erased Component

/// A type-erased `Component` for storing heterogeneous components
public struct AnyComponent: Component {
    private let layoutFn: (Constraint) -> any RenderNode
    
    public init<C: Component>(_ component: C) {
        self.layoutFn = { constraint in
            component.layout(constraint)
        }
    }
    
    public func layout(_ constraint: Constraint) -> any RenderNode {
        layoutFn(constraint)
    }
}

// MARK: - Component Builder

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
