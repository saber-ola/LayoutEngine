import XCTest
@testable import LayoutEngine

final class DirectionalEdgeInsetsTests: XCTestCase {
    func testResolvedLTR() {
        let insets = DirectionalEdgeInsets(top: 10, bottom: 5, leading: 20, trailing: 8)
        let physical = insets.resolved(in: .ltr)
        XCTAssertEqual(physical.top, 10)
        XCTAssertEqual(physical.bottom, 5)
        XCTAssertEqual(physical.left, 20)
        XCTAssertEqual(physical.right, 8)
    }

    func testResolvedRTL() {
        let insets = DirectionalEdgeInsets(top: 10, bottom: 5, leading: 20, trailing: 8)
        let physical = insets.resolved(in: .rtl)
        XCTAssertEqual(physical.top, 10)
        XCTAssertEqual(physical.bottom, 5)
        XCTAssertEqual(physical.left, 8)
        XCTAssertEqual(physical.right, 20)
    }

    func testZeroInsets() {
        let insets = DirectionalEdgeInsets.zero
        let physical = insets.resolved(in: .rtl)
        XCTAssertEqual(physical.top, 0)
        XCTAssertEqual(physical.bottom, 0)
        XCTAssertEqual(physical.left, 0)
        XCTAssertEqual(physical.right, 0)
    }
}
