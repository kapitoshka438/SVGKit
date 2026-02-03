import Foundation
import QuartzCore
import SVGKitCore
import SVGKitDOM
import OSLog

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// SVG Renderer actor
/// Renders SVG DOM to CALayer hierarchy
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public actor SVGRenderer {
    private let logger = Logger(subsystem: "com.svgkit", category: "rendering")

    public init() {}

    /// Render SVG document to CALayer
    /// - Parameters:
    ///   - document: SVG document to render
    ///   - size: Target size (nil to use intrinsic size)
    ///   - options: Rendering options
    /// - Returns: Root CALayer with rendered content
    public func render(
        document: SVGDocument,
        size: CGSize? = nil,
        options: RenderOptions = RenderOptions()
    ) async -> CALayer? {
        logger.info("Starting render of SVG document")

        guard let rootElement = document.rootElement else {
            logger.error("No root SVG element found")
            return nil
        }

        // Determine viewport size
        let viewportSize = size ?? intrinsicSize(for: rootElement) ?? CGSize(width: 300, height: 150)

        logger.debug("Viewport size: \(viewportSize.width)x\(viewportSize.height)")

        // Create render context
        var context = RenderContext(viewportSize: viewportSize, options: options)

        // Create root layer
        let rootLayer = CALayer()
        rootLayer.bounds = CGRect(origin: .zero, size: viewportSize)
        rootLayer.backgroundColor = options.backgroundColor

        // Render root element
        if let contentLayer = await renderElement(rootElement, context: &context) {
            rootLayer.addSublayer(contentLayer)
        }

        logger.info("Render complete")
        return rootLayer
    }

    /// Get intrinsic size from SVG element
    private func intrinsicSize(for element: SVGSVGElement) -> CGSize? {
        let context = SVGRenderContext()

        let width = element.width?.pixelsValue(in: context)
        let height = element.height?.pixelsValue(in: context)

        if let w = width, let h = height {
            return CGSize(width: CGFloat(w), height: CGFloat(h))
        }

        // Try to parse viewBox
        if let viewBox = element.viewBox {
            let components = viewBox.split(separator: " ").compactMap { Double($0) }
            if components.count >= 4 {
                return CGSize(width: components[2], height: components[3])
            }
        }

        return nil
    }

    /// Render single element
    private func renderElement(
        _ node: any DOMNode,
        context: inout RenderContext
    ) async -> CALayer? {
        guard let element = node as? SVGElement else {
            return nil
        }

        // Check visibility
        let style = element.effectiveStyle
        if style.display == "none" || style.visibility == "hidden" {
            return nil
        }

        // Apply transform
        let hasTransform = element.transform != nil
        if hasTransform {
            context.pushTransform(element.transformMatrix)
        }

        // Apply opacity
        let opacity = style.opacity ?? 1.0
        let hasOpacity = opacity < 1.0
        if hasOpacity {
            context.pushOpacity(opacity)
        }

        // Render based on element type
        var layer: CALayer?

        switch element {
        case let rect as SVGRectElement:
            layer = await renderRect(rect, context: context)
        case let circle as SVGCircleElement:
            layer = await renderCircle(circle, context: context)
        case let ellipse as SVGEllipseElement:
            layer = await renderEllipse(ellipse, context: context)
        case let line as SVGLineElement:
            layer = await renderLine(line, context: context)
        case let polygon as SVGPolygonElement:
            layer = await renderPolygon(polygon, context: context)
        case let polyline as SVGPolylineElement:
            layer = await renderPolyline(polyline, context: context)
        case let path as SVGPathElement:
            layer = await renderPath(path, context: context)
        case let group as SVGGElement:
            layer = await renderGroup(group, context: &context)
        case let svg as SVGSVGElement:
            layer = await renderSVG(svg, context: &context)
        case let use as SVGUseElement:
            layer = await renderUse(use, context: &context)
        case let text as SVGTextElement:
            layer = await renderText(text, context: context)
        default:
            // Handle other elements (defs, etc.)
            if element.childNodes.count > 0 {
                layer = await renderGroup(element, context: &context)
            }
        }

        // Apply opacity to layer
        if let layer = layer, hasOpacity {
            layer.opacity = Float(context.currentOpacity)
        }

        // Apply transform to layer
        if let layer = layer, hasTransform {
            layer.setAffineTransform(context.currentTransform)
        }

        // Pop stacks
        if hasOpacity {
            context.popOpacity()
        }
        if hasTransform {
            context.popTransform()
        }

        return layer
    }

    // MARK: - Shape Renderers

    private func renderRect(_ rect: SVGRectElement, context: RenderContext) async -> CALayer? {
        let x = context.pixelValue(for: rect.x)
        let y = context.pixelValue(for: rect.y)
        let width = context.pixelValue(for: rect.width)
        let height = context.pixelValue(for: rect.height)
        let rx = context.pixelValue(for: rect.rx)
        let ry = context.pixelValue(for: rect.ry)

        let bounds = CGRect(x: x, y: y, width: width, height: height)

        let cornerRadius = max(rx, ry)
        let path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        return createShapeLayer(path: path, element: rect, context: context)
    }

    private func renderCircle(_ circle: SVGCircleElement, context: RenderContext) async -> CALayer? {
        let cx = context.pixelValue(for: circle.cx)
        let cy = context.pixelValue(for: circle.cy)
        let r = context.pixelValue(for: circle.r)

        let bounds = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
        let path = CGPath(ellipseIn: bounds, transform: nil)

        return createShapeLayer(path: path, element: circle, context: context)
    }

    private func renderEllipse(_ ellipse: SVGEllipseElement, context: RenderContext) async -> CALayer? {
        let cx = context.pixelValue(for: ellipse.cx)
        let cy = context.pixelValue(for: ellipse.cy)
        let rx = context.pixelValue(for: ellipse.rx)
        let ry = context.pixelValue(for: ellipse.ry)

        let bounds = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
        let path = CGPath(ellipseIn: bounds, transform: nil)

        return createShapeLayer(path: path, element: ellipse, context: context)
    }

    private func renderLine(_ line: SVGLineElement, context: RenderContext) async -> CALayer? {
        let x1 = context.pixelValue(for: line.x1)
        let y1 = context.pixelValue(for: line.y1)
        let x2 = context.pixelValue(for: line.x2)
        let y2 = context.pixelValue(for: line.y2)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))

        return createShapeLayer(path: path, element: line, context: context)
    }

    private func renderPolygon(_ polygon: SVGPolygonElement, context: RenderContext) async -> CALayer? {
        guard let points = polygon.points else { return nil }
        guard let path = parsePoints(points, close: true) else { return nil }

        return createShapeLayer(path: path, element: polygon, context: context)
    }

    private func renderPolyline(_ polyline: SVGPolylineElement, context: RenderContext) async -> CALayer? {
        guard let points = polyline.points else { return nil }
        guard let path = parsePoints(points, close: false) else { return nil }

        return createShapeLayer(path: path, element: polyline, context: context)
    }

    private func renderPath(_ pathElement: SVGPathElement, context: RenderContext) async -> CALayer? {
        guard let d = pathElement.d else { return nil }
        guard let path = parsePath(d) else { return nil }

        return createShapeLayer(path: path, element: pathElement, context: context)
    }

    // MARK: - Group Renderers

    private func renderGroup(_ group: any DOMNode, context: inout RenderContext) async -> CALayer? {
        let layer = CALayer()
        layer.bounds = CGRect(origin: .zero, size: context.viewportSize)

        for child in group.childNodes {
            if let childLayer = await renderElement(child, context: &context) {
                layer.addSublayer(childLayer)
            }
        }

        return layer.sublayers?.isEmpty == false ? layer : nil
    }

    private func renderSVG(_ svg: SVGSVGElement, context: inout RenderContext) async -> CALayer? {
        // Similar to group but may have its own viewport
        return await renderGroup(svg, context: &context)
    }

    private func renderUse(_ use: SVGUseElement, context: inout RenderContext) async -> CALayer? {
        // TODO: Implement use element (clone referenced element)
        logger.warning("Use element rendering not yet implemented")
        return nil
    }

    private func renderText(_ text: SVGTextElement, context: RenderContext) async -> CALayer? {
        // TODO: Implement text rendering
        logger.warning("Text rendering not yet implemented")
        return nil
    }

    // MARK: - Helpers

    private func createShapeLayer(
        path: CGPath,
        element: SVGElement,
        context: RenderContext
    ) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.path = path

        let style = element.effectiveStyle

        // Fill
        if let fillStr = style.fill, fillStr != "none" {
            layer.fillColor = parseColor(fillStr, opacity: style.fillOpacity ?? 1.0)
        } else {
            layer.fillColor = nil
        }

        // Stroke
        if let strokeStr = style.stroke, strokeStr != "none" {
            layer.strokeColor = parseColor(strokeStr, opacity: style.strokeOpacity ?? 1.0)
            layer.lineWidth = style.strokeWidth ?? 1.0

            // Line cap
            if let linecap = style.strokeLinecap {
                layer.lineCap = CAShapeLayerLineCap(rawValue: linecap)
            }

            // Line join
            if let linejoin = style.strokeLinejoin {
                layer.lineJoin = CAShapeLayerLineJoin(rawValue: linejoin)
            }

            // Dash array
            if let dasharray = style.strokeDasharray, dasharray != "none" {
                let dashes = dasharray.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                if !dashes.isEmpty {
                    layer.lineDashPattern = dashes.map { NSNumber(value: $0) }
                }
            }
        } else {
            layer.strokeColor = nil
        }

        return layer
    }

    private func parseColor(_ colorStr: String, opacity: CGFloat = 1.0) -> CGColor? {
        let trimmed = colorStr.trimmingCharacters(in: .whitespaces).lowercased()

        // Handle named colors
        if let namedColor = namedColors[trimmed] {
            return namedColor.copy(alpha: opacity)
        }

        // Handle hex colors
        if trimmed.hasPrefix("#") {
            return parseHexColor(trimmed, opacity: opacity)
        }

        // Handle rgb/rgba
        if trimmed.hasPrefix("rgb") {
            return parseRGBColor(trimmed, opacity: opacity)
        }

        return nil
    }

    private func parseHexColor(_ hex: String, opacity: CGFloat) -> CGColor? {
        var hexStr = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))

        if hexStr.count == 3 {
            // Expand shorthand (#RGB -> #RRGGBB)
            hexStr = String(hexStr.flatMap { [$0, $0] })
        }

        guard hexStr.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexStr).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0

        return CGColor(red: r, green: g, blue: b, alpha: opacity)
    }

    private func parseRGBColor(_ rgb: String, opacity: CGFloat) -> CGColor? {
        let pattern = #"rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let nsString = rgb as NSString
        guard let match = regex.firstMatch(in: rgb, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }

        let r = CGFloat(Int(nsString.substring(with: match.range(at: 1))) ?? 0) / 255.0
        let g = CGFloat(Int(nsString.substring(with: match.range(at: 2))) ?? 0) / 255.0
        let b = CGFloat(Int(nsString.substring(with: match.range(at: 3))) ?? 0) / 255.0

        var alpha = opacity
        if match.range(at: 4).location != NSNotFound {
            alpha = CGFloat(Double(nsString.substring(with: match.range(at: 4))) ?? 1.0) * opacity
        }

        return CGColor(red: r, green: g, blue: b, alpha: alpha)
    }

    private func parsePoints(_ pointsStr: String, close: Bool) -> CGPath? {
        let numbers = pointsStr.split(whereSeparator: { $0.isWhitespace || $0 == "," })
            .compactMap { Double($0) }

        guard numbers.count >= 2 && numbers.count % 2 == 0 else { return nil }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: numbers[0], y: numbers[1]))

        for i in stride(from: 2, to: numbers.count, by: 2) {
            path.addLine(to: CGPoint(x: numbers[i], y: numbers[i + 1]))
        }

        if close {
            path.closeSubpath()
        }

        return path
    }

    private func parsePath(_ d: String) -> CGPath? {
        // Simplified path parsing (would need full SVG path parser for production)
        logger.warning("Path parsing is simplified - full implementation needed")

        // For now, return empty path
        // TODO: Implement full SVG path parsing
        return CGMutablePath()
    }

    // Named colors (simplified set)
    private let namedColors: [String: CGColor] = [
        "black": CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        "white": CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        "red": CGColor(red: 1, green: 0, blue: 0, alpha: 1),
        "green": CGColor(red: 0, green: 0.5, blue: 0, alpha: 1),
        "blue": CGColor(red: 0, green: 0, blue: 1, alpha: 1),
        "yellow": CGColor(red: 1, green: 1, blue: 0, alpha: 1),
        "cyan": CGColor(red: 0, green: 1, blue: 1, alpha: 1),
        "magenta": CGColor(red: 1, green: 0, blue: 1, alpha: 1),
        "gray": CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        "grey": CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
        "orange": CGColor(red: 1, green: 0.65, blue: 0, alpha: 1),
        "purple": CGColor(red: 0.5, green: 0, blue: 0.5, alpha: 1),
        "brown": CGColor(red: 0.65, green: 0.16, blue: 0.16, alpha: 1),
        "pink": CGColor(red: 1, green: 0.75, blue: 0.8, alpha: 1),
    ]
}
