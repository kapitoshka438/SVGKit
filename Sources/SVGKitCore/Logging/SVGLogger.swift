import OSLog

/// Centralized logging infrastructure for SVGKit
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public enum SVGLogger {
    /// Logger for parsing-related operations
    public static let parser = Logger(subsystem: "com.svgkit", category: "parser")

    /// Logger for DOM operations
    public static let dom = Logger(subsystem: "com.svgkit", category: "dom")

    /// Logger for rendering operations
    public static let rendering = Logger(subsystem: "com.svgkit", category: "rendering")

    /// Logger for general SVGKit operations
    public static let general = Logger(subsystem: "com.svgkit", category: "general")

    /// Logger for cache operations
    public static let cache = Logger(subsystem: "com.svgkit", category: "cache")
}
