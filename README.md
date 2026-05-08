# LayoutEngine

A pure, framework-agnostic layout engine extracted from [@lkzhao/UIComponent](https://github.com/lkzhao/UIComponent). This is a powerful, flexible layout system that can be used with any rendering framework, with built-in RTL support, automatic refresh on system/view changes, and seamless UI framework integration.

## Features

✨ **Framework Agnostic** - Zero external dependencies
- Use with UIKit, SwiftUI, NSView, or custom renderers
- Pure Swift implementation

🌍 **RTL Support** - Full right-to-left layout
- Zero-configuration: HStack/VStack automatically handle RTL
- Automatic system locale detection
- Full mirroring: child order, alignment semantics, leading/trailing insets
- `DirectionProvider` for local direction override
- App-level language switching with automatic layout refresh

📡 **Automatic Refresh**
- System RTL/language changes trigger layout updates
- View size changes auto-refresh
- TraitCollection changes monitored (iOS/tvOS)
- UIViewController appearance tracking

🎨 **Multi-Platform UI Adapters**
- UIView & UIViewController (iOS, tvOS)
- UILayoutGuide integration
- NSView & NSViewController (macOS)
- SwiftUI via LayoutEngineView
- Automatic layout engine attachment

💪 **Powerful Layout System**
- Stack layouts (HStack, VStack)
- Flexbox layouts (FlexRow, FlexColumn) with wrapping
- Overlay/Background compositing
- Constraint-based sizing
- Flexible/Fixed sizing with flex grow/shrink

⚡ **High Performance**
- Minimal allocations during layout
- Binary search for visible item detection
- Lazy evaluation support
- Efficient change detection

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
.package(url: "https://github.com/saber-ola/LayoutEngine.git", from: "1.0.0")
```

Or in Xcode: File → Add Packages → Enter the repository URL

## Quick Start

### Basic Layout

```swift
import LayoutEngine

// Create a simple horizontal stack
let engine = LayoutEngine()
let layout = HStack(spacing: 8, alignItems: .center) {
    Text("Hello")
    Image(systemName: "star")
    Text("World")
}

// Calculate layout — RTL is handled automatically based on system locale
let constraint = Constraint(maxSize: CGSize(width: 300, height: 100))
let renderNode = engine.performLayout(root: layout, constraint: constraint)

print(renderNode.size)  // CGSize
```

### RTL-Aware Layout (Zero Configuration)

```swift
import LayoutEngine

// HStack/VStack automatically handle RTL — no special components needed
let layout = HStack(spacing: 16) {
    Image("profile")
    VStack(spacing: 4) {
        Text("John Doe")
        Text("Developer")
    }
}

// On Arabic/Hebrew/Persian systems, positions are automatically mirrored
let engine = LayoutEngine()
let renderNode = engine.performLayout(root: layout, constraint: constraint)
```

### App-Level Language Switching

```swift
let engine = LayoutEngine()

// Switch to Arabic — all layouts automatically refresh
engine.updateLocale(Locale(identifier: "ar"))

// Or set direction directly
engine.updateDirection(.rtl)

// Get notified when layout needs recalculation
engine.onNeedsLayout = {
    self.view.setNeedsLayout()
}
```

### Local Direction Override

```swift
// Force a specific subtree to LTR (e.g., code block in RTL page)
DirectionProvider(direction: .ltr) {
    HStack(spacing: 4) {
        Text("let x = 1")
    }
}
```

### UIView Integration with Auto-Refresh

```swift
#if os(iOS) || os(tvOS)
import LayoutEngine

class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create layout — RTL handled automatically
        let layout = HStack(spacing: 16) {
            Text("Hello")
            Spacer()
            Text("World")
        }
        
        // Attach to view
        view.uiViewLayoutEngine.setComponent(layout)
        
        // Monitor changes (RTL, size)
        view.startLayoutMonitoring(
            onSizeChange: { size in
                print("Size changed: \(size)")
            },
            onRTLChange: { direction in
                print("RTL changed: \(direction.isRTL)")
            }
        )
    }
    
    deinit {
        view.stopLayoutMonitoring()
    }
}
#endif
```

### UIViewController with TraitCollection Monitoring

```swift
#if os(iOS) || os(tvOS)
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = HStack(spacing: 16) {
            // Layout content — automatically RTL-aware
        }
        
        view.uiViewLayoutEngine.setComponent(layout)
        
        // Automatically monitor traitCollectionDidChange
        enableLayoutEngineRTLMonitoring { direction in
            print("RTL updated: \(direction.isRTL)")
        }
    }
}
#endif
```

### SwiftUI Integration

```swift
import SwiftUI
import LayoutEngine

struct ContentView: View {
    let layout = HStack(spacing: 8) {
        Text("Hello")
        Spacer()
        Text("World")
    }
    
