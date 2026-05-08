#if os(macOS)
import AppKit

// MARK: - NSView Swizzling for Bounds Changes

private class NSViewBoundsObserver {
    weak var view: NSView?
    var onBoundsChange: ((CGSize) -> Void)?
    var lastBounds: NSRect = .zero
    var observationToken: NSKeyValueObservation?
    
    init(view: NSView) {
        self.view = view
        self.lastBounds = view.bounds
        
        observationToken = view.observe(
            \.bounds,
            options: [.new, .old],
            changeHandler: { [weak self] _, change in
                self?.handleBoundsChange()
            }
        )
    }
    
    private func handleBoundsChange() {
        guard let view = view else { return }
        let newSize = view.bounds.size
        if newSize != lastBounds.size {
            lastBounds = view.bounds
            onBoundsChange?(newSize)
        }
    }
    
    deinit {
        observationToken?.invalidate()
    }
}

private let nsViewBoundsObserverKey = "com.layoutengine.boundsObserver"

extension NSView {
    private var boundsObserver: NSViewBoundsObserver? {
        get {
            objc_getAssociatedObject(self, nsViewBoundsObserverKey) as? NSViewBoundsObserver
        }
        set {
            objc_setAssociatedObject(self, nsViewBoundsObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// Start monitoring bounds changes (size)
    public func startBoundsMonitoring(onBoundsChange: @escaping (CGSize) -> Void) {
        let observer = NSViewBoundsObserver(view: self)
        observer.onBoundsChange = onBoundsChange
        self.boundsObserver = observer
    }
    
    /// Stop monitoring bounds changes
    public func stopBoundsMonitoring() {
        boundsObserver = nil
    }
}

#endif
