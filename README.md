# LayoutEngine

A pure, framework-agnostic layout engine extracted from [@lkzhao/UIComponent](https://github.com/lkzhao/UIComponent). This is a powerful, flexible layout system that can be used with any rendering framework, with built-in RTL support, automatic refresh on system/view changes, and seamless UI framework integration.

## Features

✨ **Framework Agnostic** - Zero external dependencies
- Use with UIKit, SwiftUI, NSView, or custom renderers
- Pure Swift implementation

🌍 **RTL Support** - Full right-to-left layout
- Automatic system language detection
- RTL-aware components (RTLHStack, RTLVStack)
- Position mirroring for RTL layouts
- Seamless LTR/RTL switching

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
let layout = HStack(spacing: 8, alignItems: .center) {
    Text("Hello")
    Image(systemName: "star")
    Text("World")
}

// Calculate layout
let constraint = Constraint(maxSize: CGSize(width: 300, height: 100))
let renderNode = layout.layout(constraint)

print(renderNode.size)  // CGSize
```

### RTL-Aware Layout

```swift
import LayoutEngine

// Automatically handles RTL based on system language
let layout = RTLHStack(spacing: 16) {
    Image("profile")
    VStack(spacing: 4) {
        Text("John Doe")
        Text("Developer")
    }
}

// Positions are automatically mirrored for RTL
let renderNode = layout.layout(constraint)
```

### UIView Integration with Auto-Refresh

```swift
#if os(iOS) || os(tvOS)
import LayoutEngine

class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create layout
        let layout = HStack(spacing: 16) {
            Text("Hello")
            Spacer()
            Text("World")
        }
        
        // Attach to view - automatic layout engine creation
        view.layoutEngine.setComponent(layout)
        
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
        
        let layout = RTLHStack(spacing: 16) {
            // Layout content
        }
        
        view.layoutEngine.setComponent(layout)
        
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
        
        view.layoutEngine.setComponent(layout)
        
        // Monitor size changes
        view.startLayoutMonitoring(
            onSizeChange: { size in
                print("Size: \(size)")
            }
        )
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
    func layout(_ constraint: Constraint) -> R
}
```

Every layout element implements this and returns a `RenderNode` with size/positions.

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
    case ltr  // Left-to-Right
    case rtl  // Right-to-Left
    
    static var current: LayoutDirection  // Auto-detect
    var isRTL: Bool
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

### RTL-Aware Stack Layouts

**RTLHStack** - Horizontal with automatic RTL mirroring
```swift
RTLHStack(spacing: 16, layoutDirection: .current) {
    // Positions automatically mirrored for RTL
    Text("مرحبا")  // Arabic
    Spacer()
    Image("icon")
}
```

**RTLVStack** - Vertical with RTL awareness
```swift
RTLVStack(spacing: 16, layoutDirection: .current) {
    // children
}
```

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
// Fixed insets
component.inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))

// Convenient inset
component.inset(h: 16, v: 12)  // horizontal: 16, vertical: 12

// Equal inset
component.inset(16)
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
// Automatic layout engine attachment
extension UIView {
    var layoutEngine: LayoutEngine { /* ... */ }
    
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
    var layoutEngine: LayoutEngine { /* ... */ }
    
    func startLayoutMonitoring(
        onSizeChange: ((CGSize) -> Void)? = nil
    )
}
#endif
```

### SwiftUI Adapter

```swift
import SwiftUI

struct LayoutEngineView: View {
    let component: any Component
    @State var layoutDirection: LayoutDirection = .current
    
    var body: some View {
        // Renders layout engine component
    }
}
```

## Complete Example: Multi-Language App

```swift
#if os(iOS)
import UIKit
import LayoutEngine

class MainViewController: UIViewController {
    let contentLabel = UILabel()
    let actionButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create RTL-aware layout
        let layout = RTLVStack(spacing: 16) {
            RTLHStack(spacing: 12) {
                Image(systemName: "person.circle")
                VStack(spacing: 4) {
                    Text("User Name")
                    Text("@username")
                }
                Spacer()
            }
            
            RTLHStack(spacing: 8) {
                Text("Some description text")
            }.inset(h: 16, v: 8)
            
            RTLHStack(spacing: 8) {
                Spacer()
                Button("Action")
            }.inset(h: 16)
        }.inset(16)
        
        // Attach and monitor
        view.layoutEngine.setComponent(layout)
        
        view.startLayoutMonitoring(
            onSizeChange: { size in
                print("Layout updated for size: \(size)")
            },
            onRTLChange: { direction in
                print("RTL mode: \(direction.isRTL)")
            }
        )
        
        // Global monitoring
        LayoutChangeMonitor.shared.onLayoutDirectionChange { direction in
            self.view.setNeedsLayout()
        }
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
    
    func layout(_ constraint: Constraint) -> some RenderNode {
        let layoutResult = // ... your logic
        return CustomRenderNode(
            size: layoutResult.size,
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