    var body: some View {
        LayoutEngineView(component: layout)
            .layoutDirection(.current)  // Auto-respond to system RTL
    }
}
```

### NSView Integration (macOS)

```swift
#if os(macOS)
import LayoutEngine

class MyViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = VStack(spacing: 16) {
            Text("macOS Layout")
            HStack {
                // Content
            }
        }
        
        view.nsViewLayoutEngine.setComponent(layout)
        
        // Monitor size changes
        view.startBoundsMonitoring { size in
            print("Size: \(size)")
        }
    }
}
#endif
```

### Global RTL Monitoring

```swift
import LayoutEngine

// Monitor system RTL changes globally
LayoutChangeMonitor.shared.onLayoutDirectionChange { direction in
    print("System RTL mode: \(direction.isRTL)")
    // Trigger app-wide layout updates
}

// Check current direction
let current = LayoutDirection.current
print(current.isRTL)  // Detects Arabic, Hebrew, Persian, Urdu, etc.
```

## Core Concepts

### Component Protocol

The foundation of the layout system:

```swift
public protocol Component {
    associatedtype R: RenderNode
    func layout(context: LayoutContext, constraint: Constraint) -> R
}
```

Every layout element implements this. The `LayoutContext` carries environment information (direction, etc.) down the component tree.

### LayoutContext

Carries layout environment down the tree:

```swift
public struct LayoutContext {
    public var direction: LayoutDirection
    
    public static var system: LayoutContext  // Auto-detect from system locale
}
```

### LayoutEngine

Manages root context, direction updates, and invalidation:

```swift
let engine = LayoutEngine()

// Perform layout with automatic direction detection
let result = engine.performLayout(root: myComponent, constraint: constraint)

// Switch language at runtime
engine.updateLocale(Locale(identifier: "ar"))

// Get notified when layout needs refresh
engine.onNeedsLayout = { /* re-layout */ }
```

### Constraint

Defines available space for layout:

```swift
let constraint = Constraint(
    minSize: CGSize(width: 100, height: 50),
    maxSize: CGSize(width: 300, height: 500)
)
```

### RenderNode

Contains layout results:

```swift
public protocol RenderNode {
    var size: CGSize { get }
    var children: [any RenderNode] { get }
    var positions: [CGPoint] { get }
}
```

### LayoutDirection

Represents layout direction with RTL detection:

```swift
enum LayoutDirection {
    case ltr   // Left-to-Right
    case rtl   // Right-to-Left
    case auto  // Inherit from context (default for all components)
    
    static var current: LayoutDirection  // Auto-detect from system
    var isRTL: Bool
}
```

### DirectionProvider

Override direction for a subtree (rare — most code needs zero configuration):

```swift
DirectionProvider(direction: .ltr) {
    // Children here always layout as LTR regardless of system locale
    HStack { ... }
}
```

## Layout Components

### Stack Layouts

**HStack** - Horizontal stacking
```swift
HStack(spacing: 8, alignItems: .center, justifyContent: .spaceBetween) {
    // children
}
```

**VStack** - Vertical stacking
```swift
VStack(spacing: 16, alignItems: .start) {
    // children
}
```

### RTL Behavior

HStack and VStack handle RTL automatically — no special components needed:

```swift
// This single HStack works correctly in both LTR and RTL
HStack(spacing: 16) {
    Text("مرحبا")  // In RTL: positions mirrored, .start means right side
    Spacer()
    Image("icon")
}
```

**HStack in RTL:**
- Child positions are mirrored (first child at right, last at left)
- `.start`/`.end` alignment semantics flip automatically

**VStack in RTL:**
- Cross-axis (horizontal) alignment flips: `.start` = right, `.end` = left
- Main axis (vertical) is unaffected

### Alignment Options

```swift
enum MainAxisAlignment {
    case start, end, center
    case spaceBetween, spaceAround, spaceEvenly
}

enum CrossAxisAlignment {
    case start, end, center, stretch
    case baselineFirst, baselineLast
}
```

### Spacing & Insets

```swift
// Physical insets (not affected by RTL)
component.inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
component.inset(h: 16, v: 12)
component.inset(16)

// Directional insets (leading/trailing flip in RTL automatically)
component.directionalInset(DirectionalEdgeInsets(
    top: 16, bottom: 16, leading: 24, trailing: 8
))
// In LTR: leading=left(24), trailing=right(8)
// In RTL: leading=right(24), trailing=left(8)
```

## Auto-Refresh System

### System Level

```
System Language Changed
    ↓
LayoutChangeMonitor detects
    ↓
onLayoutDirectionChange callback
    ↓
All monitored views refresh
```

### View Level

```
View Size Changed
    ↓
ViewChangeListener detects
    ↓
onSizeChange callback
    ↓
Layout recalculates
```

### TraitCollection Level (iOS/tvOS)

```
UIViewController traitCollectionDidChange
    ↓
TraitCollectionObserver detects
    ↓
RTL/size callbacks
    ↓
