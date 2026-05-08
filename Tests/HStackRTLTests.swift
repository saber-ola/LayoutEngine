import XCTest
@testable import LayoutEngine

private struct FixedBox: Component {
    let width: CGFloat
    let height: CGFloat

    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        BasicRenderNode(size: CGSize(width: width, height: height))
    }
}

final class HStackRTLTests: XCTestCase {
    func testHStackLTRChildOrder() {
        let stack = HStack(spacing: 0, children: [FixedBox(width: 50, height: 20), FixedBox(width: 30, height: 20)])
        let context = LayoutContext(direction: .ltr)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        XCTAssertEqual(result.positions[0].x, 0)
        XCTAssertEqual(result.positions[1].x, 50)
    }

    func testHStackRTLChildOrderReversed() {
        let stack = HStack(spacing: 0, children: [FixedBox(width: 50, height: 20), FixedBox(width: 30, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        // Container width = 50+30 = 80
        // RTL: first child at x=30 (80-50=30), second at x=0
        XCTAssertEqual(result.positions[0].x, 30)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testHStackRTLWithSpacing() {
        let stack = HStack(spacing: 10, children: [FixedBox(width: 50, height: 20), FixedBox(width: 30, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        // Total width: 50+10+30 = 90
        // RTL: first child at x=40 (90-50=40), second at x=0
        XCTAssertEqual(result.positions[0].x, 40)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testHStackRTLJustifyStartMeansRight() {
        let stack = HStack(spacing: 0, justifyContent: .start, children: [FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(minSize: CGSize(width: 200, height: 0), maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL + .start (mirrored to .end offset) => child at right: x = 200 - 50 = 150
        XCTAssertEqual(result.positions[0].x, 150)
    }

    func testHStackRTLJustifyEndMeansLeft() {
        let stack = HStack(spacing: 0, justifyContent: .end, children: [FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(minSize: CGSize(width: 200, height: 0), maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL + .end (mirrored to .start offset=0) => x = 200 - (0 + 50) = 150... wait
        // Actually: .end mirrored = .start, so offset=0 from distribute
        // Then RTL mirror: x = 200 - (0 + 50) = 150? No...
        // Let me think: effectiveJustify = .end.mirrored = .start
        // distribute with .start => offset=0, spacing=0
        // primaryOffset starts at 0, node width=50
        // RTL: x = containerWidth - (primaryOffset + nodeWidth) = 200 - (0 + 50) = 150
        // Hmm that's same as .start in RTL. Let me reconsider.
        //
        // Actually .end in RTL should mean "at the left side" = x=0
        // effectiveJustify = .end.mirrored = .start => offset=0
        // In LTR with .start, offset=0 means items at left
        // In RTL mirror: x = 200 - (0+50) = 150. That puts it at right side.
        //
        // The issue: mirroring justifyContent AND mirroring positions double-mirrors.
        // We should only mirror positions, NOT justifyContent.
        // Let me re-check the design...
        //
        // Per design: RTL flips child order + position mirroring.
        // .start/.end semantic meaning flips: RTL .start = right, RTL .end = left
        // So .end in RTL => left side => x = 0
        XCTAssertEqual(result.positions[0].x, 0)
    }

    func testHStackContextPassedToChildren() {
        var receivedDirection: LayoutDirection?

        struct DirectionCapture: Component {
            let capture: (LayoutDirection) -> Void
            func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
                capture(context.resolvedDirection())
                return BasicRenderNode(size: CGSize(width: 10, height: 10))
            }
        }

        let stack = HStack(spacing: 0, children: [DirectionCapture { receivedDirection = $0 }])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        _ = stack.layout(context: context, constraint: constraint)

        XCTAssertEqual(receivedDirection, .rtl)
    }
}
