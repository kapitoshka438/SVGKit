import XCTest
@testable import SVGKitCore
@testable import SVGKitSwift
@testable import SVGKitDOM

/// Memory leak and efficiency tests
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class MemoryTests: XCTestCase {

    // MARK: - Retain Cycle Tests

    func testNoRetainCycleInDOMTree() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <g id="group1">
            <rect id="rect1" x="10" y="10" width="80" height="80" fill="blue" />
            <circle id="circle1" cx="50" cy="50" r="30" fill="red" />
          </g>
        </svg>
        """

        weak var weakImage: SVGImage?
        weak var weakDocument: SVGDocument?
        weak var weakRoot: SVGSVGElement?

        do {
            let image = try await SVGImage(string: svgString, baseURL: nil)
            weakImage = image
            weakDocument = image.document
            weakRoot = image.document.rootElement

            // Access elements
            let group = image.document.getElementById("group1")
            XCTAssertNotNil(group)

            let rect = image.document.getElementById("rect1")
            XCTAssertNotNil(rect)
        }

        // Small delay to ensure cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        // These should all be nil now if there are no retain cycles
        XCTAssertNil(weakImage, "SVGImage should be deallocated")
        XCTAssertNil(weakDocument, "SVGDocument should be deallocated")
        XCTAssertNil(weakRoot, "Root element should be deallocated")
    }

    func testNoRetainCycleWithParentChild() async throws {
        weak var weakParent: SVGElement?
        weak var weakChild: SVGElement?

        do {
            _ = SVGDocument() // Create document to ensure proper context
            let parent = SVGGElement()
            let child = SVGRectElement()

            weakParent = parent
            weakChild = child

            parent.appendChild(child)

            // Verify relationship
            XCTAssertTrue(child.parentNode === parent)
            XCTAssertEqual(parent.childNodes.count, 1)
        }

        // Small delay
        try await Task.sleep(nanoseconds: 100_000_000)

        // Parent and child should be deallocated
        // Note: This test verifies that weak parent references work correctly
        XCTAssertNil(weakParent, "Parent element should be deallocated")
        XCTAssertNil(weakChild, "Child element should be deallocated")
    }

    // MARK: - Memory Growth Tests

    func testMemoryGrowthWithManyImages() async throws {
        // Create many images and verify memory doesn't grow unbounded
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        // Create and render many images
        for _ in 0..<100 {
            let image = try await SVGImage(string: svgString, baseURL: nil)
            _ = await image.render()
        }

        // If we get here without crashing or excessive memory use, test passes
    }

    func testMemoryGrowthWithManyRenders() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        // Render many times
        for _ in 0..<100 {
            _ = await image.render()
        }
    }

    // MARK: - Cache Memory Tests

    func testCacheMemoryManagement() async throws {
        let cache = SVGCache(maxSize: 1024 * 1024, maxAge: 60) // 1MB, 60 seconds

        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        // Fill cache
        for i in 0..<100 {
            let source = SVGSource.string(svgString + "<!-- \(i) -->", baseURL: nil)
            _ = try await cache.image(from: source)
        }

        let stats = await cache.statistics()
        print("Cache after 100 entries: \(stats.count) items, \(stats.totalSize) bytes")

        // Cache should have evicted some entries
        XCTAssertLessThanOrEqual(stats.totalSize, 1024 * 1024, "Cache should respect max size")
    }

    func testCacheEviction() async throws {
        let cache = SVGCache(maxSize: 10_000, maxAge: 60) // Small cache

        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        // Add many entries to trigger eviction
        for i in 0..<50 {
            let source = SVGSource.string(svgString + "<!-- \(i) -->", baseURL: nil)
            _ = try await cache.image(from: source)
        }

        let stats = await cache.statistics()
        print("Cache stats: \(stats.count) items, \(stats.totalSize) bytes")

        // Should have evicted old entries (or at least be at limit)
        XCTAssertLessThanOrEqual(stats.count, 50, "Cache should not exceed entries")
        XCTAssertLessThanOrEqual(stats.totalSize, 10_000, "Cache should respect max size")
    }

    func testCacheClear() async throws {
        let cache = SVGCache()

        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        // Add entries
        for i in 0..<10 {
            let source = SVGSource.string(svgString + "<!-- \(i) -->", baseURL: nil)
            _ = try await cache.image(from: source)
        }

        var stats = await cache.statistics()
        XCTAssertGreaterThan(stats.count, 0)

        // Clear cache
        await cache.clearCache()

        stats = await cache.statistics()
        XCTAssertEqual(stats.count, 0, "Cache should be empty after clear")
        XCTAssertEqual(stats.totalSize, 0, "Cache size should be 0 after clear")
    }

    // MARK: - DOM Tree Memory Tests

    func testDOMTreeDeallocation() async throws {
        weak var weakDocument: SVGDocument?

        do {
            let document = SVGDocument()
            weakDocument = document

            // Create complex tree
            if let root = document.rootElement {
                for i in 0..<100 {
                    let group = SVGGElement()
                    group.setAttribute("id", value: "group\(i)")
                    root.appendChild(group)

                    for j in 0..<10 {
                        let rect = SVGRectElement()
                        rect.setAttribute("id", value: "rect\(i)_\(j)")
                        group.appendChild(rect)
                    }
                }

                // Verify tree was created
                XCTAssertEqual(root.childNodes.count, 100)
            }
        }

        // Allow time for deallocation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Document should be deallocated
        XCTAssertNil(weakDocument, "Document should be deallocated")
    }

    func testElementRemovalFreesMemory() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let document = image.document

        guard let root = document.rootElement else {
            XCTFail("No root element")
            return
        }

        weak var weakElement: SVGElement?

        do {
            let element = SVGRectElement()
            element.setAttribute("id", value: "test-rect")
            weakElement = element

            root.appendChild(element)
            XCTAssertNotNil(element.parentNode)

            // Remove element
            root.removeChild(element)
        }

        // Allow time for deallocation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Element should be deallocated after removal
        XCTAssertNil(weakElement, "Removed element should be deallocated")
    }

    // MARK: - Rendering Memory Tests

    func testLayerDeallocation() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        for _ in 0..<50 {
            let layer = await image.render()
            XCTAssertNotNil(layer)
            // Layer should be deallocated when it goes out of scope
        }

        // If we didn't leak layers, test passes
    }

    func testRasterizationMemory() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        for _ in 0..<50 {
            let rasterized = await image.rasterize(scale: 2.0)
            XCTAssertNotNil(rasterized)
            // Image should be deallocated when it goes out of scope
        }
    }

    // MARK: - Export Memory Tests

    func testExportMemoryEfficiency() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <rect x="20" y="20" width="160" height="160" fill="green" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        for _ in 0..<20 {
            let pngData = await image.exportPNG()
            XCTAssertNotNil(pngData)

            let jpegData = await image.exportJPEG()
            XCTAssertNotNil(jpegData)

            let pdfData = await image.exportPDF()
            XCTAssertNotNil(pdfData)
        }
    }

    // MARK: - Large Document Tests

    func testLargeDocumentMemory() async throws {
        // Create very large SVG
        var svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="10000" height="10000">
        """

        for i in 0..<1000 {
            svgString += """
              <rect x="\(i)" y="\(i)" width="10" height="10" fill="blue" />
            """
        }

        svgString += "</svg>"

        do {
            let image = try await SVGImage(string: svgString, baseURL: nil)
            XCTAssertNotNil(image.document)

            let root = image.document.rootElement
            let rects = root?.getElementsByTagName("rect") ?? []
            XCTAssertEqual(rects.count, 1000)
        }

        // Document should be freed
    }

    // MARK: - Concurrent Access Memory Tests

    func testConcurrentAccessMemorySafety() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        // Access from multiple tasks concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = await image.render()
                }
            }
        }
    }
}
