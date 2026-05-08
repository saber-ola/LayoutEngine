# RTL 统一设计：HStack/VStack 内部自动处理 RTL

## 目标

移除 `RTLHStack`/`RTLVStack` 独立组件，将 RTL 支持统一到 `HStack`/`VStack` 内部，实现零配置自动化——开发者无需显式传入方向参数，引擎自动处理。

## 核心决策

| 决策项 | 结论 |
|--------|------|
| 架构方案 | LayoutContext 贯穿计算链（方案 A） |
| 方向来源 | 引擎自动检测系统 locale，开发者无需手动设置 |
| RTL 影响范围 | 全面镜像：子组件顺序、定位、对齐语义、padding leading/trailing |
| 覆盖机制 | 唯一入口为 `DirectionProvider` 容器组件 |
| 旧组件处理 | 直接删除 `RTLHStack`/`RTLVStack`，无 deprecated 过渡期 |
| 自动刷新 | 支持系统 locale 变化和 app 内手动切换语言 |

## 设计详情

### 1. 核心类型

#### LayoutContext

```swift
public struct LayoutContext {
    public var direction: LayoutDirection
    
    public static var system: LayoutContext {
        LayoutContext(direction: .current)
    }
}
```

未来可扩展承载 theme、accessibility、scale factor 等环境信息。

#### LayoutDirection 改造

```swift
public enum LayoutDirection {
    case ltr
    case rtl
    case auto  // 从 context 继承，若无 context 则取系统 locale
}
```

#### 组件签名变化

```swift
// Before
func layout(constraint: Constraint) -> some RenderNode

// After
func layout(context: LayoutContext, constraint: Constraint) -> some RenderNode
```

### 2. HStack/VStack 内部 RTL 处理

HStack 在布局计算时自动读取 context.direction：

- 子组件排列顺序：RTL 下自动反转
- 对齐语义翻转：`.start`/`.end` 含义随方向变化
- padding leading/trailing：自动解析为物理 left/right

VStack 本身排列方向不受 RTL 影响，但交叉轴 `.start`/`.end` 随方向翻转，且 context 原样传递给子组件。

#### MainAxisAlignment 镜像

```swift
extension MainAxisAlignment {
    var mirrored: MainAxisAlignment {
        switch self {
        case .start: return .end
        case .end: return .start
        default: return self
        }
    }
}
```

### 3. DirectionProvider

唯一的方向覆盖入口，用于罕见的局部方向强制场景：

```swift
public struct DirectionProvider: Component {
    public var direction: LayoutDirection
    public var children: [any Component]
    
    public func layout(context: LayoutContext, constraint: Constraint) -> some RenderNode {
        var childContext = context
        childContext.direction = direction.resolved(from: context)
        // 使用 childContext 对 children 进行布局
        ...
    }
}
```

日常使用完全不需要此组件——只在 RTL 页面中嵌入 LTR 内容（或反之）时使用。

### 4. DirectionalEdgeInsets

```swift
public struct DirectionalEdgeInsets {
    public var top: CGFloat
    public var bottom: CGFloat
    public var leading: CGFloat
    public var trailing: CGFloat
    
    public func resolved(in direction: LayoutDirection) -> PhysicalEdgeInsets {
        switch direction {
        case .rtl:
            return PhysicalEdgeInsets(top: top, left: trailing, bottom: bottom, right: leading)
        default:
            return PhysicalEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        }
    }
}

public struct PhysicalEdgeInsets {
    public var top: CGFloat
    public var left: CGFloat
    public var bottom: CGFloat
    public var right: CGFloat
}
```

### 5. 自动刷新机制

#### LayoutEngine 接口

```swift
public class LayoutEngine {
    private var rootContext: LayoutContext = .system
    
    public func performLayout(root: any Component, constraint: Constraint) -> some RenderNode {
        root.layout(context: rootContext, constraint: constraint)
    }
    
    /// App 内切换语言时调用
    public func updateLocale(_ locale: Locale) {
        let direction: LayoutDirection = locale.isRTL ? .rtl : .ltr
        updateDirection(direction)
    }
    
    public func updateDirection(_ direction: LayoutDirection) {
        let resolved = direction.resolvedFromLocale()
        guard rootContext.direction != resolved else { return }
        rootContext.direction = resolved
        invalidateAll()
    }
}
```

#### 触发源

| 触发源 | 行为 |
|--------|------|
| 系统 locale 变化 | 引擎自动监听 `NSLocale.currentLocaleDidChangeNotification`，自动更新 |
| App 内手动切换 | 开发者调用 `updateLocale(_:)`，引擎更新并刷新 |
| 优先级 | `updateLocale` 调用后覆盖系统检测，直到下次调用 |

#### Invalidation 策略

- 方向变化只触发一次布局 pass（同一 RunLoop 内合并）
- 方向未实际改变时不触发刷新
- DirectionProvider 子树变化只重算该子树

### 6. 删除清单

移除以下文件：
- `Sources/RTL/RTLHStack.swift`
- `Sources/RTL/RTLVStack.swift`

保留并增强：
- `Sources/RTL/LayoutDirection.swift`（增加 `.auto` case 和解析逻辑）

### 7. 使用示例

```swift
// 日常场景：零配置，完全自动
HStack(spacing: 8) {
    Text("مرحبا")
    Icon(.arrow)
}

// 罕见场景：RTL 页面中嵌入 LTR 代码块
DirectionProvider(direction: .ltr) {
    HStack(spacing: 4) {
        Text("let x = 1")
    }
}

// App 内切换语言
func onLanguageChanged(to locale: Locale) {
    layoutEngine.updateLocale(locale)
}
```

## 测试策略

### 单元测试

1. 方向解析：`.auto` 在不同 locale 下正确解析；`DirectionProvider` 嵌套优先级正确
2. 布局计算：HStack RTL 下子组件顺序反转；`.start`/`.end` 语义翻转；VStack 交叉轴翻转；`DirectionalEdgeInsets` 解析正确
3. 刷新机制：`updateLocale` 后布局结果更新；方向未变不触发多余布局；同一 RunLoop 合并

### 集成测试

4. 嵌套 HStack/VStack 组合在 RTL 下输出正确的 RenderNode positions
5. `DirectionProvider` 局部覆盖不影响外部兄弟节点
