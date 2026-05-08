# RTL Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove RTLHStack/RTLVStack and make HStack/VStack handle RTL internally via LayoutContext, with automatic direction detection and refresh.

**Architecture:** Add `LayoutContext` struct passed through `layout(context:constraint:)`. Direction resolved from context (which flows down the tree). `DirectionProvider` overrides direction for subtrees. `LayoutEngine` class manages root context and invalidation.

**Tech Stack:** Swift 5.9, SPM, CoreGraphics, UIKit/AppKit (platform-conditional)

---

## File Structure

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `Sources/Core/LayoutContext.swift` | LayoutContext struct and LayoutDirection.resolved(from:) |
| Create | `Sources/Core/DirectionalEdgeInsets.swift` | Directional (logical) edge insets with resolution |
| Create | `Sources/Layouts/DirectionProvider.swift` | Container component that overrides direction in context |
| Create | `Sources/Core/LayoutEngine.swift` | Root context management, invalidation, locale update API |
| Modify | `Sources/RTL/LayoutDirection.swift` | Add `.auto` case and `resolved(from:)` method |
| Modify | `Sources/Components/Component.swift` | Change `layout(_:)` → `layout(context:constraint:)` |
| Modify | `Sources/Core/LayoutProtocols.swift` | Update protocol signatures, add `MainAxisAlignment.mirrored` |
| Modify | `Sources/Layouts/Stack.swift` | Add RTL logic to HStack/VStack, update layout signatures |
| Modify | `Sources/Layouts/Insets.swift` | Support DirectionalEdgeInsets |
| Modify | `Sources/Monitoring/LayoutChangeMonitor.swift` | Wire into LayoutEngine invalidation |
| Modify | `Sources/Adapters/SwiftUIAdapter.swift` | Pass LayoutContext through |
| Modify | `Sources/Adapters/UIKitAdapter.swift` | Pass LayoutContext through |
| Delete | `Sources/RTL/RTLComponent.swift` | Replaced by HStack/VStack internal RTL |
| Create | `Tests/LayoutContextTests.swift` | LayoutContext and direction resolution tests |
| Create | `Tests/DirectionalEdgeInsetsTests.swift` | Edge insets resolution tests |
| Create | `Tests/HStackRTLTests.swift` | HStack RTL layout correctness |
| Create | `Tests/VStackRTLTests.swift` | VStack cross-axis RTL correctness |
| Create | `Tests/DirectionProviderTests.swift` | Nesting and override tests |
| Create | `Tests/LayoutEngineTests.swift` | Engine invalidation and locale update tests |

---

## Task 1: Add `.auto` case to LayoutDirection

**Files:**
- Modify: `Sources/RTL/LayoutDirection.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/LayoutContextTests.swift`:

```swift
import XCTest
@testable import LayoutEngine

final class LayoutContextTests: XCTestCase {
    func testLayoutDirectionAutoResolvesToSystemDefault() {
        let direction = LayoutDirection.auto
        let resolved = direction.resolved(fallback: .ltr)
        // .auto with fallback .ltr should resolve to .ltr
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LayoutContextTests`
Expected: FAIL — `auto` case and `resolved(fallback:)` method don't exist yet.

- [ ] **Step 3: Implement `.auto` case and `resolved(fallback:)` method**

Modify `Sources/RTL/LayoutDirection.swift` — add `.auto` case:

```swift
public enum LayoutDirection: Hashable {
    case ltr
    case rtl
    case auto

    public var isRTL: Bool {
        self == .rtl
    }

    public func resolved(fallback: LayoutDirection) -> LayoutDirection {
        switch self {
        case .ltr: return .ltr
        case .rtl: return .rtl
        case .auto: return fallback == .auto ? .current : fallback
        }
    }

    // ... existing static methods unchanged ...
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LayoutContextTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/RTL/LayoutDirection.swift Tests/LayoutContextTests.swift
git commit -m "feat: add .auto case and resolved(fallback:) to LayoutDirection"
```

