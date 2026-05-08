#if os(macOS)
import AppKit

// MARK: - Layout Engine Storage for NSView

private class NSViewLayoutEngineContainer {
    let engine = NSViewLayoutEngine()
}

private let nsViewLayoutEngineKey = "com.layoutengine.nsview"

extension NSView {
    public var nsViewLayoutEngine: NSViewLayoutEngine {
        if let container = objc_getAssociatedObject(self, nsViewLayoutEngineKey) as? NSViewLayoutEngineContainer {
            return container.engine
        }

        let container = NSViewLayoutEngineContainer()
        objc_setAssociatedObject(self, nsViewLayoutEngineKey, container, .OBJC_ASSOCIATION_RETAIN)
        return container.engine
    }
}

// MARK: - NSView Layout Engine

public class NSViewLayoutEngine {
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

// MARK: - NSViewController Extension

extension NSViewController {
    public var nsViewLayoutEngine: NSViewLayoutEngine {
        view.nsViewLayoutEngine
    }
}

#endif