Automatic refresh
```

## Multi-Platform Adapters

### UIView Adapter

```swift
#if os(iOS) || os(tvOS)
extension UIView {
    var uiViewLayoutEngine: UIViewLayoutEngine { /* ... */ }
    
    func startLayoutMonitoring(
        onSizeChange: ((CGSize) -> Void)? = nil,
        onRTLChange: ((LayoutDirection) -> Void)? = nil
    )
    
    func stopLayoutMonitoring()
}
#endif
```

### UIViewController Adapter

```swift
#if os(iOS) || os(tvOS)
extension UIViewController {
    func enableLayoutEngineRTLMonitoring(
        _ handler: @escaping (LayoutDirection) -> Void
    )
}
#endif
```

### NSView Adapter (macOS)

```swift
#if os(macOS)
extension NSView {
    var nsViewLayoutEngine: NSViewLayoutEngine { /* ... */ }
    
    func startBoundsMonitoring(
        onBoundsChange: @escaping (CGSize) -> Void
    )
}
#endif
```

### SwiftUI Adapter

```swift
import SwiftUI

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
struct LayoutEngineView: View {
    let component: any Component
    let engine: LayoutEngine
    
    var body: some View {
        // Renders layout engine component with automatic RTL
    }
}
```

## Complete Example: Multi-Language App

```swift
#if os(iOS)
import UIKit
import LayoutEngine

class MainViewController: UIViewController {
    let engine = LayoutEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // No RTL-specific components needed — just use HStack/VStack
        let layout = VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle")
                VStack(spacing: 4) {
                    Text("User Name")
                    Text("@username")
                }
                Spacer()
            }
            
            HStack(spacing: 8) {
                Text("Some description text")
            }.directionalInset(DirectionalEdgeInsets(
                top: 8, bottom: 8, leading: 16, trailing: 16
            ))
            
            HStack(spacing: 8) {
                Spacer()
                Button("Action")
            }.directionalInset(DirectionalEdgeInsets(
                leading: 16, trailing: 16
            ))
        }.inset(16)
        
        // Attach and monitor
        view.uiViewLayoutEngine.setComponent(layout)
        
        // Auto-refresh on locale/direction change
        engine.onNeedsLayout = { [weak self] in
            self?.view.setNeedsLayout()
        }
        
        view.startLayoutMonitoring(
            onSizeChange: { size in
                print("Layout updated for size: \(size)")
            },
            onRTLChange: { direction in
                print("RTL mode: \(direction.isRTL)")
            }
        )
    }
    
    // App-level language switch (e.g., from settings page)
    func onLanguageChanged(to locale: Locale) {
        engine.updateLocale(locale)
        // That's it — engine triggers onNeedsLayout, all HStack/VStack auto-mirror
    }
}
#endif
```

## Performance Tips

1. **Use Spacer for flexible spacing**
   ```swift
   HStack {
       content
       Spacer()  // Fills remaining space
       moreContent
   }
   ```

2. **Stop monitoring when done**
   ```swift
   view.stopLayoutMonitoring()  // In deinit or viewWillDisappear
   ```

3. **Constrain sizes appropriately**
   - Avoid infinite constraints
   - Let parent define boundaries

## Architecture

### Separation of Concerns

- **Layout Calculation**: Pure, deterministic math
- **Monitoring**: Efficient change detection
- **Adapters**: Framework-specific integration
- **Rendering**: Delegated to frameworks

### Extension Points

Create custom layouts:

```swift
struct CustomLayout: Component {
    let children: [any Component]
    
    func layout(context: LayoutContext, constraint: Constraint) -> BasicRenderNode {
        // Access direction from context
        let direction = context.resolvedDirection()
        
        // Your layout logic here...
        return BasicRenderNode(
            size: calculatedSize,
            children: childNodes,
            positions: positions
        )
    }
}
```

## Testing

```bash
swift test
```

## Comparison

| Feature | LayoutEngine | UIComponent |
|---------|--------------|-------------|
| Layout Calculation | ✅ | ✅ |
| RTL Support | ✅ Full | ❌ |
| Auto Refresh | ✅ | ❌ |
| UIKit Integration | ✅ | ✅ |
| SwiftUI Support | ✅ | ✅ |
| macOS Support | ✅ | ❌ |
| Framework Agnostic | ✅ | ❌ |
| Lightweight | ✅ | ❌ |
| File Count | ~500 LOC | ~15000 LOC |

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Submit a pull request

## License

MIT License - see LICENSE file

## Credits

Based on the layout system from [@lkzhao/UIComponent](https://github.com/lkzhao/UIComponent). This is a refined extraction focusing on pure layout calculation with RTL support and multi-platform integration.

## Related Projects

- [UIComponent](https://github.com/lkzhao/UIComponent) - Full UI framework
- [Yoga](https://github.com/facebook/yoga) - Flexbox in C
- [Cassowary](https://constraints.cs.washington.edu/cassowary/) - Constraint solver
