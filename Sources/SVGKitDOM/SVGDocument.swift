import Foundation

/// SVG Document node
/// W3C Spec: https://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html#i-Document
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGDocument: Node {
    /// Root SVG element
    public var rootElement: SVGSVGElement? {
        return childNodes.first { $0 is SVGSVGElement } as? SVGSVGElement
    }

    /// Document element (alias for rootElement)
    public var documentElement: Element? {
        return childNodes.first { $0 is Element } as? Element
    }

    /// Elements indexed by ID
    private var elementsByID: [String: Element] = [:]

    /// Initialize empty document
    public init() {
        super.init(type: .document, name: "#document")
    }

    /// Create an element
    /// - Parameter tagName: Element tag name
    /// - Returns: New element
    public func createElement(_ tagName: String) -> Element {
        return Element(name: tagName)
    }

    /// Create an SVG element with namespace
    /// - Parameter localName: Element local name
    /// - Returns: New SVG element
    public func createSVGElement(_ localName: String) -> SVGElement {
        switch localName.lowercased() {
        // Root and container elements
        case "svg":
            return SVGSVGElement()
        case "g":
            return SVGGElement()
        case "defs":
            return SVGDefsElement()
        case "symbol":
            return SVGSymbolElement()
        case "use":
            return SVGUseElement()

        // Basic shapes
        case "rect":
            return SVGRectElement()
        case "circle":
            return SVGCircleElement()
        case "ellipse":
            return SVGEllipseElement()
        case "line":
            return SVGLineElement()
        case "polygon":
            return SVGPolygonElement()
        case "polyline":
            return SVGPolylineElement()
        case "path":
            return SVGPathElement()

        // Text elements
        case "text":
            return SVGTextElement()
        case "tspan":
            return SVGTSpanElement()
        case "textpath":
            return SVGTextPathElement()

        // Gradients
        case "lineargradient":
            return SVGLinearGradientElement()
        case "radialgradient":
            return SVGRadialGradientElement()
        case "stop":
            return SVGStopElement()

        // Pattern
        case "pattern":
            return SVGPatternElement()

        // Clipping and masking
        case "clippath":
            return SVGClipPathElement()
        case "mask":
            return SVGMaskElement()

        // Image and marker
        case "image":
            return SVGImageElement()
        case "marker":
            return SVGMarkerElement()

        // Filters
        case "filter":
            return SVGFilterElement()
        case "fegaussianblur":
            return SVGFEGaussianBlurElement()
        case "feoffset":
            return SVGFEOffsetElement()
        case "feblend":
            return SVGFEBlendElement()
        case "fecolormatrix":
            return SVGFEColorMatrixElement()
        case "fecomposite":
            return SVGFECompositeElement()
        case "femerge":
            return SVGFEMergeElement()
        case "femergenode":
            return SVGFEMergeNodeElement()

        // Style
        case "style":
            return SVGStyleElement()

        default:
            return SVGElement(name: localName)
        }
    }

    /// Create a text node
    /// - Parameter data: Text content
    /// - Returns: New text node
    public func createTextNode(_ data: String) -> Node {
        let node = Node(type: .text, name: "#text")
        node.nodeValue = data
        return node
    }

    /// Get element by ID
    /// - Parameter id: Element ID
    /// - Returns: Element with matching ID or nil
    public func getElementById(_ id: String) -> Element? {
        // Try cache first
        if let cached = elementsByID[id] {
            return cached
        }

        // Search tree
        if let root = documentElement,
           let found = root.getElementById(id) {
            elementsByID[id] = found
            return found
        }

        return nil
    }

    /// Register an element's ID for fast lookup
    /// - Parameters:
    ///   - element: Element to register
    ///   - id: Element ID
    public func registerElementID(_ element: Element, id: String) {
        elementsByID[id] = element
    }

    /// Get elements by tag name
    /// - Parameter tagName: Tag name to search for
    /// - Returns: Array of matching elements
    public func getElementsByTagName(_ tagName: String) -> [Element] {
        guard let root = documentElement else { return [] }
        return root.getElementsByTagName(tagName)
    }
}
