import Foundation

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Global monitor for layout direction and system changes
public class LayoutChangeMonitor {
    /// Singleton instance
    public static let shared = LayoutChangeMonitor()
    
    private var layoutDirectionChangeHandlers: [(LayoutDirection) -> Void] = []
    private var lastDirection: LayoutDirection = .current
    
    #if os(iOS) || os(tvOS)
    private var observer: NSObjectProtocol?
    #endif
    
    private init() {
        setupMonitoring()
    }
    
    deinit {
        #if os(iOS) || os(tvOS)
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
    }
    
    private func setupMonitoring() {
        #if os(iOS) || os(tvOS)
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didChangeUserInterfaceStyleNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkDirectionChange()
        }
        #endif
    }
    
    private func checkDirectionChange() {
        let currentDirection = LayoutDirection.current
        if currentDirection != lastDirection {
            lastDirection = currentDirection
            notifyDirectionChange(currentDirection)
        }
    }
    
    private func notifyDirectionChange(_ direction: LayoutDirection) {
        DispatchQueue.main.async {
            self.layoutDirectionChangeHandlers.forEach { handler in
                handler(direction)
            }
        }
    }
    
    /// Register a handler for layout direction changes
    public func onLayoutDirectionChange(_ handler: @escaping (LayoutDirection) -> Void) {
        layoutDirectionChangeHandlers.append(handler)
    }
    
    /// Manually trigger a check for direction changes
    public func checkAndNotifyIfChanged() {
        checkDirectionChange()
    }
}
