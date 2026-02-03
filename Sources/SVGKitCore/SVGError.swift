import Foundation

/// Errors that can occur during SVG operations
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public enum SVGError: Error, Sendable {
    /// Source-related errors
    case invalidSource(String)
    case fileNotFound(URL)
    case cannotReadFile(URL, underlyingError: Error?)
    case cannotReadData(String)
    case invalidURL(String)
    case networkError(URL, underlyingError: Error?)

    /// Parsing errors
    case parsingFailed(String)
    case invalidSVGData(String)
    case malformedXML(String)

    /// General errors
    case unknown(String)
}

extension SVGError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidSource(let message):
            return "Invalid SVG source: \(message)"
        case .fileNotFound(let url):
            return "SVG file not found at: \(url.path)"
        case .cannotReadFile(let url, let error):
            if let error = error {
                return "Cannot read SVG file at \(url.path): \(error.localizedDescription)"
            } else {
                return "Cannot read SVG file at: \(url.path)"
            }
        case .cannotReadData(let message):
            return "Cannot read SVG data: \(message)"
        case .invalidURL(let urlString):
            return "Invalid URL: \(urlString)"
        case .networkError(let url, let error):
            if let error = error {
                return "Network error loading \(url.absoluteString): \(error.localizedDescription)"
            } else {
                return "Network error loading: \(url.absoluteString)"
            }
        case .parsingFailed(let message):
            return "SVG parsing failed: \(message)"
        case .invalidSVGData(let message):
            return "Invalid SVG data: \(message)"
        case .malformedXML(let message):
            return "Malformed XML: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
