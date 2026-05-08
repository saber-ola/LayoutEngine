import Foundation
import CoreGraphics

#if os(iOS) || os(tvOS)
import UIKit

private class ViewChangeListener: NSObject {
    weak var view: UIView?
    var onSizeChange: ((CGSize) -> Void)?
    var onRTLChange: ((LayoutDirection) -> Void)?
    var lastSize: CGSize = .zero
    var lastDirection: LayoutDirection = .current
    var directionChangeObserver: NSObjectProtocol?
    
    init(view: UIView) {
        self.view = view
        self.lastSize = view.bounds.size
        super.init()
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // Monitor global RTL changes
        LayoutChangeMonitor.shared.onLayoutDirectionChange { [weak self] direction in
            self?.handleDirectionChange(direction)
        }
    }
    
    func handleSizeChange() {
        guard let view = view else { return }
        let newSize = view.bounds.size
        if newSize != lastSize {
            lastSize = newSize
            onSizeChange?(newSize)
        }
    }
    
    func handleDirectionChange(_ direction: LayoutDirection) {
        if direction != lastDirection {
            lastDirection = direction
            onRTLChange?(direction)
        }
    }
    
    func stop() {
        if let observer = directionChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    deinit {
        stop()
    }
}

extension UIView {
    private static let changeListenerKey = "com.layoutengine.changelistener"
    
    private var changeListener: ViewChangeListener? {
        get {
            objc_getAssociatedObject(self, Self.changeListenerKey) as? ViewChangeListener
        }
        set {
            objc_setAssociatedObject(self, Self.changeListenerKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// Start monitoring layout changes
    public func startLayoutMonitoring(
        onSizeChange: ((CGSize) -> Void)? = nil,
        onRTLChange: ((LayoutDirection) -> Void)? = nil
    ) {
        let listener = ViewChangeListener(view: self)
        listener.onSizeChange = onSizeChange
        listener.onRTLChange = onRTLChange
        self.changeListener = listener
    }
    
    /// Stop monitoring layout changes
    public func stopLayoutMonitoring() {
        changeListener?.stop()
        changeListener = nil
    }
    
    /// Manually trigger size change check
    public func checkLayoutChanges() {
        changeListener?.handleSizeChange()
    }
}

#elseif os(macOS)
import AppKit

private class ViewChangeListener: NSObject {
    weak var view: NSView?
    var onSizeChange: ((CGSize) -> Void)?
    var lastSize: CGSize = .zero
    
    init(view: NSView) {
        self.view = view
        self.lastSize = view.bounds.size
        super.init()
    }
    
    func handleSizeChange() {
        guard let view = view else { return }
        let newSize = view.bounds.size
        if newSize != lastSize {
            lastSize = newSize
            onSizeChange?(newSize)
        }
    }
    
    deinit {}
}

extension NSView {
    private static let changeListenerKey = "com.layoutengine.changelistener"
    
    private var changeListener: ViewChangeListener? {
        get {
            objc_getAssociatedObject(self, Self.changeListenerKey) as? ViewChangeListener
        }
        set {
            objc_setAssociatedObject(self, Self.changeListenerKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// Start monitoring layout changes
    public func startLayoutMonitoring(
        onSizeChange: ((CGSize) -> Void)? = nil
    ) {
        let listener = ViewChangeListener(view: self)
        listener.onSizeChange = onSizeChange
        self.changeListener = listener
    }
    
    /// Stop monitoring layout changes
    public func stopLayoutMonitoring() {
        changeListener = nil
    }
}

#endif
