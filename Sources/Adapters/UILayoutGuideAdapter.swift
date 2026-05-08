#if os(iOS) || os(tvOS)
import UIKit

public class LayoutGuideManager {
    weak var view: UIView?
    private var component: (any Component)?
    private var constraints: [NSLayoutConstraint] = []
    private var context: LayoutContext = .system

    public init(view: UIView) {
        self.view = view
    }

    public func setComponent(_ component: any Component) {
        self.component = component
        updateLayout()
    }

    public func setContext(_ context: LayoutContext) {
        self.context = context
        updateLayout()
    }

    private func updateLayout() {
        guard let view = view, let component = component else { return }

        view.removeConstraints(constraints)
        constraints.removeAll()

        let constraint = Constraint(maxSize: view.bounds.size)
        let renderNode = component.layout(context: context, constraint: constraint)
        _ = renderNode
    }
}

#endif
