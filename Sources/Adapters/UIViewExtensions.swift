#if os(iOS) || os(tvOS)
import UIKit

// MARK: - Layout Engine Storage

private class LayoutEngineContainer {
    let engine = UIViewLayoutEngine()
}

private let layoutEngineKey = "com.layoutengine.uiview"

extension UIView {
    public var uiViewLayoutEngine: UIViewLayoutEngine {
        if let container = objc_getAssociatedObject(self, layoutEngineKey) as? LayoutEngineContainer {
            return container.engine
        }

        let container = LayoutEngineContainer()
        objc_setAssociatedObject(self, layoutEngineKey, container, .OBJC_ASSOCIATION_RETAIN)
        return container.engine
    }
}

// MARK: - UIView Layout Engine

public class UIViewLayoutEngine {
    private var component: (any Component)?
    private var currentConstraint: Constraint?
    private var renderNode: (any RenderNode)?
    private var context: LayoutContext = .system

    public init() {}

    public func setComponent(_ component: any Component) {
        self.component = component
    }

    public func setContext(_ context: LayoutContext) {
        self.context = context
    }

    public func layout(constraint: Constraint) -> (any RenderNode)? {
        guard let component = component else { return nil }
        let node = component.layout(context: context, constraint: constraint)
        self.renderNode = node
        self.currentConstraint = constraint
        return node
    }

    public var currentRenderNode: (any RenderNode)? {
        renderNode
    }
}

#endif
