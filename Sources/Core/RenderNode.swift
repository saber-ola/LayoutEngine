import CoreGraphics

/// Protocol representing a node in the layout tree after layout calculation
public protocol RenderNode {
    /// The calculated size of this render node
    var size: CGSize { get }
    
    /// The child render nodes of this node
    var children: [any RenderNode] { get }
    
    /// The positions of each child relative to this node's origin
    var positions: [CGPoint] { get }
    
    /// Optional: The distance from the baseline to the top (for text alignment)
    var ascender: CGFloat { get }
    
    /// Optional: The distance from the baseline to the bottom (for text alignment)
    var descender: CGFloat { get }
}

// MARK: - Default Implementations

extension RenderNode {
    public var ascender: CGFloat { 0 }
    public var descender: CGFloat { 0 }
}

// MARK: - Helper Structures

/// Represents a child render node with its position and index
public struct RenderNodeChild {
    public let renderNode: any RenderNode
    public let position: CGPoint
    public let index: Int
}

// MARK: - Concrete Implementations

/// A simple render node that returns the provided values
public struct BasicRenderNode: RenderNode {
    public let size: CGSize
    public let children: [any RenderNode]
    public let positions: [CGPoint]
    
    public init(size: CGSize, children: [any RenderNode] = [], positions: [CGPoint] = []) {
        self.size = size
        self.children = children
        self.positions = positions
    }
}

/// A render node that wraps another render node and modifies it
public protocol RenderNodeWrapper: RenderNode {
    associatedtype Content: RenderNode
    var content: Content { get }
}

extension RenderNodeWrapper {
    public var size: CGSize { content.size }
    public var children: [any RenderNode] { [content] }
    public var positions: [CGPoint] { [.zero] }
    public var ascender: CGFloat { content.ascender }
    public var descender: CGFloat { content.descender }
}
