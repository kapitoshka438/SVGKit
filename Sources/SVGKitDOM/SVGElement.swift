import Foundation
import SVGKitCore

/// Base class for all SVG elements
/// W3C Spec: https://www.w3.org/TR/SVG11/types.html#InterfaceSVGElement
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
open class SVGElement: Element {
    /// SVG element ID (from id attribute)
    public var identifier: String? {
        get { getAttribute("id") }
        set {
            if let value = newValue {
                setAttribute("id", value: value)
            } else {
                removeAttribute("id")
            }
        }
    }

    /// Class attribute
    public var className: String? {
        get { getAttribute("class") }
        set {
            if let value = newValue {
                setAttribute("class", value: value)
            } else {
                removeAttribute("class")
            }
        }
    }

    /// Style attribute
    public var style: String? {
        get { getAttribute("style") }
        set {
            if let value = newValue {
                setAttribute("style", value: value)
            } else {
                removeAttribute("style")
            }
        }
    }

    /// Reference to the root SVG element
    public weak var ownerSVGElement: SVGSVGElement?

    /// Initialize SVG element
    /// - Parameters:
    ///   - name: Element name
    ///   - namespaceURI: Namespace URI
    public init(name: String, namespaceURI: String = "http://www.w3.org/2000/svg") {
        super.init(name: name, namespaceURI: namespaceURI, prefix: nil)
    }

    // MARK: - Convenience Attribute Getters

    /// Get float attribute value
    /// - Parameter name: Attribute name
    /// - Returns: Float value or nil
    public func getFloatAttribute(_ name: String) -> Float? {
        guard let value = getAttribute(name) else { return nil }
        return Float(value)
    }

    /// Get SVGLength attribute value
    /// - Parameter name: Attribute name
    /// - Returns: SVGLength or nil
    public func getLengthAttribute(_ name: String) -> SVGLength? {
        guard let value = getAttribute(name) else { return nil }
        return SVGLength(string: value)
    }

    /// Get boolean attribute
    /// - Parameter name: Attribute name
    /// - Returns: True if attribute exists and is not "false" or "0"
    public func getBoolAttribute(_ name: String) -> Bool {
        guard let value = getAttribute(name) else { return false }
        let lowercased = value.lowercased()
        return lowercased != "false" && lowercased != "0" && !lowercased.isEmpty
    }
}

/// Root SVG element
/// W3C Spec: https://www.w3.org/TR/SVG11/struct.html#InterfaceSVGSVGElement
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGSVGElement: SVGElement {
    /// Width attribute
    public var width: SVGLength? {
        return getLengthAttribute("width")
    }

    /// Height attribute
    public var height: SVGLength? {
        return getLengthAttribute("height")
    }

    /// ViewBox attribute
    public var viewBox: String? {
        return getAttribute("viewBox")
    }

    /// Initialize SVG root element
    public init() {
        super.init(name: "svg", namespaceURI: "http://www.w3.org/2000/svg")
        self.ownerSVGElement = self
    }
}

// MARK: - Common SVG Elements

/// Rectangle element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGRectElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var width: SVGLength? { getLengthAttribute("width") }
    public var height: SVGLength? { getLengthAttribute("height") }
    public var rx: SVGLength? { getLengthAttribute("rx") }
    public var ry: SVGLength? { getLengthAttribute("ry") }

    public init() {
        super.init(name: "rect")
    }
}

/// Circle element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGCircleElement: SVGElement {
    public var cx: SVGLength? { getLengthAttribute("cx") }
    public var cy: SVGLength? { getLengthAttribute("cy") }
    public var r: SVGLength? { getLengthAttribute("r") }

    public init() {
        super.init(name: "circle")
    }
}

/// Path element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGPathElement: SVGElement {
    public var d: String? {
        return getAttribute("d")
    }

    public init() {
        super.init(name: "path")
    }
}

/// Ellipse element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGEllipseElement: SVGElement {
    public var cx: SVGLength? { getLengthAttribute("cx") }
    public var cy: SVGLength? { getLengthAttribute("cy") }
    public var rx: SVGLength? { getLengthAttribute("rx") }
    public var ry: SVGLength? { getLengthAttribute("ry") }

    public init() {
        super.init(name: "ellipse")
    }
}

/// Line element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGLineElement: SVGElement {
    public var x1: SVGLength? { getLengthAttribute("x1") }
    public var y1: SVGLength? { getLengthAttribute("y1") }
    public var x2: SVGLength? { getLengthAttribute("x2") }
    public var y2: SVGLength? { getLengthAttribute("y2") }

    public init() {
        super.init(name: "line")
    }
}

