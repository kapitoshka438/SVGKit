import Foundation
import CoreGraphics

/// SVG Transform types
/// W3C Spec: https://www.w3.org/TR/SVG11/coords.html#InterfaceSVGTransform
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public enum SVGTransformType: String, Sendable {
    case matrix
    case translate
    case scale
    case rotate
    case skewX
    case skewY
}

/// SVG Transform
/// Represents a single transformation operation
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct SVGTransform: Sendable, Hashable {
    /// Type of transform
    public let type: SVGTransformType

    /// Transform matrix
    public let matrix: CGAffineTransform

    /// Initialize with matrix
    public init(matrix: CGAffineTransform) {
        self.type = .matrix
        self.matrix = matrix
    }

    /// Initialize with translation
    public init(translateX tx: CGFloat, y ty: CGFloat) {
        self.type = .translate
        self.matrix = CGAffineTransform(translationX: tx, y: ty)
    }

    /// Initialize with scale
    public init(scaleX sx: CGFloat, y sy: CGFloat) {
        self.type = .scale
        self.matrix = CGAffineTransform(scaleX: sx, y: sy)
    }

    /// Initialize with uniform scale
    public init(scale s: CGFloat) {
        self.type = .scale
        self.matrix = CGAffineTransform(scaleX: s, y: s)
    }

    /// Initialize with rotation
    /// - Parameters:
    ///   - angle: Rotation angle in degrees
    ///   - cx: Center X (optional)
    ///   - cy: Center Y (optional)
    public init(rotate angle: CGFloat, cx: CGFloat = 0, cy: CGFloat = 0) {
        self.type = .rotate
        let radians = angle * .pi / 180.0

        if cx == 0 && cy == 0 {
            self.matrix = CGAffineTransform(rotationAngle: radians)
        } else {
            // Rotate around center point: translate, rotate, translate back
            var transform = CGAffineTransform(translationX: cx, y: cy)
            transform = transform.rotated(by: radians)
            transform = transform.translatedBy(x: -cx, y: -cy)
            self.matrix = transform
        }
    }

    /// Initialize with skewX
    /// - Parameter angle: Skew angle in degrees
    public init(skewX angle: CGFloat) {
        self.type = .skewX
        let radians = angle * .pi / 180.0
        let tanAngle = tan(radians)
        self.matrix = CGAffineTransform(a: 1, b: 0, c: tanAngle, d: 1, tx: 0, ty: 0)
    }

    /// Initialize with skewY
    /// - Parameter angle: Skew angle in degrees
    public init(skewY angle: CGFloat) {
        self.type = .skewY
        let radians = angle * .pi / 180.0
        let tanAngle = tan(radians)
        self.matrix = CGAffineTransform(a: 1, b: tanAngle, c: 0, d: 1, tx: 0, ty: 0)
    }

    /// Parse transform string
    /// Supports: translate(x,y), scale(x,y), rotate(angle cx cy), skewX(angle), skewY(angle), matrix(a,b,c,d,e,f)
    /// - Parameter string: Transform string from SVG
    /// - Returns: Array of transforms or nil if parsing failed
    public static func parse(_ string: String) -> [SVGTransform]? {
        var transforms: [SVGTransform] = []
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Regular expression to match transform functions
        let pattern = #"(\w+)\s*\(([\d\s,.\-+]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let matches = regex.matches(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed))

        for match in matches {
            guard let typeRange = Range(match.range(at: 1), in: trimmed),
                  let paramsRange = Range(match.range(at: 2), in: trimmed) else {
                continue
            }

            let type = String(trimmed[typeRange]).lowercased()
            let paramsString = String(trimmed[paramsRange])
            let params = parseNumbers(paramsString)

            guard !params.isEmpty else { continue }

            switch type {
            case "translate":
                if params.count == 1 {
                    transforms.append(SVGTransform(translateX: params[0], y: 0))
                } else if params.count >= 2 {
                    transforms.append(SVGTransform(translateX: params[0], y: params[1]))
                }

            case "scale":
                if params.count == 1 {
                    transforms.append(SVGTransform(scale: params[0]))
                } else if params.count >= 2 {
                    transforms.append(SVGTransform(scaleX: params[0], y: params[1]))
                }

            case "rotate":
                if params.count == 1 {
                    transforms.append(SVGTransform(rotate: params[0]))
                } else if params.count >= 3 {
                    transforms.append(SVGTransform(rotate: params[0], cx: params[1], cy: params[2]))
                }

            case "skewx":
                if params.count >= 1 {
                    transforms.append(SVGTransform(skewX: params[0]))
                }

            case "skewy":
                if params.count >= 1 {
                    transforms.append(SVGTransform(skewY: params[0]))
                }

            case "matrix":
                if params.count >= 6 {
                    let matrix = CGAffineTransform(
                        a: params[0], b: params[1],
                        c: params[2], d: params[3],
                        tx: params[4], ty: params[5]
                    )
                    transforms.append(SVGTransform(matrix: matrix))
                }

            default:
                break
            }
        }

        return transforms.isEmpty ? nil : transforms
    }

    /// Parse comma/space separated numbers
    private static func parseNumbers(_ string: String) -> [CGFloat] {
        let cleaned = string.replacingOccurrences(of: ",", with: " ")
        let components = cleaned.split(separator: " ").compactMap { Double($0) }
        return components.map { CGFloat($0) }
    }

    /// Combine multiple transforms into a single matrix
    /// - Parameter transforms: Array of transforms to combine
    /// - Returns: Combined transform matrix
    public static func combine(_ transforms: [SVGTransform]) -> CGAffineTransform {
        var result = CGAffineTransform.identity
        for transform in transforms {
            result = result.concatenating(transform.matrix)
        }
        return result
    }
}
