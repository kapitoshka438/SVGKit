import Foundation
import QuartzCore
import SVGKitCore
import SVGKitDOM
import SVGKitParser
import SVGKitRendering

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Modern Swift wrapper for SVG documents
/// Provides easy loading, rendering, and caching of SVG files
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class SVGImage: @unchecked Sendable {
    /// The parsed SVG document
    public let document: SVGDocument

    /// The SVG source
    public let source: SVGSource

    /// Intrinsic size from SVG (if available)
    public let intrinsicSize: CGSize?

    /// Private renderer instance
    private let renderer = SVGRenderer()

    // MARK: - Initialization

    /// Initialize with a parsed document
    /// - Parameter document: Parsed SVG document
    public init(document: SVGDocument, source: SVGSource) {
        self.document = document
        self.source = source
        self.intrinsicSize = Self.calculateIntrinsicSize(from: document)
    }

    /// Load SVG from source
    /// - Parameter source: SVG source (file, URL, data, string)
    /// - Throws: SVGError if loading or parsing fails
    public convenience init(source: SVGSource) async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let result = try await parser.parse(from: source)

        guard let document = result.document else {
            throw SVGError.parsingFailed("Failed to parse SVG document")
        }

        self.init(document: document, source: source)
    }

    /// Load SVG from file URL
    /// - Parameter url: File URL to SVG
    /// - Throws: SVGError if loading or parsing fails
    public convenience init(fileURL url: URL) async throws {
        try await self.init(source: .file(url))
    }

    /// Load SVG from remote URL
    /// - Parameter url: Remote URL to SVG
    /// - Throws: SVGError if loading or parsing fails
    public convenience init(url: URL) async throws {
        try await self.init(source: .url(url))
    }

    /// Load SVG from data
    /// - Parameters:
    ///   - data: SVG data
    ///   - baseURL: Optional base URL for resolving relative references
    /// - Throws: SVGError if parsing fails
    public convenience init(data: Data, baseURL: URL? = nil) async throws {
        try await self.init(source: .data(data, baseURL: baseURL))
    }

    /// Load SVG from string
    /// - Parameters:
    ///   - string: SVG string
    ///   - baseURL: Optional base URL for resolving relative references
    /// - Throws: SVGError if parsing fails
    public convenience init(string: String, baseURL: URL? = nil) async throws {
        try await self.init(source: .string(string, baseURL: baseURL))
    }

    /// Load SVG from named resource in bundle
    /// - Parameters:
    ///   - name: Resource name (without extension)
    ///   - bundle: Bundle containing the resource (default: main bundle)
    /// - Throws: SVGError if resource not found or parsing fails
    public convenience init(named name: String, in bundle: Bundle = .main) async throws {
        let source = try SVGSource.named(name, in: bundle)
        try await self.init(source: source)
    }

    // MARK: - Rendering

    /// Render to CALayer
    /// - Parameters:
    ///   - size: Target size (nil = use intrinsic size)
    ///   - options: Rendering options
    /// - Returns: CALayer with rendered content
    public func render(
        size: CGSize? = nil,
        options: RenderOptions = RenderOptions()
    ) async -> CALayer? {
        let targetSize = size ?? intrinsicSize
        return await renderer.render(document: document, size: targetSize, options: options)
    }

    /// Rasterize to platform image
    /// - Parameters:
    ///   - size: Target size (nil = use intrinsic size)
    ///   - scale: Scale factor (default: screen scale)
    ///   - options: Rendering options
    /// - Returns: Rasterized image
    public func rasterize(
        size: CGSize? = nil,
        scale: CGFloat = 0,
        options: RenderOptions = RenderOptions()
    ) async -> PlatformImage? {
        let targetSize = size ?? intrinsicSize ?? CGSize(width: 300, height: 150)

        #if canImport(UIKit)
        let screenScale = scale > 0 ? scale : await MainActor.run { UIScreen.main.scale }
        #elseif canImport(AppKit)
        let screenScale = scale > 0 ? scale : await MainActor.run { NSScreen.main?.backingScaleFactor ?? 1.0 }
        #endif

        // Create options with scale
        var renderOptions = options
        renderOptions.scale = screenScale

        guard let layer = await renderer.render(document: document, size: targetSize, options: renderOptions) else {
            return nil
        }

        // Rasterize layer to image

        #if canImport(UIKit)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, screenScale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }

        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image

        #elseif canImport(AppKit)
        let image = NSImage(size: targetSize)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        layer.render(in: context)
        image.unlockFocus()

        return image
        #endif
    }

    // MARK: - Helpers

    private static func calculateIntrinsicSize(from document: SVGDocument) -> CGSize? {
        guard let root = document.rootElement else { return nil }

        let context = SVGRenderContext()

        // Try width/height attributes
        if let width = root.width?.pixelsValue(in: context),
           let height = root.height?.pixelsValue(in: context) {
            return CGSize(width: CGFloat(width), height: CGFloat(height))
        }

        // Try viewBox
        if let viewBox = root.viewBox {
            let components = viewBox.split(separator: " ").compactMap { Double($0) }
            if components.count >= 4 {
                return CGSize(width: components[2], height: components[3])
            }
        }

        return nil
    }
}
