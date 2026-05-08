#if os(macOS)
import AppKit

// MARK: - Layout Engine Storage for NSView

private class NSViewLayoutEngineContainer {
    let engine = NSViewLayoutEngine()
}

private let nsViewLayoutEngineKey = "com.layoutengine.nsview"

extension NSView {
    /// The layout engine associated with this NSView
    public var layoutEngine: NSViewLayoutEngine {
        if let container = objc_getAssociatedObject(self, nsViewLayoutEngineKey) as? NSViewLayoutEngineContainer {
            return container.engine
        }
        
        let container = NSViewLayoutEngineContainer()
        objc_setAssociatedObject(self, nsViewLayoutEngineKey, container, .OBJC_ASSOCIATION_RETAIN)
        return container.engine
    }
}

// MARK: - NSView Layout Engine

/// Layout engine for macOS NSView
public class NSViewLayoutEngine {
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

// MARK: - NSViewController Extension

extension NSViewController {
    /// The layout engine associated with this view controller's view
    public var layoutEngine: NSViewLayoutEngine {
        view.layoutEngine
    }
}

#endif
