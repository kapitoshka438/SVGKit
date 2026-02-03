import Foundation
import QuartzCore
import SVGKitCore
import SVGKitRendering

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Export utilities for SVGImage
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension SVGImage {

    // MARK: - PNG Export

    /// Export to PNG data
    /// - Parameters:
    ///   - size: Target size (nil = use intrinsic size)
    ///   - scale: Scale factor (default: 1.0)
    ///   - options: Rendering options
    /// - Returns: PNG data
    public func exportPNG(
        size: CGSize? = nil,
        scale: CGFloat = 1.0,
        options: RenderOptions = RenderOptions()
    ) async -> Data? {
        guard let image = await rasterize(size: size, scale: scale, options: options) else {
            return nil
        }

        #if canImport(UIKit)
        return image.pngData()
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    /// Export to PNG file
    /// - Parameters:
    ///   - url: File URL to write to
    ///   - size: Target size (nil = use intrinsic size)
    ///   - scale: Scale factor (default: 1.0)
    ///   - options: Rendering options
    /// - Throws: Error if writing fails
    public func exportPNG(
        to url: URL,
        size: CGSize? = nil,
        scale: CGFloat = 1.0,
        options: RenderOptions = RenderOptions()
    ) async throws {
        guard let data = await exportPNG(size: size, scale: scale, options: options) else {
            throw SVGError.unknown("Failed to generate PNG data")
        }
        try data.write(to: url)
    }

    // MARK: - JPEG Export

    /// Export to JPEG data
    /// - Parameters:
    ///   - size: Target size (nil = use intrinsic size)
    ///   - scale: Scale factor (default: 1.0)
    ///   - compressionQuality: JPEG compression quality (0.0 - 1.0)
    ///   - backgroundColor: Background color (default: white)
    ///   - options: Rendering options
    /// - Returns: JPEG data
    public func exportJPEG(
        size: CGSize? = nil,
        scale: CGFloat = 1.0,
        compressionQuality: CGFloat = 0.9,
        backgroundColor: CGColor? = nil,
        options: RenderOptions = RenderOptions()
    ) async -> Data? {
        // JPEG doesn't support transparency, so we need a background
        var exportOptions = options
        exportOptions.backgroundColor = backgroundColor ?? CGColor(gray: 1.0, alpha: 1.0)

        guard let image = await rasterize(size: size, scale: scale, options: exportOptions) else {
            return nil
        }

        #if canImport(UIKit)
        return image.jpegData(compressionQuality: compressionQuality)
        #elseif canImport(AppKit)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionQuality]
        )
        #endif
    }

    /// Export to JPEG file
    /// - Parameters:
    ///   - url: File URL to write to
    ///   - size: Target size (nil = use intrinsic size)
    ///   - scale: Scale factor (default: 1.0)
    ///   - compressionQuality: JPEG compression quality (0.0 - 1.0)
    ///   - backgroundColor: Background color (default: white)
    ///   - options: Rendering options
    /// - Throws: Error if writing fails
    public func exportJPEG(
        to url: URL,
        size: CGSize? = nil,
        scale: CGFloat = 1.0,
        compressionQuality: CGFloat = 0.9,
        backgroundColor: CGColor? = nil,
        options: RenderOptions = RenderOptions()
    ) async throws {
        guard let data = await exportJPEG(
            size: size,
            scale: scale,
            compressionQuality: compressionQuality,
            backgroundColor: backgroundColor,
            options: options
        ) else {
            throw SVGError.unknown("Failed to generate JPEG data")
        }
        try data.write(to: url)
    }

    // MARK: - PDF Export

    /// Export to PDF data
    /// - Parameters:
    ///   - size: Target size (nil = use intrinsic size)
    ///   - options: Rendering options
    /// - Returns: PDF data
    public func exportPDF(
        size: CGSize? = nil,
        options: RenderOptions = RenderOptions()
    ) async -> Data? {
        let targetSize = size ?? intrinsicSize ?? CGSize(width: 300, height: 150)

        guard let layer = await render(size: targetSize, options: options) else {
            return nil
        }

        // Create PDF context
        let pdfData = NSMutableData()

        #if canImport(UIKit)
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: targetSize), nil)
        UIGraphicsBeginPDFPage()

        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            return nil
        }

        layer.render(in: context)
        UIGraphicsEndPDFContext()

        #elseif canImport(AppKit)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return nil
        }

        context.beginPDFPage(nil)

        // Set up coordinate system to match UIKit (origin at top-left)
        context.translateBy(x: 0, y: targetSize.height)
        context.scaleBy(x: 1.0, y: -1.0)

        layer.render(in: context)
        context.endPDFPage()
        context.closePDF()
        #endif

        return pdfData as Data
    }

    /// Export to PDF file
    /// - Parameters:
    ///   - url: File URL to write to
    ///   - size: Target size (nil = use intrinsic size)
    ///   - options: Rendering options
    /// - Throws: Error if writing fails
    public func exportPDF(
        to url: URL,
        size: CGSize? = nil,
        options: RenderOptions = RenderOptions()
    ) async throws {
        guard let data = await exportPDF(size: size, options: options) else {
            throw SVGError.unknown("Failed to generate PDF data")
        }
        try data.write(to: url)
    }
}
