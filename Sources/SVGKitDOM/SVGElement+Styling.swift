import Foundation
import SVGKitCore
import CoreGraphics

/// Extension to SVGElement for style and transform support
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGElement {
    // MARK: - Transform Support

    /// Get parsed transform attribute
    public var transform: [SVGTransform]? {
        guard let transformString = getAttribute("transform") else {
            return nil
        }
        return SVGTransform.parse(transformString)
    }

    /// Get combined transform matrix
    public var transformMatrix: CGAffineTransform {
        guard let transforms = transform else {
            return .identity
        }
        return SVGTransform.combine(transforms)
    }

    // MARK: - Style Support

    /// Get parsed style attribute
    public var parsedStyle: SVGStyle? {
        guard let styleString = getAttribute("style") else {
            return nil
        }
        return SVGStyle.parse(styleString)
    }

    /// Get effective style (combines inline style with presentation attributes)
    public var effectiveStyle: SVGStyle {
        var style = parsedStyle ?? SVGStyle()

        // Add presentation attributes that aren't in the style
        let presentationAttributes = [
            "fill", "stroke", "stroke-width", "fill-opacity", "stroke-opacity",
            "opacity", "stroke-linecap", "stroke-linejoin", "stroke-dasharray",
            "font-family", "font-size", "font-weight", "text-anchor",
            "display", "visibility"
        ]

        for attr in presentationAttributes {
            if style.getProperty(attr) == nil, let value = getAttribute(attr) {
                style.setProperty(attr, value: value)
            }
        }

        return style
    }
}
