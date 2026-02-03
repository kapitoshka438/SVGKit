import XCTest
@testable import SVGKitCore
@testable import SVGKitSwift
@testable import SVGKitRendering

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGImageTests: XCTestCase {

    func testInitWithString() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        XCTAssertNotNil(image.document)
        XCTAssertEqual(image.intrinsicSize?.width, 100)
        XCTAssertEqual(image.intrinsicSize?.height, 100)
    }

    func testInitWithData() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="150">
          <circle cx="100" cy="75" r="50" fill="red" />
        </svg>
        """
        let data = svgString.data(using: .utf8)!

        let image = try await SVGImage(data: data, baseURL: nil)

        XCTAssertNotNil(image.document)
        XCTAssertEqual(image.intrinsicSize?.width, 200)
        XCTAssertEqual(image.intrinsicSize?.height, 150)
    }

    func testRenderToLayer() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="green" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let layer = await image.render()

        XCTAssertNotNil(layer)
        XCTAssertEqual(layer?.bounds.size.width, 100)
        XCTAssertEqual(layer?.bounds.size.height, 100)
    }

    func testRenderWithCustomSize() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let customSize = CGSize(width: 200, height: 200)
        let layer = await image.render(size: customSize)

        XCTAssertNotNil(layer)
        XCTAssertEqual(layer?.bounds.size.width, 200)
        XCTAssertEqual(layer?.bounds.size.height, 200)
    }

    func testRasterize() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">
          <circle cx="25" cy="25" r="20" fill="orange" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let rasterized = await image.rasterize(scale: 1.0)

        XCTAssertNotNil(rasterized)
        XCTAssertEqual(rasterized?.size.width, 50)
        XCTAssertEqual(rasterized?.size.height, 50)
    }

    func testIntrinsicSizeFromViewBox() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 200">
          <rect x="10" y="10" width="280" height="180" fill="purple" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        XCTAssertNotNil(image.intrinsicSize)
        XCTAssertEqual(image.intrinsicSize?.width, 300)
        XCTAssertEqual(image.intrinsicSize?.height, 200)
    }

    func testNoIntrinsicSize() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <rect x="10" y="10" width="80" height="80" fill="gray" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        XCTAssertNil(image.intrinsicSize)
    }

    func testRenderOptions() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        let options = RenderOptions(
            scale: 2.0,
            backgroundColor: nil,
            antialiasing: true,
            fitToViewport: false
        )

        let layer = await image.render(options: options)

        XCTAssertNotNil(layer)
    }

    func testMultipleRenders() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="red" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        // Render multiple times
        let layer1 = await image.render()
        let layer2 = await image.render()
        let layer3 = await image.render(size: CGSize(width: 200, height: 200))

        XCTAssertNotNil(layer1)
        XCTAssertNotNil(layer2)
        XCTAssertNotNil(layer3)
        XCTAssertNotEqual(layer1, layer2) // Different instances
    }
}
