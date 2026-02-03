import XCTest
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Helper for comparing rendered images against golden file baselines
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public final class GoldenFileComparator {

    /// Compare two images pixel by pixel
    /// - Parameters:
    ///   - image1: First image to compare
    ///   - image2: Second image to compare
    ///   - tolerance: Acceptable difference per pixel (0.0 to 1.0)
    /// - Returns: True if images are equal within tolerance
    public static func imagesAreEqual(_ image1: PlatformImage, _ image2: PlatformImage, tolerance: Float = 0.01) -> Bool {
        #if canImport(UIKit)
        guard let cgImage1 = image1.cgImage, let cgImage2 = image2.cgImage else {
            return false
        }
        #elseif canImport(AppKit)
        guard let cgImage1 = image1.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cgImage2 = image2.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }
        #endif

        // Check dimensions
        guard cgImage1.width == cgImage2.width && cgImage1.height == cgImage2.height else {
            return false
        }

        let width = cgImage1.width
        let height = cgImage1.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        // Allocate pixel data
        var pixelData1 = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        var pixelData2 = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context1 = CGContext(
            data: &pixelData1,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ),
        let context2 = CGContext(
            data: &pixelData2,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return false
        }

        // Draw images into contexts
        context1.draw(cgImage1, in: CGRect(x: 0, y: 0, width: width, height: height))
        context2.draw(cgImage2, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Compare pixel data
        let pixelCount = width * height * bytesPerPixel
        var totalDifference: Float = 0

        for i in 0..<pixelCount {
            let diff = abs(Float(pixelData1[i]) - Float(pixelData2[i])) / 255.0
            totalDifference += diff
        }

        let averageDifference = totalDifference / Float(pixelCount)
        return averageDifference <= tolerance
    }

    /// Calculate difference percentage between two images
    /// - Parameters:
    ///   - image1: First image
    ///   - image2: Second image
    /// - Returns: Difference percentage (0.0 to 1.0)
    public static func imageDifference(_ image1: PlatformImage, _ image2: PlatformImage) -> Float {
        #if canImport(UIKit)
        guard let cgImage1 = image1.cgImage, let cgImage2 = image2.cgImage else {
            return 1.0
        }
        #elseif canImport(AppKit)
        guard let cgImage1 = image1.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let cgImage2 = image2.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return 1.0
        }
        #endif

        guard cgImage1.width == cgImage2.width && cgImage1.height == cgImage2.height else {
            return 1.0
        }

        let width = cgImage1.width
        let height = cgImage1.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData1 = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        var pixelData2 = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context1 = CGContext(
            data: &pixelData1,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ),
        let context2 = CGContext(
            data: &pixelData2,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return 1.0
        }

        context1.draw(cgImage1, in: CGRect(x: 0, y: 0, width: width, height: height))
        context2.draw(cgImage2, in: CGRect(x: 0, y: 0, width: width, height: height))

        let pixelCount = width * height * bytesPerPixel
        var totalDifference: Float = 0

        for i in 0..<pixelCount {
            let diff = abs(Float(pixelData1[i]) - Float(pixelData2[i])) / 255.0
            totalDifference += diff
        }

        return totalDifference / Float(pixelCount)
    }
}

// MARK: - XCTest Assertions

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public extension XCTestCase {
    /// Assert that two images are equal within tolerance
    func XCTAssertImagesEqual(
        _ image1: PlatformImage,
        _ image2: PlatformImage,
        tolerance: Float = 0.01,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let difference = GoldenFileComparator.imageDifference(image1, image2)
        XCTAssertLessThanOrEqual(
            difference,
            tolerance,
            "Images differ by \(difference * 100)%, tolerance is \(tolerance * 100)%. \(message())",
            file: file,
            line: line
        )
    }
}

// MARK: - Platform Abstraction

#if canImport(UIKit)
public typealias PlatformImage = UIKit.UIImage
#elseif canImport(AppKit)
public typealias PlatformImage = AppKit.NSImage
#endif
