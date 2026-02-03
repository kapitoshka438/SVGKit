import Foundation
import OSLog
import SVGKitCore
@preconcurrency import SVGKitDOM

/// Result of parsing an SVG document
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct ParseResult: Sendable {
    /// The parsed document
    public let document: SVGDocument?

    /// The root node (Document or SVGElement)
    public var rootNode: (any DOMNode)? {
        return document
    }

    /// Parsing errors (non-fatal)
    public let errors: [SVGError]

    /// Parsing warnings
    public let warnings: [String]

    /// Success flag
    public var isSuccess: Bool {
        return document != nil && errors.isEmpty
    }

    public init(
        document: SVGDocument?,
        errors: [SVGError] = [],
        warnings: [String] = []
    ) {
        self.document = document
        self.errors = errors
        self.warnings = warnings
    }
}

/// Main SVG parser using Foundation's XMLParser
/// Replaces libxml2-based parsing with pure Swift implementation
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public actor SVGParser {
    /// Parser extensions to handle different elements
    private var extensions: [any ParserExtension]

    /// Logger
    private let logger = SVGLogger.parser

    /// Initialize parser with extensions
    /// - Parameter extensions: Array of parser extensions
    public init(extensions: [any ParserExtension] = []) {
        self.extensions = extensions
    }

    /// Parse SVG data from a source
    /// - Parameter source: The SVG source
    /// - Returns: Parse result with document or errors
    public func parse(from source: SVGSource) async throws -> ParseResult {
        logger.info("Starting parse from source: \(source.cacheKey)")

        // Load data
        let data: Data
        do {
            data = try await source.loadDataAsync()
            logger.debug("Loaded \(data.count) bytes")
        } catch let error as SVGError {
            return ParseResult(document: nil, errors: [error])
        } catch {
            return ParseResult(document: nil, errors: [.unknown(error.localizedDescription)])
        }

        // Create XMLParser
        let xmlParser = XMLParser(data: data)
        xmlParser.shouldProcessNamespaces = true
        xmlParser.shouldReportNamespacePrefixes = true

        // Create delegate
        let delegate = SVGParserDelegate(extensions: extensions, source: source)
        xmlParser.delegate = delegate

        // Parse
        let success = xmlParser.parse()

        logger.info("Parse completed. Success: \(success)")

        if !success, let error = xmlParser.parserError {
            var errors = delegate.errors
            errors.append(.malformedXML(error.localizedDescription))
            return ParseResult(
                document: delegate.document,
                errors: errors,
                warnings: delegate.warnings
            )
        }

        return ParseResult(
            document: delegate.document,
            errors: delegate.errors,
            warnings: delegate.warnings
        )
    }

    /// Add a parser extension
    public func addExtension(_ extension: any ParserExtension) {
        extensions.append(`extension`)
        logger.debug("Added parser extension supporting namespaces: \(`extension`.supportedNamespaces)")
    }

    /// Add multiple parser extensions
    public func addExtensions(_ extensions: [any ParserExtension]) {
        for ext in extensions {
            self.addExtension(ext)
        }
    }
}
