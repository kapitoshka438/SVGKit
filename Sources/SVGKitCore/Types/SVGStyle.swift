import Foundation
import CoreGraphics

/// SVG Style properties
/// Represents CSS styling for SVG elements
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct SVGStyle: Sendable, Hashable {
    /// Style properties dictionary
    public var properties: [String: String]

    /// Initialize empty style
    public init() {
        self.properties = [:]
    }

    /// Initialize with properties
    public init(properties: [String: String]) {
        self.properties = properties
    }

    /// Parse style string
    /// - Parameter string: CSS style string (e.g., "fill:red; stroke:blue")
    /// - Returns: SVGStyle or nil if parsing failed
    public static func parse(_ string: String) -> SVGStyle? {
        var properties: [String: String] = [:]

        // Split by semicolon
        let declarations = string.split(separator: ";")

        for declaration in declarations {
            // Split by colon
            let parts = declaration.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }

            let property = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)

            guard !property.isEmpty && !value.isEmpty else { continue }

            properties[property] = value
        }

        return properties.isEmpty ? nil : SVGStyle(properties: properties)
    }

    /// Get property value
    /// - Parameter name: Property name
    /// - Returns: Property value or nil
    public func getProperty(_ name: String) -> String? {
        return properties[name]
    }

    /// Set property value
    /// - Parameters:
    ///   - name: Property name
    ///   - value: Property value
    public mutating func setProperty(_ name: String, value: String) {
        properties[name] = value
    }

    /// Remove property
    /// - Parameter name: Property name
    public mutating func removeProperty(_ name: String) {
        properties.removeValue(forKey: name)
    }

    /// Merge with another style (other properties take precedence)
    /// - Parameter other: Style to merge
    /// - Returns: Merged style
    public func merging(with other: SVGStyle) -> SVGStyle {
        var merged = self
        for (key, value) in other.properties {
            merged.properties[key] = value
        }
        return merged
    }

    // MARK: - Common Properties

    /// Fill color
    public var fill: String? {
        get { getProperty("fill") }
        set { if let value = newValue { properties["fill"] = value } else { properties.removeValue(forKey: "fill") } }
    }

    /// Stroke color
    public var stroke: String? {
        get { getProperty("stroke") }
        set { if let value = newValue { properties["stroke"] = value } else { properties.removeValue(forKey: "stroke") } }
    }

    /// Stroke width
    public var strokeWidth: CGFloat? {
        get {
            guard let value = getProperty("stroke-width") else { return nil }
            return CGFloat(Double(value) ?? 0)
        }
        set {
            if let value = newValue {
                properties["stroke-width"] = String(Double(value))
            } else {
                properties.removeValue(forKey: "stroke-width")
            }
        }
    }

    /// Fill opacity (0.0 to 1.0)
    public var fillOpacity: CGFloat? {
        get {
            guard let value = getProperty("fill-opacity") else { return nil }
            return CGFloat(Double(value) ?? 1.0)
        }
        set {
            if let value = newValue {
                properties["fill-opacity"] = String(Double(value))
            } else {
                properties.removeValue(forKey: "fill-opacity")
            }
        }
    }

    /// Stroke opacity (0.0 to 1.0)
    public var strokeOpacity: CGFloat? {
        get {
            guard let value = getProperty("stroke-opacity") else { return nil }
            return CGFloat(Double(value) ?? 1.0)
        }
        set {
            if let value = newValue {
                properties["stroke-opacity"] = String(Double(value))
            } else {
                properties.removeValue(forKey: "stroke-opacity")
            }
        }
    }

    /// Overall opacity (0.0 to 1.0)
    public var opacity: CGFloat? {
        get {
            guard let value = getProperty("opacity") else { return nil }
            return CGFloat(Double(value) ?? 1.0)
        }
        set {
            if let value = newValue {
                properties["opacity"] = String(Double(value))
            } else {
                properties.removeValue(forKey: "opacity")
            }
        }
    }

    /// Stroke line cap (butt, round, square)
    public var strokeLinecap: String? {
        get { getProperty("stroke-linecap") }
        set { if let value = newValue { properties["stroke-linecap"] = value } else { properties.removeValue(forKey: "stroke-linecap") } }
    }

    /// Stroke line join (miter, round, bevel)
    public var strokeLinejoin: String? {
        get { getProperty("stroke-linejoin") }
        set { if let value = newValue { properties["stroke-linejoin"] = value } else { properties.removeValue(forKey: "stroke-linejoin") } }
    }

    /// Stroke dash array
    public var strokeDasharray: String? {
        get { getProperty("stroke-dasharray") }
        set { if let value = newValue { properties["stroke-dasharray"] = value } else { properties.removeValue(forKey: "stroke-dasharray") } }
    }

    /// Font family
    public var fontFamily: String? {
        get { getProperty("font-family") }
        set { if let value = newValue { properties["font-family"] = value } else { properties.removeValue(forKey: "font-family") } }
    }

    /// Font size
    public var fontSize: String? {
        get { getProperty("font-size") }
        set { if let value = newValue { properties["font-size"] = value } else { properties.removeValue(forKey: "font-size") } }
    }

    /// Font weight
    public var fontWeight: String? {
        get { getProperty("font-weight") }
        set { if let value = newValue { properties["font-weight"] = value } else { properties.removeValue(forKey: "font-weight") } }
    }

    /// Text anchor (start, middle, end)
    public var textAnchor: String? {
        get { getProperty("text-anchor") }
        set { if let value = newValue { properties["text-anchor"] = value } else { properties.removeValue(forKey: "text-anchor") } }
    }

    /// Display property
    public var display: String? {
        get { getProperty("display") }
        set { if let value = newValue { properties["display"] = value } else { properties.removeValue(forKey: "display") } }
    }

    /// Visibility property
    public var visibility: String? {
        get { getProperty("visibility") }
        set { if let value = newValue { properties["visibility"] = value } else { properties.removeValue(forKey: "visibility") } }
    }
}
