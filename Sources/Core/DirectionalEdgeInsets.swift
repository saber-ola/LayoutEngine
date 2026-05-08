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
