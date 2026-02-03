import Foundation
import SVGKitCore
import SVGKitDOM

/// Parser extension for basic SVG elements
/// Handles svg, rect, circle, path, g, and other common elements
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct SVGElementParserExtension: ParserExtension {
    public var supportedNamespaces: Set<String> {
        return ["http://www.w3.org/2000/svg"]
    }

    public var supportedElements: Set<String> {
        return [
            // Root and container elements
            "svg", "g", "defs", "symbol", "use",

            // Basic shapes
            "rect", "circle", "ellipse", "line", "polygon", "polyline", "path",

            // Text elements
            "text", "tspan", "textPath",

            // Gradients
            "linearGradient", "radialGradient", "stop",

            // Pattern
            "pattern",

            // Clipping and masking
            "clipPath", "mask",

            // Image and marker
            "image", "marker",

            // Filters
            "filter", "feGaussianBlur", "feOffset", "feBlend", "feColorMatrix",
            "feComposite", "feMerge", "feMergeNode",

            // Style
            "style"
        ]
    }

    public init() {}

    public func handleStartElement(
        localName: String,
        prefix: String?,
        namespace: String,
        attributes: [String: String],
        context: ParserContext
    ) throws -> (any DOMNode)? {
        // Verify document exists in context
        guard findDocument(from: context.parentNode) != nil else {
            throw SVGError.parsingFailed("No document found in context")
        }

        // Create appropriate element
        let element: SVGElement

        switch localName.lowercased() {
        // Root and container elements
        case "svg":
            element = SVGSVGElement()
        case "g":
            element = SVGGElement()
        case "defs":
            element = SVGDefsElement()
        case "symbol":
            element = SVGSymbolElement()
        case "use":
            element = SVGUseElement()

        // Basic shapes
        case "rect":
            element = SVGRectElement()
        case "circle":
            element = SVGCircleElement()
        case "ellipse":
            element = SVGEllipseElement()
        case "line":
            element = SVGLineElement()
        case "polygon":
            element = SVGPolygonElement()
        case "polyline":
            element = SVGPolylineElement()
        case "path":
            element = SVGPathElement()

        // Text elements
        case "text":
            element = SVGTextElement()
        case "tspan":
            element = SVGTSpanElement()
        case "textpath":
            element = SVGTextPathElement()

        // Gradients
        case "lineargradient":
            element = SVGLinearGradientElement()
        case "radialgradient":
            element = SVGRadialGradientElement()
        case "stop":
            element = SVGStopElement()

        // Pattern
        case "pattern":
            element = SVGPatternElement()

        // Clipping and masking
        case "clippath":
            element = SVGClipPathElement()
        case "mask":
            element = SVGMaskElement()

        // Image and marker
        case "image":
            element = SVGImageElement()
        case "marker":
            element = SVGMarkerElement()

        // Filters
        case "filter":
            element = SVGFilterElement()
        case "fegaussianblur":
            element = SVGFEGaussianBlurElement()
        case "feoffset":
            element = SVGFEOffsetElement()
        case "feblend":
            element = SVGFEBlendElement()
        case "fecolormatrix":
            element = SVGFEColorMatrixElement()
        case "fecomposite":
            element = SVGFECompositeElement()
        case "femerge":
            element = SVGFEMergeElement()
        case "femergenode":
            element = SVGFEMergeNodeElement()

        // Style
        case "style":
            element = SVGStyleElement()

        default:
            element = SVGElement(name: localName, namespaceURI: namespace)
        }

        // Set attributes
        for (key, value) in attributes {
            element.setAttribute(key, value: value)
        }

        // Set owner SVG element if we're inside an SVG
        if let svg = findOwnerSVG(from: context.parentNode) {
            element.ownerSVGElement = svg
        } else if let svg = element as? SVGSVGElement {
            // This element IS the SVG root
            svg.ownerSVGElement = svg
        }

        return element
    }

    public func handleEndElement(
        node: any DOMNode,
        context: ParserContext
    ) throws {
        // Most elements don't need post-processing
        // Text elements would handle their text content here
    }

    // MARK: - Helpers

    private func findDocument(from node: (any DOMNode)?) -> SVGDocument? {
        var current = node
        while let node = current {
            if let doc = node as? SVGDocument {
                return doc
            }
            current = node.parentNode
        }
        return nil
    }

    private func findOwnerSVG(from node: (any DOMNode)?) -> SVGSVGElement? {
        var current = node
        while let node = current {
            if let svg = node as? SVGSVGElement {
                return svg
            }
            current = node.parentNode
        }
        return nil
    }
}