---

## Task 2: Create LayoutContext

**Files:**
- Create: `Sources/Core/LayoutContext.swift`
- Modify: `Tests/LayoutContextTests.swift`

- [ ] **Step 1: Write the failing test**

Add to `Tests/LayoutContextTests.swift`:

```swift
func testLayoutContextSystemDefault() {
    let context = LayoutContext.system
    // Should resolve to a concrete direction (ltr or rtl), not .auto
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LayoutContextTests`
Expected: FAIL — `LayoutContext` doesn't exist yet.

- [ ] **Step 3: Create LayoutContext**

Create `Sources/Core/LayoutContext.swift`:

```swift
import Foundation

public struct LayoutContext {
    public var direction: LayoutDirection

    public init(direction: LayoutDirection = .auto) {
        self.direction = direction
    }

    public static var system: LayoutContext {
        LayoutContext(direction: .current)
    }

    public func resolvedDirection() -> LayoutDirection {
        direction == .auto ? .current : direction
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LayoutContextTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Core/LayoutContext.swift Tests/LayoutContextTests.swift
git commit -m "feat: add LayoutContext struct"
```

---

## Task 3: Create DirectionalEdgeInsets

**Files:**
- Create: `Sources/Core/DirectionalEdgeInsets.swift`
- Create: `Tests/DirectionalEdgeInsetsTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/DirectionalEdgeInsetsTests.swift`:

```swift
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
        XCTAssertEqual(physical.left, 8)   // trailing becomes left in RTL
        XCTAssertEqual(physical.right, 20)  // leading becomes right in RTL
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter DirectionalEdgeInsetsTests`
Expected: FAIL — `DirectionalEdgeInsets` doesn't exist.

- [ ] **Step 3: Implement DirectionalEdgeInsets**

Create `Sources/Core/DirectionalEdgeInsets.swift`:

```swift
import CoreGraphics

public struct DirectionalEdgeInsets: Equatable {
    public var top: CGFloat
    public var bottom: CGFloat
    public var leading: CGFloat
    public var trailing: CGFloat

    public init(top: CGFloat = 0, bottom: CGFloat = 0, leading: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.bottom = bottom
        self.leading = leading
        self.trailing = trailing
    }

    public static var zero: DirectionalEdgeInsets {
        DirectionalEdgeInsets()
    }

    public func resolved(in direction: LayoutDirection) -> PhysicalEdgeInsets {
        switch direction {
        case .rtl:
            return PhysicalEdgeInsets(top: top, left: trailing, bottom: bottom, right: leading)
        case .ltr, .auto:
            return PhysicalEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        }
    }
}

public struct PhysicalEdgeInsets: Equatable {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat

    public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public var asUIEdgeInsets: UIEdgeInsets {
        UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter DirectionalEdgeInsetsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Core/DirectionalEdgeInsets.swift Tests/DirectionalEdgeInsetsTests.swift
git commit -m "feat: add DirectionalEdgeInsets with physical resolution"
```

---

## Task 4: Update Component protocol to accept LayoutContext

**Files:**
- Modify: `Sources/Components/Component.swift`
- Modify: `Sources/Core/LayoutProtocols.swift`

- [ ] **Step 1: Update Component protocol**

Modify `Sources/Components/Component.swift`:

```swift
import CoreGraphics

public protocol Component {
    associatedtype R: RenderNode

    func layout(context: LayoutContext, constraint: Constraint) -> R
}

public struct AnyComponent: Component {
    private let layoutFn: (LayoutContext, Constraint) -> any RenderNode

    public init<C: Component>(_ component: C) {
        self.layoutFn = { context, constraint in
            component.layout(context: context, constraint: constraint)
        }
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> any RenderNode {
        layoutFn(context, constraint)
    }
}

@resultBuilder
public struct ComponentBuilder {
    public static func buildBlock(_ components: any Component...) -> [any Component] {
        components
    }

    public static func buildOptional(_ component: [any Component]?) -> [any Component] {
        component ?? []
    }

    public static func buildEither(first: [any Component]) -> [any Component] {
        first
    }

    public static func buildEither(second: [any Component]) -> [any Component] {
        second
    }
}
```

