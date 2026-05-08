#if os(iOS) || os(tvOS)
import UIKit

// MARK: - UIViewController Extension

extension UIViewController {
    private static let traitCollectionObserverKey = "com.layoutengine.traitcollectionobserver"
    
    /// Enable RTL monitoring for this view controller
    public func enableLayoutEngineRTLMonitoring(_ handler: @escaping (LayoutDirection) -> Void) {
        let observer = TraitCollectionObserver(viewController: self, handler: handler)
        objc_setAssociatedObject(self, Self.traitCollectionObserverKey, observer, .OBJC_ASSOCIATION_RETAIN)
    }
}

// MARK: - Trait Collection Observer

private class TraitCollectionObserver {
    weak var viewController: UIViewController?
    let handler: (LayoutDirection) -> Void
    var lastDirection: LayoutDirection = .current
    
    init(viewController: UIViewController, handler: @escaping (LayoutDirection) -> Void) {
        self.viewController = viewController
        self.handler = handler
        
        // Swizzle traitCollectionDidChange
        let originalMethod = #selector(UIViewController.traitCollectionDidChange(_:))
        let swizzledMethod = #selector(UIViewController.layoutEngine_traitCollectionDidChange(_:))
        
        guard let originalSel = class_getInstanceMethod(UIViewController.self, originalMethod),
              let swizzledSel = class_getInstanceMethod(UIViewController.self, swizzledMethod) else {
            return
        }
        
        method_exchangeImplementations(originalSel, swizzledSel)
    }
}

// MARK: - Swizzling

extension UIViewController {
    @objc func layoutEngine_traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Call original implementation
        layoutEngine_traitCollectionDidChange(previousTraitCollection)
        
        // Check for direction change
        let currentDirection = LayoutDirection.current
        if let container = objc_getAssociatedObject(self, UIViewController.traitCollectionObserverKey) as? TraitCollectionObserver {
            if currentDirection != container.lastDirection {
                container.lastDirection = currentDirection
                container.handler(currentDirection)
            }
        }
    }
}

#endif
