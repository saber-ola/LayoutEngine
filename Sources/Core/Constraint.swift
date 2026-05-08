import Foundation
import CoreGraphics

/// Represents the size constraints for a component layout.
/// Defines the minimum and maximum sizes available for a component.
public struct Constraint {
    /// The minimum size the component can be
    public let minSize: CGSize
    
    /// The maximum size the component can be
    public let maxSize: CGSize
    
    /// Creates a constraint with explicit minimum and maximum sizes
    public init(minSize: CGSize = .zero, maxSize: CGSize = CGSize(width: .infinity, height: .infinity)) {
        self.minSize = minSize
        self.maxSize = maxSize
    }
    
    /// Creates a constraint with a tight (fixed) size
    public init(tightSize: CGSize) {
        self.minSize = tightSize
        self.maxSize = tightSize
    }
    
    /// Creates a constraint with maximum size only
    public init(maxSize: CGSize) {
        self.minSize = .zero
        self.maxSize = maxSize
    }
    
    /// Applies insets to this constraint
    public func inset(by insets: UIEdgeInsets) -> Constraint {
        let horizontalInset = insets.left + insets.right
        let verticalInset = insets.top + insets.bottom
        
        return Constraint(
            minSize: CGSize(
                width: max(0, minSize.width - horizontalInset),
                height: max(0, minSize.height - verticalInset)
            ),
            maxSize: CGSize(
                width: max(0, maxSize.width - horizontalInset),
                height: max(0, maxSize.height - verticalInset)
            )
        )
    }
}

// MARK: - UIEdgeInsets Extension

extension UIEdgeInsets {
    /// Creates edge insets with horizontal and vertical values
    public static func inset(h: CGFloat, v: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: v, left: h, bottom: v, right: h)
    }
    
    /// Inverts the insets for size expansion
    public func inverted() -> UIEdgeInsets {
        UIEdgeInsets(
            top: -top,
            left: -left,
            bottom: -bottom,
            right: -right
        )
    }
}

// MARK: - CGSize Extension

extension CGSize {
    /// Insets the size by the given edge insets
    public func inset(by insets: UIEdgeInsets) -> CGSize {
        CGSize(
            width: self.width + insets.left + insets.right,
            height: self.height + insets.top + insets.bottom
        )
    }
    
    /// Bounds the size within the given constraint
    public func bound(to constraint: Constraint) -> CGSize {
        CGSize(
            width: self.width.clamp(constraint.minSize.width, constraint.maxSize.width),
            height: self.height.clamp(constraint.minSize.height, constraint.maxSize.height)
        )
    }
}

// MARK: - CGFloat Extension

extension CGFloat {
    /// Clamps a value between min and max
    func clamp(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}
