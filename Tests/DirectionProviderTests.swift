import XCTest
@testable import LayoutEngine

private struct FixedBox: Component {
    let width: CGFloat
    let height: CGFloat

    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        BasicRenderNode(size: CGSize(width: width, height: height))
    }
}

private struct DirectionCapture: Component {
    let capture: (LayoutDirection) -> Void
    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        capture(context.resolvedDirection())
        return BasicRenderNode(size: CGSize(width: 10, height: 10))
    }
}

final class DirectionProviderTests: XCTestCase {
    func testDirectionProviderOverridesContext() {
        var receivedDirection: LayoutDirection?

        let provider = DirectionProvider(direction: .rtl) {
            DirectionCapture { receivedDirection = $0 }
        }

        let context = LayoutContext(direction: .ltr)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
        _ = provider.layout(context: context, constraint: constraint)

        XCTAssertEqual(receivedDirection, .rtl)
    }

    func testDirectionProviderNestedOverride() {
        var innerDirection: LayoutDirection?

        let outer = DirectionProvider(direction: .rtl) {
            DirectionProvider(direction: .ltr) {
                DirectionCapture { innerDirection = $0 }
            }
        }

        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
        _ = outer.layout(context: context, constraint: constraint)

        XCTAssertEqual(innerDirection, .ltr)
    }

    func testDirectionProviderAutoInheritsFromParent() {
        var receivedDirection: LayoutDirection?

        let provider = DirectionProvider(direction: .auto) {
            DirectionCapture { receivedDirection = $0 }
        }

        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
        _ = provider.layout(context: context, constraint: constraint)

        XCTAssertEqual(receivedDirection, .rtl)
    }

    func testDirectionProviderLayoutsChildren() {
        let provider = DirectionProvider(direction: .ltr) {
            FixedBox(width: 100, height: 50)
        }

        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
        let result = provider.layout(context: context, constraint: constraint)

        XCTAssertEqual(result.size, CGSize(width: 100, height: 50))
    }
}
