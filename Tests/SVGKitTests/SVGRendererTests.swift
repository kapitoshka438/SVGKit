import XCTest
import QuartzCore
@testable import SVGKitCore
@testable import SVGKitParser
@testable import SVGKitDOM
@testable import SVGKitRendering

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGRendererTests: XCTestCase {

    func testRendererInitialization() {
        let renderer = SVGRenderer()
        XCTAssertNotNil(renderer)
    }

    func testRenderSimpleRect() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.document)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
        XCTAssertEqual(layer?.bounds.size.width, 100)
        XCTAssertEqual(layer?.bounds.size.height, 100)
        XCTAssertTrue((layer?.sublayers?.count ?? 0) > 0)
    }

    func testRenderSimpleCircle() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <circle cx="50" cy="50" r="40" fill="red" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
        XCTAssertTrue((layer?.sublayers?.count ?? 0) > 0)
    }

    func testRenderWithStroke() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="none" stroke="black" stroke-width="2" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderGroup() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <g fill="blue">
            <rect x="10" y="10" width="50" height="50" />
            <circle cx="120" cy="35" r="25" />
          </g>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
        XCTAssertTrue((layer?.sublayers?.count ?? 0) > 0)
    }

    func testRenderWithTransform() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="30" height="30" fill="green" transform="translate(20, 20)" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderWithOpacity() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" opacity="0.5" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderEllipse() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <ellipse cx="50" cy="50" rx="40" ry="25" fill="purple" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderLine() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <line x1="10" y1="10" x2="90" y2="90" stroke="black" stroke-width="2" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderPolygon() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <polygon points="50,10 90,90 10,90" fill="orange" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderPolyline() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <polyline points="10,10 50,50 90,10" fill="none" stroke="red" stroke-width="2" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderHexColor() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="#FF5733" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderRGBColor() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="rgb(100, 150, 200)" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let renderer = SVGRenderer()
        let layer = await renderer.render(document: result.document!)

        XCTAssertNotNil(layer)
    }

    func testRenderOptions() {
        let options = RenderOptions(
            scale: 2.0,
            backgroundColor: nil,
            antialiasing: true,
            fitToViewport: false
        )

        XCTAssertEqual(options.scale, 2.0)
        XCTAssertNil(options.backgroundColor)
        XCTAssertTrue(options.antialiasing)
        XCTAssertFalse(options.fitToViewport)
    }

    func testRenderContext() {
        var context = RenderContext(
            viewportSize: CGSize(width: 100, height: 100),
            options: RenderOptions()
        )

        XCTAssertEqual(context.viewportSize.width, 100)
        XCTAssertEqual(context.viewportSize.height, 100)

        // Test transform stack
        context.pushTransform(CGAffineTransform(translationX: 10, y: 10))
        XCTAssertNotEqual(context.currentTransform, .identity)

        context.popTransform()
        XCTAssertEqual(context.currentTransform, .identity)

        // Test opacity stack
        context.pushOpacity(0.5)
        XCTAssertEqual(context.currentOpacity, 0.5)

        context.pushOpacity(0.8)
        XCTAssertEqual(context.currentOpacity, 0.4) // 0.5 * 0.8

        context.popOpacity()
        XCTAssertEqual(context.currentOpacity, 0.5)

        context.popOpacity()
        XCTAssertEqual(context.currentOpacity, 1.0)
    }
}