/// Polygon element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGPolygonElement: SVGElement {
    public var points: String? {
        return getAttribute("points")
    }

    public init() {
        super.init(name: "polygon")
    }
}

/// Polyline element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGPolylineElement: SVGElement {
    public var points: String? {
        return getAttribute("points")
    }

    public init() {
        super.init(name: "polyline")
    }
}

/// Group element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGGElement: SVGElement {
    public init() {
        super.init(name: "g")
    }
}

// MARK: - Text Elements

/// Text element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGTextElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var dx: SVGLength? { getLengthAttribute("dx") }
    public var dy: SVGLength? { getLengthAttribute("dy") }

    public init() {
        super.init(name: "text")
    }
}

/// TSpan element (text span)
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGTSpanElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var dx: SVGLength? { getLengthAttribute("dx") }
    public var dy: SVGLength? { getLengthAttribute("dy") }

    public init() {
        super.init(name: "tspan")
    }
}

/// TextPath element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGTextPathElement: SVGElement {
    public var href: String? {
        return getAttribute("href") ?? getAttribute("xlink:href")
    }

    public init() {
        super.init(name: "textPath")
    }
}

// MARK: - Gradient Elements

/// Linear gradient element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGLinearGradientElement: SVGElement {
    public var x1: SVGLength? { getLengthAttribute("x1") }
    public var y1: SVGLength? { getLengthAttribute("y1") }
    public var x2: SVGLength? { getLengthAttribute("x2") }
    public var y2: SVGLength? { getLengthAttribute("y2") }
    public var gradientUnits: String? { getAttribute("gradientUnits") }
    public var gradientTransform: String? { getAttribute("gradientTransform") }
    public var spreadMethod: String? { getAttribute("spreadMethod") }
    public var href: String? {
        return getAttribute("href") ?? getAttribute("xlink:href")
    }

    public init() {
        super.init(name: "linearGradient")
    }
}

/// Radial gradient element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGRadialGradientElement: SVGElement {
    public var cx: SVGLength? { getLengthAttribute("cx") }
    public var cy: SVGLength? { getLengthAttribute("cy") }
    public var r: SVGLength? { getLengthAttribute("r") }
    public var fx: SVGLength? { getLengthAttribute("fx") }
    public var fy: SVGLength? { getLengthAttribute("fy") }
    public var gradientUnits: String? { getAttribute("gradientUnits") }
    public var gradientTransform: String? { getAttribute("gradientTransform") }
    public var spreadMethod: String? { getAttribute("spreadMethod") }
    public var href: String? {
        return getAttribute("href") ?? getAttribute("xlink:href")
    }

    public init() {
        super.init(name: "radialGradient")
    }
}

/// Gradient stop element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGStopElement: SVGElement {
    public var offset: SVGLength? { getLengthAttribute("offset") }
    public var stopColor: String? { getAttribute("stop-color") }
    public var stopOpacity: Float? { getFloatAttribute("stop-opacity") }

    public init() {
        super.init(name: "stop")
    }
}

// MARK: - Pattern Element

/// Pattern element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGPatternElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var width: SVGLength? { getLengthAttribute("width") }
    public var height: SVGLength? { getLengthAttribute("height") }
    public var patternUnits: String? { getAttribute("patternUnits") }
    public var patternContentUnits: String? { getAttribute("patternContentUnits") }
    public var patternTransform: String? { getAttribute("patternTransform") }
    public var viewBox: String? { getAttribute("viewBox") }
    public var href: String? {
        return getAttribute("href") ?? getAttribute("xlink:href")
    }

    public init() {
        super.init(name: "pattern")
    }
}

// MARK: - Clipping and Masking Elements

/// ClipPath element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGClipPathElement: SVGElement {
    public var clipPathUnits: String? { getAttribute("clipPathUnits") }

    public init() {
        super.init(name: "clipPath")
    }
}

/// Mask element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGMaskElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var width: SVGLength? { getLengthAttribute("width") }
    public var height: SVGLength? { getLengthAttribute("height") }
    public var maskUnits: String? { getAttribute("maskUnits") }
    public var maskContentUnits: String? { getAttribute("maskContentUnits") }

    public init() {
        super.init(name: "mask")
    }
}

// MARK: - Structural Elements