- [ ] **Step 2: Update BaseLayoutProtocol**

Modify `Sources/Core/LayoutProtocols.swift` — update `BaseLayoutProtocol`:

```swift
public protocol BaseLayoutProtocol {
    associatedtype R: RenderNode
    func layout(context: LayoutContext, constraint: Constraint) -> R
}
```

Add `MainAxisAlignment.mirrored`:

```swift
extension MainAxisAlignment {
    public var mirrored: MainAxisAlignment {
        switch self {
        case .start: return .end
        case .end: return .start
        case .center: return .center
        case .spaceBetween: return .spaceBetween
        case .spaceAround: return .spaceAround
        case .spaceEvenly: return .spaceEvenly
        }
    }
}

extension CrossAxisAlignment {
    public var mirrored: CrossAxisAlignment {
        switch self {
        case .start: return .end
        case .end: return .start
        case .center: return .center
        case .stretch: return .stretch
        case .baselineFirst: return .baselineFirst
        case .baselineLast: return .baselineLast
        }
    }
}
```

- [ ] **Step 3: Fix all compilation errors from signature change**

This step requires updating every file that uses `layout(_:)`. The compiler will guide you. All components must change from `func layout(_ constraint: Constraint)` to `func layout(context: LayoutContext, constraint: Constraint)`.

Files to update:
- `Sources/Layouts/Stack.swift` (HStack, VStack, Spacer) — update signatures, pass context to children
- `Sources/Layouts/Insets.swift` — update signature, pass context to content
- `Sources/Adapters/SwiftUIAdapter.swift` — pass `LayoutContext.system` at call site

- [ ] **Step 4: Verify compilation**

Run: `swift build`
Expected: BUILD SUCCEEDED (no tests yet, just compilation)

- [ ] **Step 5: Commit**

```bash
git add Sources/Components/Component.swift Sources/Core/LayoutProtocols.swift Sources/Layouts/Stack.swift Sources/Layouts/Insets.swift Sources/Adapters/SwiftUIAdapter.swift
git commit -m "refactor: update Component protocol to accept LayoutContext"
```

---

## Task 5: Add RTL logic to HStack

**Files:**
- Modify: `Sources/Layouts/Stack.swift`
- Create: `Tests/HStackRTLTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/HStackRTLTests.swift`:

```swift
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

        // LTR: first child at x=0, second at x=50
        XCTAssertEqual(result.positions[0].x, 0)
        XCTAssertEqual(result.positions[1].x, 50)
    }

    func testHStackRTLChildOrderReversed() {
        let stack = HStack(spacing: 0, children: [FixedBox(width: 50, height: 20), FixedBox(width: 30, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL: first child at right side (x=150), second at x=170 ... wait
        // Actually in RTL, the first child should be placed at the right,
        // and the second child placed to the left of it.
        // Container width is determined by content: 50+30=80
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

        // RTL + .start => child placed at right edge: x = 200 - 50 = 150
        XCTAssertEqual(result.positions[0].x, 150)
    }

    func testHStackRTLJustifyEndMeansLeft() {
        let stack = HStack(spacing: 0, justifyContent: .end, children: [FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(minSize: CGSize(width: 200, height: 0), maxSize: CGSize(width: 200, height: 100))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL + .end => child placed at left edge: x = 0
        XCTAssertEqual(result.positions[0].x, 0)
    }

    func testHStackContextPassedToChildren() {
        // Verify children receive the context
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HStackRTLTests`
Expected: FAIL — HStack doesn't have RTL logic yet.

- [ ] **Step 3: Implement RTL in HStack**

Modify HStack's `layout(context:constraint:)` in `Sources/Layouts/Stack.swift`:

