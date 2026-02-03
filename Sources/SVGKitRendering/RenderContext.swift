import Foundation
import CoreGraphics
import SVGKitCore

/// Rendering options
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct RenderOptions: Sendable {
    /// Scale factor for rendering (default: 1.0)
    public var scale: CGFloat

    /// Background color (nil for transparent)
    public var backgroundColor: CGColor?

    /// Enable antialiasing (default: true)
    public var antialiasing: Bool

    /// Render at original size or fit to viewport
    public var fitToViewport: Bool

    /// Initialize with default options
    public init(
        scale: CGFloat = 1.0,
        backgroundColor: CGColor? = nil,
        antialiasing: Bool = true,
        fitToViewport: Bool = false
    ) {
        self.scale = scale
        self.backgroundColor = backgroundColor
        self.antialiasing = antialiasing
        self.fitToViewport = fitToViewport
    }
}

/// Context for SVG rendering
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct RenderContext {
    /// Viewport size
    public let viewportSize: CGSize

    /// Render options
    public let options: RenderOptions

    /// Current transform stack
    public var transformStack: [CGAffineTransform]

    /// Current opacity stack
    public var opacityStack: [CGFloat]

    /// DPI for unit conversion (default: 96)
    public let dpi: CGFloat

    /// Font size for em units (default: 16)
    public let fontSize: CGFloat

    /// Initialize render context
    public init(
        viewportSize: CGSize,
        options: RenderOptions = RenderOptions(),
        dpi: CGFloat = 96.0,
        fontSize: CGFloat = 16.0
    ) {
        self.viewportSize = viewportSize
        self.options = options
        self.dpi = dpi
        self.fontSize = fontSize
        self.transformStack = [.identity]
        self.opacityStack = [1.0]
    }

    /// Current transform
    public var currentTransform: CGAffineTransform {
        return transformStack.last ?? .identity
    }

    /// Current opacity
    public var currentOpacity: CGFloat {
        return opacityStack.last ?? 1.0
    }

    /// Push transform onto stack
    public mutating func pushTransform(_ transform: CGAffineTransform) {
        let combined = currentTransform.concatenating(transform)
        transformStack.append(combined)
    }

    /// Pop transform from stack
    public mutating func popTransform() {
        if transformStack.count > 1 {
            transformStack.removeLast()
        }
    }

    /// Push opacity onto stack
    public mutating func pushOpacity(_ opacity: CGFloat) {
        let combined = currentOpacity * opacity
        opacityStack.append(combined)
    }

    /// Pop opacity from stack
    public mutating func popOpacity() {
        if opacityStack.count > 1 {
            opacityStack.removeLast()
        }
    }

    /// Create SVGRenderContext for length conversions
    public var lengthContext: SVGRenderContext {
        return SVGRenderContext(
            pixelsPerInch: dpi,
            fontSize: fontSize,
            viewportSize: viewportSize
        )
    }

    /// Convert SVGLength to CGFloat in pixels
    public func pixelValue(for length: SVGLength?) -> CGFloat {
        guard let length = length else { return 0 }
        return length.pixelsValue(in: lengthContext)
    }
}
