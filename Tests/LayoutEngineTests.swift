import XCTest
@testable import LayoutEngine

private struct DirectionReader: Component {
    let capture: (LayoutDirection) -> Void
    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        capture(context.resolvedDirection())
        return BasicRenderNode(size: CGSize(width: 10, height: 10))
    }
}

final class LayoutEngineClassTests: XCTestCase {
    func testEngineDefaultsToSystemDirection() {
        let engine = LayoutEngine()
        var received: LayoutDirection?

        let root = DirectionReader { received = $0 }
        let constraint = Constraint(maxSize: CGSize(width: 100, height: 100))
        _ = engine.performLayout(root: root, constraint: constraint)

        XCTAssertNotNil(received)
        XCTAssertNotEqual(received, .auto)
    }

    func testEngineUpdateDirection() {
        let engine = LayoutEngine()
        var received: LayoutDirection?

        engine.updateDirection(.rtl)

        let root = DirectionReader { received = $0 }
        let constraint = Constraint(maxSize: CGSize(width: 100, height: 100))
        _ = engine.performLayout(root: root, constraint: constraint)

        XCTAssertEqual(received, .rtl)
    }

    func testEngineUpdateLocaleArabic() {
        let engine = LayoutEngine()
        var received: LayoutDirection?

        let arabicLocale = Locale(identifier: "ar")
        engine.updateLocale(arabicLocale)

        let root = DirectionReader { received = $0 }
        let constraint = Constraint(maxSize: CGSize(width: 100, height: 100))
        _ = engine.performLayout(root: root, constraint: constraint)

        XCTAssertEqual(received, .rtl)
    }

    func testEngineUpdateLocaleEnglish() {
        let engine = LayoutEngine()
        var received: LayoutDirection?

        let englishLocale = Locale(identifier: "en")
        engine.updateLocale(englishLocale)

        let root = DirectionReader { received = $0 }
        let constraint = Constraint(maxSize: CGSize(width: 100, height: 100))
        _ = engine.performLayout(root: root, constraint: constraint)

        XCTAssertEqual(received, .ltr)
    }

    func testEngineInvalidationCallback() {
        let engine = LayoutEngine()
        var invalidationCount = 0

        engine.onNeedsLayout = {
            invalidationCount += 1
        }

        engine.updateDirection(.rtl)
        XCTAssertEqual(invalidationCount, 1)

        engine.updateDirection(.rtl)
        XCTAssertEqual(invalidationCount, 1)

        engine.updateDirection(.ltr)
        XCTAssertEqual(invalidationCount, 2)
    }
}
