#if os(iOS) || os(tvOS) || os(macOS)
import SwiftUI

/// SwiftUI view that renders a LayoutEngine component
public struct LayoutEngineView: View {
    let component: any Component
    @State private var size: CGSize = .zero
    @State private var layoutDirection: LayoutDirection = .current
    
    public init(component: any Component) {
        self.component = component
    }
    
    public var body: some View {
        GeometryReader { geometry in
            Canvas { context in
                let constraint = Constraint(maxSize: geometry.size)
                let renderNode = component.layout(constraint)
                
                // Render based on render node
                renderComponent(renderNode, in: &context, at: .zero)
            }
            .onAppear {
                size = geometry.size
            }
            .onChange(of: geometry.size) { newSize in
                size = newSize
            }
        }
    }
    
    private func renderComponent(
        _ renderNode: any RenderNode,
        in context: inout GraphicsContext,
        at position: CGPoint
    ) {
        // This is a basic placeholder
        // Actual rendering depends on component types
    }
}

// MARK: - SwiftUI Modifier

extension View {
    /// Apply layout direction to a view
    public func layoutDirection(_ direction: LayoutDirection) -> some View {
        #if os(iOS) || os(tvOS)
        return environment(\.layoutDirection, direction.isRTL ? .rightToLeft : .leftToRight)
        #else
        return self
        #endif
    }
}

#endif