/// Symbol element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGSymbolElement: SVGElement {
    public var viewBox: String? { getAttribute("viewBox") }
    public var preserveAspectRatio: String? { getAttribute("preserveAspectRatio") }

    public init() {
        super.init(name: "symbol")
    }
}

/// Marker element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGMarkerElement: SVGElement {
    public var markerWidth: SVGLength? { getLengthAttribute("markerWidth") }
    public var markerHeight: SVGLength? { getLengthAttribute("markerHeight") }
    public var refX: SVGLength? { getLengthAttribute("refX") }
    public var refY: SVGLength? { getLengthAttribute("refY") }
    public var markerUnits: String? { getAttribute("markerUnits") }
    public var orient: String? { getAttribute("orient") }
    public var viewBox: String? { getAttribute("viewBox") }

    public init() {
        super.init(name: "marker")
    }
}

/// Defs element (definitions)
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGDefsElement: SVGElement {
    public init() {
        super.init(name: "defs")
    }
}

/// Use element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGUseElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var width: SVGLength? { getLengthAttribute("width") }
    public var height: SVGLength? { getLengthAttribute("height") }
    public var href: String? {
        return getAttribute("href") ?? getAttribute("xlink:href")
    }

    public init() {
        super.init(name: "use")
    }
}

/// Image element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGImageElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var width: SVGLength? { getLengthAttribute("width") }
    public var height: SVGLength? { getLengthAttribute("height") }
    public var href: String? {
        return getAttribute("href") ?? getAttribute("xlink:href")
    }
    public var preserveAspectRatio: String? { getAttribute("preserveAspectRatio") }

    public init() {
        super.init(name: "image")
    }
}

// MARK: - Filter Elements

/// Filter element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFilterElement: SVGElement {
    public var x: SVGLength? { getLengthAttribute("x") }
    public var y: SVGLength? { getLengthAttribute("y") }
    public var width: SVGLength? { getLengthAttribute("width") }
    public var height: SVGLength? { getLengthAttribute("height") }
    public var filterUnits: String? { getAttribute("filterUnits") }
    public var primitiveUnits: String? { getAttribute("primitiveUnits") }

    public init() {
        super.init(name: "filter")
    }
}

/// Filter primitive base class
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
open class SVGFilterPrimitiveElement: SVGElement {
    public var result: String? { getAttribute("result") }
    public var `in`: String? { getAttribute("in") }
}

/// Gaussian blur filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFEGaussianBlurElement: SVGFilterPrimitiveElement {
    public var stdDeviation: String? { getAttribute("stdDeviation") }

    public init() {
        super.init(name: "feGaussianBlur")
    }
}

/// Offset filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFEOffsetElement: SVGFilterPrimitiveElement {
    public var dx: SVGLength? { getLengthAttribute("dx") }
    public var dy: SVGLength? { getLengthAttribute("dy") }

    public init() {
        super.init(name: "feOffset")
    }
}

/// Blend filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFEBlendElement: SVGFilterPrimitiveElement {
    public var in2: String? { getAttribute("in2") }
    public var mode: String? { getAttribute("mode") }

    public init() {
        super.init(name: "feBlend")
    }
}

/// Color matrix filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFEColorMatrixElement: SVGFilterPrimitiveElement {
    public var type: String? { getAttribute("type") }
    public var values: String? { getAttribute("values") }

    public init() {
        super.init(name: "feColorMatrix")
    }
}

/// Composite filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFECompositeElement: SVGFilterPrimitiveElement {
    public var in2: String? { getAttribute("in2") }
    public var `operator`: String? { getAttribute("operator") }
    public var k1: Float? { getFloatAttribute("k1") }
    public var k2: Float? { getFloatAttribute("k2") }
    public var k3: Float? { getFloatAttribute("k3") }
    public var k4: Float? { getFloatAttribute("k4") }

    public init() {
        super.init(name: "feComposite")
    }
}

/// Merge filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFEMergeElement: SVGFilterPrimitiveElement {
    public init() {
        super.init(name: "feMerge")
    }
}

/// Merge node filter
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGFEMergeNodeElement: SVGFilterPrimitiveElement {
    public init() {
        super.init(name: "feMergeNode")
    }
}

// MARK: - Style Element

/// Style element
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGStyleElement: SVGElement {
    public var type: String? { getAttribute("type") }
    public var media: String? { getAttribute("media") }

    public init() {
        super.init(name: "style")
    }
}
