import CoreGraphics

// MARK: - RTL HStack

/// A horizontal stack component with automatic RTL support
public struct RTLHStack: Component, HorizontalLayoutProtocol {
    public let spacing: CGFloat
    public let justifyContent: MainAxisAlignment
    public let alignItems: CrossAxisAlignment
    public let children: [any Component]
    public let layoutDirection: LayoutDirection
    
    public init(
        spacing: CGFloat = 0,
        justifyContent: MainAxisAlignment = .start,
        alignItems: CrossAxisAlignment = .start,
        layoutDirection: LayoutDirection = .current,
        @ComponentBuilder _ content: () -> [any Component] = { [] }
    ) {
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.layoutDirection = layoutDirection
        self.children = layoutDirection.isRTL ? content().reversed() : content()
    }
    
    public func layout(_ constraint: Constraint) -> RTLHStackRenderNode {
        var renderNodes: [any RenderNode] = []
        
        let childConstraint = Constraint(
            minSize: CGSize(width: -.infinity, height: alignItems == .stretch ? constraint.maxSize.height : 0),
            maxSize: CGSize(width: .infinity, height: constraint.maxSize.height)
        )
        
        for child in children {
            renderNodes.append(child.layout(childConstraint))
        }
        
        let crossMax = renderNodes.reduce(0) { max($0, $1.size.height) }
        let mainTotal = renderNodes.reduce(0) { $0 + $1.size.width }
        let maxPrimary = constraint.maxSize.width
        let minPrimary = constraint.minSize.width
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
            
            // Mirror position for RTL
            let x: CGFloat
            if layoutDirection.isRTL {
                x = primaryBound - (primaryOffset + node.size.width)
            } else {
                x = primaryOffset
            }
            
            positions.append(CGPoint(x: x, y: crossValue))
            primaryOffset += node.size.width + distributedSpacing
        }
        
        let intrinsicMain = primaryOffset - distributedSpacing
        let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
        let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)
        
        return RTLHStackRenderNode(
            size: CGSize(width: finalMain, height: crossMax),
            children: renderNodes,
            positions: positions,
            layoutDirection: layoutDirection
        )
    }
}

public struct RTLHStackRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
    public let layoutDirection: LayoutDirection
}

// MARK: - RTL VStack

/// A vertical stack component with RTL awareness
public struct RTLVStack: Component, VerticalLayoutProtocol {
    public let spacing: CGFloat
    public let justifyContent: MainAxisAlignment
    public let alignItems: CrossAxisAlignment
    public let children: [any Component]
    public let layoutDirection: LayoutDirection
    
    public init(
        spacing: CGFloat = 0,
        justifyContent: MainAxisAlignment = .start,
        alignItems: CrossAxisAlignment = .start,
        layoutDirection: LayoutDirection = .current,
        @ComponentBuilder _ content: () -> [any Component] = { [] }
    ) {
        self.spacing = spacing
        self.justifyContent = justifyContent
        self.alignItems = alignItems
        self.layoutDirection = layoutDirection
        self.children = content()
    }
    
    public func layout(_ constraint: Constraint) -> RTLVStackRenderNode {
        var renderNodes: [any RenderNode] = []
        
        let childConstraint = Constraint(
            minSize: CGSize(width: alignItems == .stretch ? constraint.maxSize.width : 0, height: -.infinity),
            maxSize: CGSize(width: constraint.maxSize.width, height: .infinity)
        )
        
        for child in children {
            renderNodes.append(child.layout(childConstraint))
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
            var crossValue: CGFloat = 0
            switch alignItems {
            case .start, .baselineFirst:
                crossValue = 0
            case .end, .baselineLast:
                crossValue = crossMax - node.size.width
            case .center:
                crossValue = (crossMax - node.size.width) / 2
            case .stretch:
                crossValue = 0
            }
            
            // Mirror for RTL
            let x: CGFloat
            if layoutDirection.isRTL {
                x = crossMax - (crossValue + node.size.width)
            } else {
                x = crossValue
            }
            
            positions.append(CGPoint(x: x, y: primaryOffset))
            primaryOffset += node.size.height + distributedSpacing
        }
        
        let intrinsicMain = primaryOffset - distributedSpacing
        let shouldFillPrimary = justifyContent != .start && primaryBound != .infinity
        let finalMain = max(shouldFillPrimary ? primaryBound : minPrimary, intrinsicMain)
        
        return RTLVStackRenderNode(
            size: CGSize(width: crossMax, height: finalMain),
            children: renderNodes,
            positions: positions,
            layoutDirection: layoutDirection
        )
    }
}

public struct RTLVStackRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
    public let layoutDirection: LayoutDirection
}
