import Foundation
import CoreGraphics

#if os(iOS) || os(tvOS)
import UIKit
#else
public struct UIEdgeInsets: Equatable {
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
}
#endif

public struct Constraint {
    public let minSize: CGSize
    public let maxSize: CGSize

    public init(minSize: CGSize = .zero, maxSize: CGSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)) {
        self.minSize = minSize
        self.maxSize = maxSize
    }

    public init(tightSize: CGSize) {
        self.minSize = tightSize
        self.maxSize = tightSize
    }

    public init(maxSize: CGSize) {
        self.minSize = .zero
        self.maxSize = maxSize
    }

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
    public static func inset(h: CGFloat, v: CGFloat) -> UIEdgeInsets {
        UIEdgeInsets(top: v, left: h, bottom: v, right: h)
    }

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
    public func inset(by insets: UIEdgeInsets) -> CGSize {
        CGSize(
            width: self.width + insets.left + insets.right,
            height: self.height + insets.top + insets.bottom
        )
    }

    public func bound(to constraint: Constraint) -> CGSize {
        CGSize(
            width: self.width.clamp(constraint.minSize.width, constraint.maxSize.width),
            height: self.height.clamp(constraint.minSize.height, constraint.maxSize.height)
        )
    }
}

// MARK: - CGFloat Extension

extension CGFloat {
    func clamp(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}

prefix func -(insets: UIEdgeInsets) -> UIEdgeInsets {
    UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right)
}
