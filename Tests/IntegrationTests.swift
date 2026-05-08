import XCTest
@testable import LayoutEngine

private struct FixedBox: Component {
    let width: CGFloat
    let height: CGFloat

    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        BasicRenderNode(size: CGSize(width: width, height: height))
    }
}

final class IntegrationTests: XCTestCase {
    func testNestedStacksRTL() {
        let inner = VStack(spacing: 5, alignItems: .start, children: [
            FixedBox(width: 20, height: 10),
            FixedBox(width: 30, height: 10)
        ])
        let stack = HStack(spacing: 10, children: [
            FixedBox(width: 40, height: 25),
            inner
        ])

        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 300, height: 300))
        let result = stack.layout(context: context, constraint: constraint)

        // HStack total: 40 + 10 + 30(inner VStack crossMax) = 80
        XCTAssertEqual(result.size.width, 80)

        // RTL: first child (40px) at right: x = 80 - 0 - 40 = 40
        XCTAssertEqual(result.positions[0].x, 40)
        // Second child (30px VStack) at left: x = 80 - 50 - 30 = 0
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testDirectionProviderLocalOverride() {
        var outerDirection: LayoutDirection?
        var innerDirection: LayoutDirection?

        struct DirectionCapture: Component {
            let capture: (LayoutDirection) -> Void
            func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
                capture(context.resolvedDirection())
                return BasicRenderNode(size: CGSize(width: 10, height: 10))
            }
        }

        let tree = HStack(spacing: 0, children: [
            DirectionCapture { outerDirection = $0 },
            DirectionProvider(direction: .ltr) {
                DirectionCapture { innerDirection = $0 }
            }
        ])

        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
        _ = tree.layout(context: context, constraint: constraint)

        XCTAssertEqual(outerDirection, .rtl)
        XCTAssertEqual(innerDirection, .ltr)
    }

    func testLayoutEngineEndToEnd() {
        let engine = LayoutEngine()
        engine.updateDirection(.rtl)

        let stack = HStack(spacing: 0, children: [
            FixedBox(width: 50, height: 20),
            FixedBox(width: 30, height: 20)
        ])

        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        let result = engine.performLayout(root: stack, constraint: constraint)

        // RTL: container width = 80, first at x=30, second at x=0
        XCTAssertEqual(result.positions[0].x, 30)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testLayoutEngineLocaleSwitch() {
        let engine = LayoutEngine()
        var results: [LayoutDirection] = []

        struct DirectionReader: Component {
            let capture: (LayoutDirection) -> Void
            func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
                capture(context.resolvedDirection())
                return BasicRenderNode(size: CGSize(width: 10, height: 10))
            }
        }

        let constraint = Constraint(maxSize: CGSize(width: 100, height: 100))

        engine.updateLocale(Locale(identifier: "en"))
        _ = engine.performLayout(root: DirectionReader { results.append($0) }, constraint: constraint)

        engine.updateLocale(Locale(identifier: "ar"))
        _ = engine.performLayout(root: DirectionReader { results.append($0) }, constraint: constraint)

        XCTAssertEqual(results, [.ltr, .rtl])
    }

    func testDirectionalInsetsWithRTL() {
        let box = FixedBox(width: 100, height: 50)
            .directionalInset(DirectionalEdgeInsets(top: 10, bottom: 10, leading: 20, trailing: 5))

        let ltrContext = LayoutContext(direction: .ltr)
        let rtlContext = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))

        let ltrResult = box.layout(context: ltrContext, constraint: constraint)
        let rtlResult = box.layout(context: rtlContext, constraint: constraint)

        // LTR: leading=20 is left, trailing=5 is right
        XCTAssertEqual(ltrResult.positions[0], CGPoint(x: 20, y: 10))
        XCTAssertEqual(ltrResult.size, CGSize(width: 125, height: 70))

        // RTL: leading=20 becomes right, trailing=5 becomes left
        XCTAssertEqual(rtlResult.positions[0], CGPoint(x: 5, y: 10))
        XCTAssertEqual(rtlResult.size, CGSize(width: 125, height: 70))
    }
}
