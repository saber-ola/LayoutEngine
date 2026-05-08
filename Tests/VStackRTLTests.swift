import XCTest
@testable import LayoutEngine

private struct FixedBox: Component {
    let width: CGFloat
    let height: CGFloat

    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        BasicRenderNode(size: CGSize(width: width, height: height))
    }
}

final class VStackRTLTests: XCTestCase {
    func testVStackLTRCrossAxisStart() {
        let stack = VStack(spacing: 0, alignItems: .start, children: [FixedBox(width: 30, height: 20), FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .ltr)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 400))
        let result = stack.layout(context: context, constraint: constraint)

        XCTAssertEqual(result.positions[0].x, 0)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testVStackRTLCrossAxisStartMeansRight() {
        let stack = VStack(spacing: 0, alignItems: .start, children: [FixedBox(width: 30, height: 20), FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 400))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL + .start mirrored to .end => aligned to right edge of cross axis
        // crossMax = 50, first child width=30: x = 50 - 30 = 20
        // second child width=50: x = 50 - 50 = 0
        XCTAssertEqual(result.positions[0].x, 20)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testVStackRTLCrossAxisEndMeansLeft() {
        let stack = VStack(spacing: 0, alignItems: .end, children: [FixedBox(width: 30, height: 20), FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 400))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL + .end mirrored to .start => x=0 for all
        XCTAssertEqual(result.positions[0].x, 0)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testVStackRTLMainAxisUnchanged() {
        let stack = VStack(spacing: 10, children: [FixedBox(width: 30, height: 20), FixedBox(width: 30, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 400))
        let result = stack.layout(context: context, constraint: constraint)

        XCTAssertEqual(result.positions[0].y, 0)
        XCTAssertEqual(result.positions[1].y, 30)
    }

    func testVStackContextPassedToChildren() {
        var receivedDirection: LayoutDirection?

        struct DirectionCapture: Component {
            let capture: (LayoutDirection) -> Void
            func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
                capture(context.resolvedDirection())
                return BasicRenderNode(size: CGSize(width: 10, height: 10))
            }
        }

        let stack = VStack(spacing: 0, children: [DirectionCapture { receivedDirection = $0 }])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        _ = stack.layout(context: context, constraint: constraint)

        XCTAssertEqual(receivedDirection, .rtl)
    }
}