```swift
public func layout(context: LayoutContext, constraint: Constraint) -> HStackRenderNode {
    let resolvedDirection = context.resolvedDirection()
    var renderNodes: [any RenderNode] = []

    let childConstraint = Constraint(
        minSize: CGSize(width: -.infinity, height: alignItems == .stretch ? constraint.maxSize.height : 0),
        maxSize: CGSize(width: .infinity, height: constraint.maxSize.height)
    )

    for child in children {
        renderNodes.append(child.layout(context: context, constraint: childConstraint))
    }

    let crossMax = renderNodes.reduce(0) { max($0, $1.size.height) }
    let mainTotal = renderNodes.reduce(0) { $0 + $1.size.width }
    let maxPrimary = constraint.maxSize.width
    let minPrimary = constraint.minSize.width
    let primaryBound = minPrimary > 0 ? minPrimary : maxPrimary

    let effectiveJustify = resolvedDirection.isRTL ? justifyContent.mirrored : justifyContent

    let (offset, distributedSpacing) = LayoutHelper.distribute(
        justifyContent: effectiveJustify,
        maxPrimary: primaryBound,
        totalPrimary: mainTotal,
        minimumSpacing: spacing,
        numberOfItems: children.count
    )

    var positions: [CGPoint] = []
    var primaryOffset = offset

    for node in renderNodes {
        var crossValue: CGFloat = 0
        switch alignItems {
        case .start, .baselineFirst:
            crossValue = 0
        case .end, .baselineLast:
            crossValue = crossMax - node.size.height
        case .center:
            crossValue = (crossMax - node.size.height) / 2
        case .stretch:
            crossValue = 0
        }

        let x: CGFloat
        if resolvedDirection.isRTL {
            let intrinsicMain = mainTotal + distributedSpacing * CGFloat(renderNodes.count - 1)
            let containerWidth = max(primaryBound.isInfinite ? intrinsicMain : primaryBound, intrinsicMain)
            x = containerWidth - (primaryOffset + node.size.width)
        } else {
            x = primaryOffset
        }

        positions.append(CGPoint(x: x, y: crossValue))
        primaryOffset += node.size.width + distributedSpacing
    }

    let intrinsicMain = primaryOffset - distributedSpacing
    let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
    let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)

    return HStackRenderNode(
        size: CGSize(width: finalMain, height: crossMax),
        children: renderNodes,
        positions: positions
    )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HStackRTLTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Layouts/Stack.swift Tests/HStackRTLTests.swift
git commit -m "feat: add RTL support to HStack layout"
```

---

## Task 6: Add RTL logic to VStack (cross-axis)

**Files:**
- Modify: `Sources/Layouts/Stack.swift`
- Create: `Tests/VStackRTLTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/VStackRTLTests.swift`:

```swift
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

        // LTR + .start => x=0
        XCTAssertEqual(result.positions[0].x, 0)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testVStackRTLCrossAxisStartMeansRight() {
        let stack = VStack(spacing: 0, alignItems: .start, children: [FixedBox(width: 30, height: 20), FixedBox(width: 50, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 400))
        let result = stack.layout(context: context, constraint: constraint)

        // RTL + .start => aligned to right edge of cross axis
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

        // RTL + .end => aligned to left edge: x=0
        XCTAssertEqual(result.positions[0].x, 0)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testVStackRTLMainAxisUnchanged() {
        let stack = VStack(spacing: 10, children: [FixedBox(width: 30, height: 20), FixedBox(width: 30, height: 20)])
        let context = LayoutContext(direction: .rtl)
        let constraint = Constraint(maxSize: CGSize(width: 200, height: 400))
        let result = stack.layout(context: context, constraint: constraint)

        // Main axis (vertical) should not be affected by RTL
        XCTAssertEqual(result.positions[0].y, 0)
        XCTAssertEqual(result.positions[1].y, 30) // 20 + 10 spacing
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter VStackRTLTests`
Expected: FAIL — VStack doesn't have RTL cross-axis logic.

