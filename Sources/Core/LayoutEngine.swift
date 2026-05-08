import Foundation

public class LayoutEngine {
    private var rootContext: LayoutContext

    public var onNeedsLayout: (() -> Void)?

    public init() {
        self.rootContext = .system
        setupSystemMonitoring()
    }

    public var currentDirection: LayoutDirection {
        rootContext.resolvedDirection()
    }

    public func performLayout<C: Component>(root: C, constraint: Constraint) -> C.R {
        root.layout(context: rootContext, constraint: constraint)
    }

    public func updateDirection(_ direction: LayoutDirection) {
        let newResolved = direction == .auto ? LayoutDirection.current : direction
        guard rootContext.direction != newResolved else { return }
        rootContext.direction = newResolved
        onNeedsLayout?()
    }

    public func updateLocale(_ locale: Locale) {
        let direction = LayoutDirection.fromLocale(locale)
        updateDirection(direction)
    }

    private func setupSystemMonitoring() {
        LayoutChangeMonitor.shared.onLayoutDirectionChange { [weak self] direction in
            self?.handleSystemDirectionChange(direction)
        }
    }

    private func handleSystemDirectionChange(_ direction: LayoutDirection) {
        updateDirection(direction)
    }
}
