import XCTest
@testable import SVGKitCore
@testable import SVGKitSwift
@testable import SVGKitParser
@testable import SVGKitDOM
@testable import SVGKitRendering

/// Performance benchmarks for SVGKit
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class PerformanceTests: XCTestCase {

    // MARK: - Parsing Performance

    func testParsingSimpleSVGPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        measure {
            Task {
                _ = try? await SVGImage(string: svgString, baseURL: nil)
            }
        }
    }

    func testParsingComplexSVGPerformance() async throws {
        // Create a complex SVG with many elements
        var svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000">
        """

        // Add 100 rectangles
        for i in 0..<100 {
            let x = (i % 10) * 100
            let y = (i / 10) * 100
            svgString += """
              <rect x="\(x)" y="\(y)" width="90" height="90" fill="blue" opacity="0.5" />
            """
        }

        svgString += "</svg>"

        measure {
            Task {
                _ = try? await SVGImage(string: svgString, baseURL: nil)
            }
        }
    }

    func testParsingFromFilePerformance() throws {
        guard let url = Bundle.mypackageResources.url(forResource: "Lion.svg", withExtension: nil) else {
            XCTFail("Could not find Lion.svg")
            return
        }

        measure {
            Task {
                _ = try? await SVGImage(fileURL: url)
            }
        }
    }

    // MARK: - Rendering Performance

    func testRenderingSimpleSVGPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
          <circle cx="50" cy="50" r="30" fill="red" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                _ = await image.render()
            }
        }
    }

    func testRenderingComplexSVGPerformance() async throws {
        // Create SVG with many shapes
        var svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">
        """

        for i in 0..<50 {
            svgString += """
              <rect x="\(i * 10)" y="\(i * 10)" width="50" height="50" fill="blue" opacity="0.3" />
              <circle cx="\(i * 10 + 25)" cy="\(i * 10 + 25)" r="20" fill="red" opacity="0.3" />
            """
        }

        svgString += "</svg>"

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                _ = await image.render()
            }
        }
    }

    func testRenderingWithCustomSizePerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let customSize = CGSize(width: 500, height: 500)

        measure {
            Task {
                _ = await image.render(size: customSize)
            }
        }
    }

    // MARK: - Rasterization Performance

    func testRasterizationPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <rect x="20" y="20" width="160" height="160" fill="green" />
          <circle cx="100" cy="100" r="60" fill="yellow" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                _ = await image.rasterize(scale: 2.0)
            }
        }
    }

    func testRasterizationHighResolutionPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let largeSize = CGSize(width: 2000, height: 2000)

        measure {
            Task {
                _ = await image.rasterize(size: largeSize, scale: 3.0)
            }
        }
    }

    // MARK: - Export Performance

    func testPNGExportPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <rect x="20" y="20" width="160" height="160" fill="purple" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                _ = await image.exportPNG()
            }
        }
    }

    func testJPEGExportPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <rect x="20" y="20" width="160" height="160" fill="orange" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                _ = await image.exportJPEG()
            }
        }
    }

    func testPDFExportPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <rect x="20" y="20" width="160" height="160" fill="teal" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                _ = await image.exportPDF()
            }
        }
    }

    // MARK: - Cache Performance

    func testCachePerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let cache = SVGCache()
        let source = SVGSource.string(svgString, baseURL: nil)

        // Pre-populate cache
        _ = try await cache.image(from: source)

        measure {
            Task {
                // This should hit the cache
                _ = try? await cache.image(from: source)
            }
        }
    }

    // MARK: - DOM Traversal Performance

    func testDOMTraversalPerformance() async throws {
        // Create a deep DOM tree
        var svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        """

        // Create nested groups
        for _ in 0..<10 {
            svgString += "<g>"
        }

        svgString += "<rect x=\"10\" y=\"10\" width=\"80\" height=\"80\" fill=\"blue\" />"

        for _ in 0..<10 {
            svgString += "</g>"
        }

        svgString += "</svg>"

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let root = image.document.rootElement

        measure {
            // Traverse entire tree
            var count = 0
            func traverse(_ node: Node) {
                count += 1
                for child in node.childNodes {
                    if let childNode = child as? Node {
                        traverse(childNode)
                    }
                }
            }

            if let root = root {
                traverse(root)
            }
        }
    }

    func testElementSearchPerformance() async throws {
        // Create SVG with many elements
        var svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000">
        """

        for i in 0..<100 {
            svgString += """
              <rect id="rect\(i)" x="\(i * 10)" y="\(i * 10)" width="50" height="50" fill="blue" />
            """
        }

        svgString += "</svg>"

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let document = image.document

        measure {
            // Search for element by ID
            _ = document.getElementById("rect50")
        }
    }

    // MARK: - Multiple Render Performance

    func testMultipleRendersPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        measure {
            Task {
                // Render multiple times
                for _ in 0..<10 {
                    _ = await image.render()
                }
            }
        }
    }

    // MARK: - Memory Performance

    func testMemoryEfficiencyWithManyImages() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        measure {
            Task {
                // Create many images
                var images: [SVGImage] = []
                for _ in 0..<100 {
                    if let image = try? await SVGImage(string: svgString, baseURL: nil) {
                        images.append(image)
                    }
                }
                // Force retention
                _ = images.count
            }
        }
    }

    // MARK: - Concurrent Performance

    func testConcurrentParsingPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        measure {
            Task {
                // Parse 10 SVGs concurrently
                await withTaskGroup(of: SVGImage?.self) { group in
                    for _ in 0..<10 {
                        group.addTask {
                            try? await SVGImage(string: svgString, baseURL: nil)
                        }
                    }

                    var results: [SVGImage?] = []
                    for await result in group {
                        results.append(result)
                    }
                }
            }
        }
    }

    func testConcurrentRenderingPerformance() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let images = try await (0..<10).asyncMap { _ in
            try await SVGImage(string: svgString, baseURL: nil)
        }

        measure {
            Task {
                // Render 10 SVGs concurrently
                await withTaskGroup(of: Void.self) { group in
                    for image in images {
                        group.addTask {
                            _ = await image.render()
                        }
                    }
                }
            }
        }
    }
}

// Helper extension for async map
extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}