- [ ] **Step 3: Implement RTL cross-axis in VStack**

Modify VStack's `layout(context:constraint:)` in `Sources/Layouts/Stack.swift`:

```swift
public func layout(context: LayoutContext, constraint: Constraint) -> VStackRenderNode {
    let resolvedDirection = context.resolvedDirection()
    var renderNodes: [any RenderNode] = []

    let childConstraint = Constraint(
        minSize: CGSize(width: alignItems == .stretch ? constraint.maxSize.width : 0, height: -.infinity),
        maxSize: CGSize(width: constraint.maxSize.width, height: .infinity)
    )

    for child in children {
        renderNodes.append(child.layout(context: context, constraint: childConstraint))
    }

    let crossMax = renderNodes.reduce(0) { max($0, $1.size.width) }
    let mainTotal = renderNodes.reduce(0) { $0 + $1.size.height }
    let maxPrimary = constraint.maxSize.height
    let minPrimary = constraint.minSize.height
    let primaryBound = minPrimary > 0 ? minPrimary : maxPrimary

    let (offset, distributedSpacing) = LayoutHelper.distribute(
        justifyContent: justifyContent,
        maxPrimary: primaryBound,
        totalPrimary: mainTotal,
        minimumSpacing: spacing,
        numberOfItems: children.count
    )

    var positions: [CGPoint] = []
    var primaryOffset = offset

    for node in renderNodes {
        let effectiveAlign = resolvedDirection.isRTL ? alignItems.mirrored : alignItems

        var crossValue: CGFloat = 0
        switch effectiveAlign {
        case .start, .baselineFirst:
            crossValue = 0
        case .end, .baselineLast:
            crossValue = crossMax - node.size.width
        case .center:
            crossValue = (crossMax - node.size.width) / 2
        case .stretch:
            crossValue = 0
        }

        positions.append(CGPoint(x: crossValue, y: primaryOffset))
        primaryOffset += node.size.height + distributedSpacing
    }

    let intrinsicMain = primaryOffset - distributedSpacing
    let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
    let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)

    return VStackRenderNode(
        size: CGSize(width: crossMax, height: finalMain),
        children: renderNodes,
        positions: positions
    )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter VStackRTLTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Layouts/Stack.swift Tests/VStackRTLTests.swift
git commit -m "feat: add RTL cross-axis support to VStack"
```

---

## Task 7: Create DirectionProvider

**Files:**
- Create: `Sources/Layouts/DirectionProvider.swift`
- Create: `Tests/DirectionProviderTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/DirectionProviderTests.swift`:

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter DirectionProviderTests`
Expected: FAIL — `DirectionProvider` doesn't exist.

- [ ] **Step 3: Implement DirectionProvider**

Create `Sources/Layouts/DirectionProvider.swift`:

```swift
import CoreGraphics

public struct DirectionProvider: Component {
    public let direction: LayoutDirection
    public let children: [any Component]

    public init(
        direction: LayoutDirection,
        @ComponentBuilder _ content: () -> [any Component] = { [] }
    ) {
        self.direction = direction
        self.children = content()
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> DirectionProviderRenderNode {
        var childContext = context
        let resolved = direction.resolved(fallback: context.resolvedDirection())
        childContext.direction = resolved

        var childNodes: [any RenderNode] = []
        var positions: [CGPoint] = []
        var maxWidth: CGFloat = 0
        var yOffset: CGFloat = 0

        for child in children {
            let node = child.layout(context: childContext, constraint: constraint)
            childNodes.append(node)
            positions.append(CGPoint(x: 0, y: yOffset))
            maxWidth = max(maxWidth, node.size.width)
            yOffset += node.size.height
        }

        return DirectionProviderRenderNode(
            size: CGSize(width: maxWidth, height: yOffset),
            children: childNodes,
            positions: positions
        )
    }
}

public struct DirectionProviderRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter DirectionProviderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Layouts/DirectionProvider.swift Tests/DirectionProviderTests.swift
git commit -m "feat: add DirectionProvider component"
```

---

## Task 8: Create LayoutEngine class with invalidation

**Files:**
- Create: `Sources/Core/LayoutEngine.swift`
- Create: `Tests/LayoutEngineTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Tests/LayoutEngineTests.swift`:

```swift
import XCTest
@testable import LayoutEngine

private struct FixedBox: Component {
    let width: CGFloat
    let height: CGFloat

    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        BasicRenderNode(size: CGSize(width: width, height: height))
    }
}

