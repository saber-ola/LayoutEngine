#if os(iOS) || os(tvOS)
import UIKit

// MARK: - Layout Engine Storage

private class LayoutEngineContainer {
    let engine = LayoutEngine()
}

private let layoutEngineKey = "com.layoutengine.uiview"

extension UIView {
    /// The layout engine associated with this view
    public var layoutEngine: LayoutEngine {
        if let container = objc_getAssociatedObject(self, layoutEngineKey) as? LayoutEngineContainer {
            return container.engine
        }
        
        let container = LayoutEngineContainer()
        objc_setAssociatedObject(self, layoutEngineKey, container, .OBJC_ASSOCIATION_RETAIN)
        return container.engine
    }
}

// MARK: - Layout Engine

/// Main layout engine for calculating and managing layouts
public class LayoutEngine {
    private var component: (any Component)?
    private var currentConstraint: Constraint?
    private var renderNode: (any RenderNode)?
    
    public init() {}
    
    /// Set a component to be laid out
    public func setComponent(_ component: any Component) {
        self.component = component
    }
    
    /// Layout with a given constraint
    public func layout(constraint: Constraint) -> (any RenderNode)? {
        guard let component = component else { return nil }
        let node = component.layout(constraint)
        self.renderNode = node
        self.currentConstraint = constraint
        return node
    }
    
    /// Get the current render node
    public var currentRenderNode: (any RenderNode)? {
        renderNode
    }
}

#endif
