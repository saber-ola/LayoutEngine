#if os(iOS) || os(tvOS) || os(macOS)
import SwiftUI

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct LayoutEngineView: View {
    let component: any Component
    let engine: LayoutEngine
    @State private var size: CGSize = .zero

    public init(component: any Component, engine: LayoutEngine = LayoutEngine()) {
        self.component = component
        self.engine = engine
    }

    public var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let constraint = Constraint(maxSize: geometry.size)
                let renderNode = engine.performLayout(root: AnyComponent(component), constraint: constraint)
                renderComponent(renderNode, in: &context, at: .zero)
            }
            .onAppear {
                size = geometry.size
            }
        }
    }

    private func renderComponent(
        _ renderNode: some RenderNode,
        in context: inout GraphicsContext,
        at position: CGPoint
    ) {
        // Rendering implementation depends on component types
    }
}

extension View {
    public func layoutDirection(_ direction: LayoutDirection) -> some View {
        #if os(iOS) || os(tvOS)
        return environment(\.layoutDirection, direction.isRTL ? .rightToLeft : .leftToRight)
        #else
        return self
        #endif
    }
}

#endif