private struct DirectionReader: Component {
    let capture: (LayoutDirection) -> Void
    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        capture(context.resolvedDirection())
        return BasicRenderNode(size: CGSize(width: 10, height: 10))
    }
}

final class LayoutEngineTests: XCTestCase {
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

    func testEngineUpdateLocale() {
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

        // Same direction should not trigger
        engine.updateDirection(.rtl)
        XCTAssertEqual(invalidationCount, 1)

        engine.updateDirection(.ltr)
        XCTAssertEqual(invalidationCount, 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LayoutEngineTests`
Expected: FAIL — `LayoutEngine` class doesn't exist.

- [ ] **Step 3: Implement LayoutEngine**

Create `Sources/Core/LayoutEngine.swift`:

```swift
import Foundation

public class LayoutEngine {
    private var rootContext: LayoutContext

    public var onNeedsLayout: (() -> Void)?

    public init() {
        self.rootContext = .system
        setupSystemMonitoring()
    }

    public var currentDirection: LayoutDirection {
        rootContext.resolvedDirection()
    }

    public func performLayout<C: Component>(root: C, constraint: Constraint) -> C.R {
        root.layout(context: rootContext, constraint: constraint)
    }

    public func updateDirection(_ direction: LayoutDirection) {
        let newResolved = direction == .auto ? LayoutDirection.current : direction
        guard rootContext.direction != newResolved else { return }
        rootContext.direction = newResolved
        onNeedsLayout?()
    }

    public func updateLocale(_ locale: Locale) {
        let direction = LayoutDirection.fromLocale(locale)
        updateDirection(direction)
    }

    private func setupSystemMonitoring() {
        LayoutChangeMonitor.shared.onLayoutDirectionChange { [weak self] direction in
            self?.handleSystemDirectionChange(direction)
        }
    }

    private func handleSystemDirectionChange(_ direction: LayoutDirection) {
        updateDirection(direction)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LayoutEngineTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Core/LayoutEngine.swift Tests/LayoutEngineTests.swift
git commit -m "feat: add LayoutEngine class with invalidation and locale update"
```

---

## Task 9: Update Insets to support DirectionalEdgeInsets

**Files:**
- Modify: `Sources/Layouts/Insets.swift`

- [ ] **Step 1: Write the failing test**

Add to `Tests/DirectionalEdgeInsetsTests.swift`:

```swift
func testDirectionalInsetsComponent() {
    struct FixedBox: Component {
        func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
            BasicRenderNode(size: CGSize(width: 100, height: 50))
        }
    }

    let component = FixedBox().directionalInset(DirectionalEdgeInsets(top: 10, bottom: 10, leading: 20, trailing: 5))
    let context = LayoutContext(direction: .ltr)
    let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
    let result = component.layout(context: context, constraint: constraint)

    // Size should be content + insets: (100+20+5, 50+10+10) = (125, 70)
    XCTAssertEqual(result.size.width, 125)
    XCTAssertEqual(result.size.height, 70)
    // Child positioned at (left=leading=20, top=10)
    XCTAssertEqual(result.positions[0], CGPoint(x: 20, y: 10))
}

func testDirectionalInsetsComponentRTL() {
    struct FixedBox: Component {
        func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
            BasicRenderNode(size: CGSize(width: 100, height: 50))
        }
    }

    let component = FixedBox().directionalInset(DirectionalEdgeInsets(top: 10, bottom: 10, leading: 20, trailing: 5))
    let context = LayoutContext(direction: .rtl)
    let constraint = Constraint(maxSize: CGSize(width: 200, height: 200))
    let result = component.layout(context: context, constraint: constraint)

    // RTL: leading=20 becomes right, trailing=5 becomes left
    // Size: (100+20+5, 50+10+10) = (125, 70)
    XCTAssertEqual(result.size.width, 125)
    XCTAssertEqual(result.size.height, 70)
    // Child positioned at (left=trailing=5, top=10)
    XCTAssertEqual(result.positions[0], CGPoint(x: 5, y: 10))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter DirectionalEdgeInsetsTests`
Expected: FAIL — `directionalInset` method doesn't exist.

- [ ] **Step 3: Implement DirectionalInsets component**

Add to `Sources/Layouts/Insets.swift`:

```swift
public struct DirectionalInsets: Component {
    let content: any Component
    let insets: DirectionalEdgeInsets

    public init(content: any Component, insets: DirectionalEdgeInsets) {
        self.content = content
        self.insets = insets
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> InsetRenderNode {
        let physical = insets.resolved(in: context.resolvedDirection())
        let uiInsets = physical.asUIEdgeInsets
        let insetConstraint = constraint.inset(by: uiInsets)
        let contentNode = content.layout(context: context, constraint: insetConstraint)

        return InsetRenderNode(
            size: contentNode.size.inset(by: -uiInsets),
            content: contentNode,
            insets: uiInsets
        )
    }
}

extension Component {
    public func directionalInset(_ insets: DirectionalEdgeInsets) -> some Component {
        DirectionalInsets(content: self, insets: insets)
    }
}
```

Also update existing `Insets` struct to accept context:

```swift
public struct Insets: Component {
    let content: any Component
    let insets: UIEdgeInsets

    public init(content: any Component, insets: UIEdgeInsets) {
        self.content = content
        self.insets = insets
    }

    public func layout(context: LayoutContext, constraint: Constraint) -> InsetRenderNode {
        let insetConstraint = constraint.inset(by: insets)
        let contentNode = content.layout(context: context, constraint: insetConstraint)

        return InsetRenderNode(
            size: contentNode.size.inset(by: -insets),
            content: contentNode,
            insets: insets
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter DirectionalEdgeInsetsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/Layouts/Insets.swift Tests/DirectionalEdgeInsetsTests.swift
git commit -m "feat: add DirectionalInsets component with RTL-aware edge insets"
```

---

## Task 10: Update adapters

**Files:**
- Modify: `Sources/Adapters/SwiftUIAdapter.swift`
- Modify: `Sources/Adapters/UIKitAdapter.swift`

- [ ] **Step 1: Update SwiftUIAdapter**

Modify `Sources/Adapters/SwiftUIAdapter.swift`:

```swift
#if os(iOS) || os(tvOS) || os(macOS)
import SwiftUI

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
            Canvas { context in
                let constraint = Constraint(maxSize: geometry.size)
                let renderNode = engine.performLayout(root: AnyComponent(component), constraint: constraint)
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
        // Rendering implementation
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
```

- [ ] **Step 2: Update UIKitAdapter — no functional changes needed**

The `UIKitAdapter.swift` uses `LayoutDirection.current` already and hooks into trait collection changes. It remains compatible since `LayoutChangeMonitor` still works the same way. No changes needed.

- [ ] **Step 3: Verify compilation**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Sources/Adapters/SwiftUIAdapter.swift
git commit -m "refactor: update SwiftUIAdapter to use LayoutEngine"
```

---

## Task 11: Delete RTLComponent.swift

**Files:**
- Delete: `Sources/RTL/RTLComponent.swift`

- [ ] **Step 1: Verify no remaining references to RTLHStack or RTLVStack**

Run: `grep -r "RTLHStack\|RTLVStack\|RTLComponent" Sources/ --include="*.swift" -l`
Expected: Only `Sources/RTL/RTLComponent.swift` itself.

- [ ] **Step 2: Delete the file**

```bash
rm Sources/RTL/RTLComponent.swift
```

- [ ] **Step 3: Verify compilation**

Run: `swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run all tests**

Run: `swift test`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: remove RTLHStack/RTLVStack, RTL now handled internally by HStack/VStack"
```

---

## Task 12: Update Spacer and clean up Stack protocol

**Files:**
- Modify: `Sources/Layouts/Stack.swift`

- [ ] **Step 1: Update Spacer to accept context**

In `Sources/Layouts/Stack.swift`, update `Spacer`:

```swift
public struct Spacer: Component {
    public init() {}

    public func layout(context: LayoutContext, constraint: Constraint) -> SpacerRenderNode {
        let size = CGSize(
            width: constraint.maxSize.width,
            height: constraint.maxSize.height
        )
        return SpacerRenderNode(size: size)
    }
}
```

- [ ] **Step 2: Clean up Stack protocol extension (remove if unused)**

The `Stack` protocol's default `layout` extension uses `fatalError("Subclass must implement renderNode")` which is dead code since HStack/VStack have their own implementations. Remove the protocol extension's `layout` method and `getRenderNodes`/`renderNode` helpers if they are unused.

Check if anything else conforms to `Stack`. If not, simplify to just the property requirements:

```swift
public protocol Stack: BaseLayoutProtocol {
    var spacing: CGFloat { get }
    var justifyContent: MainAxisAlignment { get }
    var alignItems: CrossAxisAlignment { get }
    var children: [any Component] { get }
}
```

- [ ] **Step 3: Verify compilation and tests**

Run: `swift build && swift test`
Expected: BUILD SUCCEEDED, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add Sources/Layouts/Stack.swift
git commit -m "refactor: update Spacer signature, clean up Stack protocol"
```

---

## Task 13: Integration test — full component tree

**Files:**
- Create: `Tests/IntegrationTests.swift`

- [ ] **Step 1: Write integration tests**

Create `Tests/IntegrationTests.swift`:

```swift
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
        // HStack containing a VStack, all under RTL
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

        // HStack total: 40 + 10 + 30 = 80 (inner VStack cross = max(20,30) = 30)
        XCTAssertEqual(result.size.width, 80)

        // RTL: first child (40px) should be at right side: x = 80 - 40 = 40
        XCTAssertEqual(result.positions[0].x, 40)
        // Second child (30px wide VStack) at x = 0
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testDirectionProviderLocalOverride() {
        // Outer: RTL, inner DirectionProvider forces LTR
        var outerDirection: LayoutDirection?
        var innerDirection: LayoutDirection?

        struct DirectionCapture: Component {
            let id: String
            let capture: (LayoutDirection) -> Void
            func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
                capture(context.resolvedDirection())
                return BasicRenderNode(size: CGSize(width: 10, height: 10))
            }
        }

        let tree = HStack(spacing: 0, children: [
            DirectionCapture(id: "outer") { outerDirection = $0 },
            DirectionProvider(direction: .ltr) {
                DirectionCapture(id: "inner") { innerDirection = $0 }
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

        // RTL: first at x=30, second at x=0
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
}
```

- [ ] **Step 2: Run all tests**

Run: `swift test`
Expected: ALL PASS

- [ ] **Step 3: Commit**

```bash
git add Tests/IntegrationTests.swift
git commit -m "test: add integration tests for RTL unification"
```

---

## Task 14: Final verification

- [ ] **Step 1: Clean build**

Run: `swift package clean && swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 2: Run full test suite**

Run: `swift test`
Expected: All tests pass.

- [ ] **Step 3: Verify no references to deleted types remain**

Run: `grep -r "RTLHStack\|RTLVStack\|RTLHStackRenderNode\|RTLVStackRenderNode" Sources/ Tests/ --include="*.swift"`
Expected: No output (no references).

- [ ] **Step 4: Final commit (if any cleanup needed)**

```bash
git status
# If clean, no commit needed
```
