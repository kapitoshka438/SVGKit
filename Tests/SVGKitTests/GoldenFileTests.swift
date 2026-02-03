import XCTest
@testable import SVGKitCore
@testable import SVGKitSwift
@testable import SVGKitParser
@testable import SVGKitDOM
@testable import SVGKitRendering

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Golden file tests - Load real SVG files and verify they parse and render correctly
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class GoldenFileTests: XCTestCase {

    let testSVGFiles = [
        "simple-rect.svg",
        "simple-circle.svg",
        "simple-path.svg",
        "g-element-applies-rotation.svg",
        "test-stroke-dash-array.svg",
        "radialGradientTest.svg",
        "Lion.svg",
        "NewTux.svg",
        "RainbowWing.svg"
    ]

    // MARK: - Parsing Tests

    func testParseAllGoldenFiles() async throws {
        for fileName in testSVGFiles {
            guard let url = Bundle.mypackageResources.url(forResource: fileName, withExtension: nil) else {
                XCTFail("Could not find test file: \(fileName)")
                continue
            }

            let image = try await SVGImage(fileURL: url)

            XCTAssertNotNil(image.document, "Failed to parse \(fileName)")
            XCTAssertNotNil(image.document.rootElement, "No root element in \(fileName)")

            print("✓ Successfully parsed: \(fileName)")
        }
    }

    func testSimpleRect() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "simple-rect.svg", withExtension: nil) else {
            XCTFail("Could not find simple-rect.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let root = image.document.rootElement

        XCTAssertNotNil(root)
        XCTAssertEqual(root?.tagName, "svg")

        // Check for rect element
        let rects = root?.getElementsByTagName("rect") ?? []
        XCTAssertGreaterThan(rects.count, 0, "Should have at least one rect element")
    }

    func testSimpleCircle() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "simple-circle.svg", withExtension: nil) else {
            XCTFail("Could not find simple-circle.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let root = image.document.rootElement

        XCTAssertNotNil(root)

        // Check for circle element
        let circles = root?.getElementsByTagName("circle") ?? []
        XCTAssertGreaterThan(circles.count, 0, "Should have at least one circle element")
    }

    func testSimplePath() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "simple-path.svg", withExtension: nil) else {
            XCTFail("Could not find simple-path.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let root = image.document.rootElement

        XCTAssertNotNil(root)

        // Check for path element
        let paths = root?.getElementsByTagName("path") ?? []
        XCTAssertGreaterThan(paths.count, 0, "Should have at least one path element")
    }

    func testGroupWithRotation() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "g-element-applies-rotation.svg", withExtension: nil) else {
            XCTFail("Could not find g-element-applies-rotation.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let root = image.document.rootElement

        XCTAssertNotNil(root)

        // Check for group element
        let groups = root?.getElementsByTagName("g") ?? []
        XCTAssertGreaterThan(groups.count, 0, "Should have at least one g element")
    }

    // MARK: - Rendering Tests

    func testRenderAllGoldenFiles() async throws {
        for fileName in testSVGFiles {
            guard let url = Bundle.mypackageResources.url(forResource: fileName, withExtension: nil) else {
                XCTFail("Could not find test file: \(fileName)")
                continue
            }

            let image = try await SVGImage(fileURL: url)
            let layer = await image.render()

            XCTAssertNotNil(layer, "Failed to render \(fileName)")

            if let layer = layer {
                XCTAssertGreaterThan(layer.bounds.width, 0, "Layer width should be > 0 for \(fileName)")
                XCTAssertGreaterThan(layer.bounds.height, 0, "Layer height should be > 0 for \(fileName)")
            }

            print("✓ Successfully rendered: \(fileName)")
        }
    }

    func testRenderSimpleRect() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "simple-rect.svg", withExtension: nil) else {
            XCTFail("Could not find simple-rect.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let layer = await image.render()

        XCTAssertNotNil(layer)
        XCTAssertGreaterThan(layer?.bounds.width ?? 0, 0)
        XCTAssertGreaterThan(layer?.bounds.height ?? 0, 0)
    }

    func testRenderComplexSVG() async throws {
        // Test with Lion.svg - a more complex SVG
        guard let url = Bundle.mypackageResources.url(forResource: "Lion.svg", withExtension: nil) else {
            XCTFail("Could not find Lion.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let layer = await image.render()

        XCTAssertNotNil(layer)
        XCTAssertGreaterThan(layer?.bounds.width ?? 0, 0)
        XCTAssertGreaterThan(layer?.bounds.height ?? 0, 0)
    }

    // MARK: - Rasterization Tests

    func testRasterizeAllGoldenFiles() async throws {
        for fileName in testSVGFiles {
            guard let url = Bundle.mypackageResources.url(forResource: fileName, withExtension: nil) else {
                XCTFail("Could not find test file: \(fileName)")
                continue
            }

            let image = try await SVGImage(fileURL: url)
            let rasterized = await image.rasterize(scale: 1.0)

            XCTAssertNotNil(rasterized, "Failed to rasterize \(fileName)")

            if let rasterized = rasterized {
                XCTAssertGreaterThan(rasterized.size.width, 0, "Rasterized width should be > 0 for \(fileName)")
                XCTAssertGreaterThan(rasterized.size.height, 0, "Rasterized height should be > 0 for \(fileName)")
            }

            print("✓ Successfully rasterized: \(fileName)")
        }
    }

    // MARK: - DOM Structure Tests

    func testDOMStructureIntegrity() async throws {
        for fileName in testSVGFiles {
            guard let url = Bundle.mypackageResources.url(forResource: fileName, withExtension: nil) else {
                XCTFail("Could not find test file: \(fileName)")
                continue
            }

            let image = try await SVGImage(fileURL: url)
            let root = image.document.rootElement

            XCTAssertNotNil(root, "Root element missing in \(fileName)")

            // Verify DOM tree structure
            if let root = root {
                verifyDOMTree(node: root, fileName: fileName)
            }
        }
    }

    private func verifyDOMTree(node: Node, fileName: String, depth: Int = 0) {
        // Verify parent-child relationships
        for child in node.childNodes {
            XCTAssertTrue(child.parentNode === node, "Parent reference broken in \(fileName)")

            // Verify sibling relationships
            if let firstChild = node.firstChild {
                XCTAssertNotNil(firstChild.parentNode, "First child has no parent in \(fileName)")
            }

            if let lastChild = node.lastChild {
                XCTAssertNotNil(lastChild.parentNode, "Last child has no parent in \(fileName)")
            }

            // Recursively verify children
            if depth < 20, let childNode = child as? Node { // Prevent infinite recursion
                verifyDOMTree(node: childNode, fileName: fileName, depth: depth + 1)
            }
        }
    }

    // MARK: - Element Count Tests

    func testElementCounts() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "Lion.svg", withExtension: nil) else {
            XCTFail("Could not find Lion.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)
        let root = image.document.rootElement

        // Count different element types
        let paths = root?.getElementsByTagName("path") ?? []
        let groups = root?.getElementsByTagName("g") ?? []

        print("Lion.svg contains:")
        print("  - \(paths.count) path elements")
        print("  - \(groups.count) group elements")

        // Complex SVGs should have many elements
        XCTAssertGreaterThan(paths.count + groups.count, 0, "Should have some elements")
    }

    // MARK: - Size Tests

    func testIntrinsicSizes() async throws {
        for fileName in testSVGFiles {
            guard let url = Bundle.mypackageResources.url(forResource: fileName, withExtension: nil) else {
                continue
            }

            let image = try await SVGImage(fileURL: url)

            if let size = image.intrinsicSize {
                print("\(fileName): \(size.width) x \(size.height)")
                XCTAssertGreaterThan(size.width, 0)
                XCTAssertGreaterThan(size.height, 0)
            } else {
                print("\(fileName): No intrinsic size")
            }
        }
    }

    // MARK: - Export Tests

    func testExportAllFormats() async throws {
        guard let url = Bundle.mypackageResources.url(forResource: "simple-rect.svg", withExtension: nil) else {
            XCTFail("Could not find simple-rect.svg")
            return
        }

        let image = try await SVGImage(fileURL: url)

        // Test PNG export
        let pngData = await image.exportPNG()
        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData?.count ?? 0, 0)

        // Test JPEG export
        let jpegData = await image.exportJPEG()
        XCTAssertNotNil(jpegData)
        XCTAssertGreaterThan(jpegData?.count ?? 0, 0)

        // Test PDF export
        let pdfData = await image.exportPDF()
        XCTAssertNotNil(pdfData)
        XCTAssertGreaterThan(pdfData?.count ?? 0, 0)
    }
}
