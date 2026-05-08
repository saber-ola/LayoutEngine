import XCTest
@testable import LayoutEngine

final class LayoutContextTests: XCTestCase {
    func testLayoutDirectionAutoResolvesToSystemDefault() {
        let direction = LayoutDirection.auto
        let resolved = direction.resolved(fallback: .ltr)
        XCTAssertEqual(resolved, .ltr)
    }

    func testLayoutDirectionExplicitLTR() {
        let resolved = LayoutDirection.ltr.resolved(fallback: .rtl)
        XCTAssertEqual(resolved, .ltr)
    }

    func testLayoutDirectionExplicitRTL() {
        let resolved = LayoutDirection.rtl.resolved(fallback: .ltr)
        XCTAssertEqual(resolved, .rtl)
    }

    func testLayoutDirectionAutoResolvesToFallbackRTL() {
        let resolved = LayoutDirection.auto.resolved(fallback: .rtl)
        XCTAssertEqual(resolved, .rtl)
    }

    // MARK: - LayoutContext Tests

    func testLayoutContextSystemDefault() {
        let context = LayoutContext.system
        XCTAssertNotEqual(context.direction, .auto)
    }

    func testLayoutContextCustomDirection() {
        let context = LayoutContext(direction: .rtl)
        XCTAssertEqual(context.direction, .rtl)
    }

    func testLayoutContextResolveDirection() {
        let context = LayoutContext(direction: .rtl)
        let resolved = LayoutDirection.auto.resolved(fallback: context.direction)
        XCTAssertEqual(resolved, .rtl)
    }
}
