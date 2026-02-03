import Foundation
import CoreGraphics

/// SVG length unit type
/// W3C Spec: http://www.w3.org/TR/SVG/types.html#InterfaceSVGLength
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public enum SVGLengthUnit: Int, Sendable, Hashable, Codable {
    case unknown = 0
    case number = 1
    case percentage = 2
    case ems = 3
    case exs = 4
    case px = 5
    case cm = 6
    case mm = 7
    case `in` = 8
    case pt = 9
    case pc = 10
}

/// Represents an SVG length value with a unit
/// W3C Spec: http://www.w3.org/TR/SVG/types.html#InterfaceSVGLength
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct SVGLength: Sendable, Hashable, Codable {
    /// The numeric value in specified units
    public var valueInSpecifiedUnits: Float

    /// The unit type
    public var unitType: SVGLengthUnit

    /// Creates a new SVG length
    public init(value: Float, unit: SVGLengthUnit) {
        self.valueInSpecifiedUnits = value
        self.unitType = unit
    }

    /// Zero length
    public static let zero = SVGLength(value: 0, unit: .number)

    /// Creates an SVGLength from a string representation
    /// Examples: "10px", "50%", "2em", "100"
    public init?(string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        // Try to parse unit suffix
        if trimmed.hasSuffix("px") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .px)
        } else if trimmed.hasSuffix("%") {
            guard let value = Float(trimmed.dropLast(1)) else { return nil }
            self.init(value: value, unit: .percentage)
        } else if trimmed.hasSuffix("em") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .ems)
        } else if trimmed.hasSuffix("ex") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .exs)
        } else if trimmed.hasSuffix("cm") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .cm)
        } else if trimmed.hasSuffix("mm") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .mm)
        } else if trimmed.hasSuffix("in") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .in)
        } else if trimmed.hasSuffix("pt") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .pt)
        } else if trimmed.hasSuffix("pc") {
            guard let value = Float(trimmed.dropLast(2)) else { return nil }
            self.init(value: value, unit: .pc)
        } else {
            // No unit suffix - treat as number
            guard let value = Float(trimmed) else { return nil }
            self.init(value: value, unit: .number)
        }
    }

    /// String representation
    public var valueAsString: String {
        switch unitType {
        case .unknown:
            return "\(valueInSpecifiedUnits)"
        case .number:
            return "\(valueInSpecifiedUnits)"
        case .percentage:
            return "\(valueInSpecifiedUnits)%"
        case .ems:
            return "\(valueInSpecifiedUnits)em"
        case .exs:
            return "\(valueInSpecifiedUnits)ex"
        case .px:
            return "\(valueInSpecifiedUnits)px"
        case .cm:
            return "\(valueInSpecifiedUnits)cm"
        case .mm:
            return "\(valueInSpecifiedUnits)mm"
        case .in:
            return "\(valueInSpecifiedUnits)in"
        case .pt:
            return "\(valueInSpecifiedUnits)pt"
        case .pc:
            return "\(valueInSpecifiedUnits)pc"
        }
    }
}

// MARK: - Conversion Methods

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGLength {
    /// Convert to pixels using a rendering context
    /// - Parameter context: The rendering context with viewport and DPI information
    /// - Returns: The value in pixels
    public func pixelsValue(in context: SVGRenderContext) -> CGFloat {
        switch unitType {
        case .unknown, .number, .px:
            return CGFloat(valueInSpecifiedUnits)

        case .percentage:
            // Percentage requires a base dimension from context
            return 0 // Will be implemented with full context support

        case .ems:
            return CGFloat(valueInSpecifiedUnits) * context.fontSize

        case .exs:
            return CGFloat(valueInSpecifiedUnits) * context.fontSize * 0.5 // Approximate

        case .cm:
            return CGFloat(valueInSpecifiedUnits) * context.pixelsPerInch / 2.54

        case .mm:
            return CGFloat(valueInSpecifiedUnits) * context.pixelsPerInch / 25.4

        case .in:
            return CGFloat(valueInSpecifiedUnits) * context.pixelsPerInch

        case .pt:
            return CGFloat(valueInSpecifiedUnits) * context.pixelsPerInch / 72.0

        case .pc:
            return CGFloat(valueInSpecifiedUnits) * context.pixelsPerInch / 6.0
        }
    }

    /// Convert to pixels with a specific dimension for percentage calculation
    /// - Parameters:
    ///   - dimension: The dimension to use for percentage calculation (width, height, or diagonal)
    ///   - context: The rendering context
    /// - Returns: The value in pixels
    public func pixelsValue(withDimension dimension: CGFloat, in context: SVGRenderContext) -> CGFloat {
        if unitType == .percentage {
            return dimension * CGFloat(valueInSpecifiedUnits) / 100.0
        }
        return pixelsValue(in: context)
    }
}

// MARK: - Render Context (placeholder for Phase 1)

/// Context for rendering SVG elements with viewport and DPI information
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct SVGRenderContext: Sendable {
    /// Pixels per inch for the current device
    public var pixelsPerInch: CGFloat

    /// Current font size for em/ex calculations
    public var fontSize: CGFloat

    /// Viewport size
    public var viewportSize: CGSize

    /// Creates a default render context
    public init(
        pixelsPerInch: CGFloat = 96.0, // Standard web DPI
        fontSize: CGFloat = 16.0,
        viewportSize: CGSize = .zero
    ) {
        self.pixelsPerInch = pixelsPerInch
        self.fontSize = fontSize
        self.viewportSize = viewportSize
    }
}
