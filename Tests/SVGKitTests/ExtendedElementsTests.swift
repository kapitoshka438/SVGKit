import XCTest
@testable import SVGKitCore
@testable import SVGKitParser
@testable import SVGKitDOM

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class ExtendedElementsTests: XCTestCase {

    // MARK: - Shape Elements Tests

    func testParseEllipse() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <ellipse cx="50" cy="60" rx="40" ry="30" fill="blue" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.document)

        let ellipse = result.document?.rootElement?.childNodes.first as? SVGEllipseElement
        XCTAssertNotNil(ellipse)
        XCTAssertEqual(ellipse?.cx?.valueInSpecifiedUnits, 50.0)
        XCTAssertEqual(ellipse?.cy?.valueInSpecifiedUnits, 60.0)
        XCTAssertEqual(ellipse?.rx?.valueInSpecifiedUnits, 40.0)
        XCTAssertEqual(ellipse?.ry?.valueInSpecifiedUnits, 30.0)
    }

    func testParseLine() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <line x1="10" y1="20" x2="100" y2="80" stroke="black" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let line = result.document?.rootElement?.childNodes.first as? SVGLineElement
        XCTAssertNotNil(line)
        XCTAssertEqual(line?.x1?.valueInSpecifiedUnits, 10.0)
        XCTAssertEqual(line?.y1?.valueInSpecifiedUnits, 20.0)
        XCTAssertEqual(line?.x2?.valueInSpecifiedUnits, 100.0)
        XCTAssertEqual(line?.y2?.valueInSpecifiedUnits, 80.0)
    }

    func testParsePolygon() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <polygon points="0,0 100,0 100,100 0,100" fill="green" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let polygon = result.document?.rootElement?.childNodes.first as? SVGPolygonElement
        XCTAssertNotNil(polygon)
        XCTAssertEqual(polygon?.points, "0,0 100,0 100,100 0,100")
    }

    func testParsePolyline() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <polyline points="0,0 50,50 100,0" stroke="red" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let polyline = result.document?.rootElement?.childNodes.first as? SVGPolylineElement
        XCTAssertNotNil(polyline)
        XCTAssertEqual(polyline?.points, "0,0 50,50 100,0")
    }

    // MARK: - Text Elements Tests

    func testParseText() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <text x="10" y="20" fill="black">Hello World</text>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let text = result.document?.rootElement?.childNodes.first as? SVGTextElement
        XCTAssertNotNil(text)
        XCTAssertEqual(text?.x?.valueInSpecifiedUnits, 10.0)
        XCTAssertEqual(text?.y?.valueInSpecifiedUnits, 20.0)
    }

    func testParseTSpan() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <text x="10" y="20">
            <tspan x="10" y="30">First line</tspan>
            <tspan x="10" y="50">Second line</tspan>
          </text>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let text = result.document?.rootElement?.childNodes.first as? SVGTextElement
        XCTAssertNotNil(text)
        XCTAssertEqual(text?.childNodes.count, 2)

        let tspan1 = text?.childNodes[0] as? SVGTSpanElement
        XCTAssertNotNil(tspan1)
        XCTAssertEqual(tspan1?.x?.valueInSpecifiedUnits, 10.0)
        XCTAssertEqual(tspan1?.y?.valueInSpecifiedUnits, 30.0)
    }

    // MARK: - Gradient Tests

    func testParseLinearGradient() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stop-color="rgb(255,255,0)" />
              <stop offset="100%" stop-color="rgb(255,0,0)" />
            </linearGradient>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        XCTAssertNotNil(defs)

        let gradient = defs?.childNodes.first as? SVGLinearGradientElement
        XCTAssertNotNil(gradient)
        XCTAssertEqual(gradient?.identifier, "grad1")
        XCTAssertEqual(gradient?.childNodes.count, 2)

        let stop1 = gradient?.childNodes[0] as? SVGStopElement
        XCTAssertNotNil(stop1)
        XCTAssertEqual(stop1?.getAttribute("offset"), "0%")
        XCTAssertEqual(stop1?.stopColor, "rgb(255,255,0)")
    }

    func testParseRadialGradient() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <radialGradient id="grad2" cx="50%" cy="50%" r="50%">
              <stop offset="0%" stop-color="white" />
              <stop offset="100%" stop-color="blue" />
            </radialGradient>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let gradient = defs?.childNodes.first as? SVGRadialGradientElement
        XCTAssertNotNil(gradient)
        XCTAssertEqual(gradient?.identifier, "grad2")
    }

    // MARK: - Pattern Tests

    func testParsePattern() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <pattern id="pattern1" x="0" y="0" width="20" height="20" patternUnits="userSpaceOnUse">
              <circle cx="10" cy="10" r="5" fill="red" />
            </pattern>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let pattern = defs?.childNodes.first as? SVGPatternElement
        XCTAssertNotNil(pattern)
        XCTAssertEqual(pattern?.identifier, "pattern1")
        XCTAssertEqual(pattern?.width?.valueInSpecifiedUnits, 20.0)
        XCTAssertEqual(pattern?.height?.valueInSpecifiedUnits, 20.0)
    }

    // MARK: - Clipping and Masking Tests

    func testParseClipPath() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <clipPath id="clip1">
              <circle cx="50" cy="50" r="40" />
            </clipPath>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let clipPath = defs?.childNodes.first as? SVGClipPathElement
        XCTAssertNotNil(clipPath)
        XCTAssertEqual(clipPath?.identifier, "clip1")
    }

    func testParseMask() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <mask id="mask1" x="0" y="0" width="100" height="100">
              <rect x="0" y="0" width="100" height="100" fill="white" />
            </mask>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let mask = defs?.childNodes.first as? SVGMaskElement
        XCTAssertNotNil(mask)
        XCTAssertEqual(mask?.identifier, "mask1")
    }

    // MARK: - Structural Elements Tests

    func testParseSymbol() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <symbol id="icon" viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="40" />
            </symbol>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let symbol = defs?.childNodes.first as? SVGSymbolElement
        XCTAssertNotNil(symbol)
        XCTAssertEqual(symbol?.identifier, "icon")
        XCTAssertEqual(symbol?.viewBox, "0 0 100 100")
    }

    func testParseUse() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <use href="#icon" x="10" y="20" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let use = result.document?.rootElement?.childNodes.first as? SVGUseElement
        XCTAssertNotNil(use)
        XCTAssertEqual(use?.href, "#icon")
        XCTAssertEqual(use?.x?.valueInSpecifiedUnits, 10.0)
        XCTAssertEqual(use?.y?.valueInSpecifiedUnits, 20.0)
    }

    func testParseImage() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <image href="image.png" x="0" y="0" width="100" height="100" />
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let image = result.document?.rootElement?.childNodes.first as? SVGImageElement
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.href, "image.png")
        XCTAssertEqual(image?.width?.valueInSpecifiedUnits, 100.0)
    }

    func testParseMarker() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <marker id="arrow" markerWidth="10" markerHeight="10" refX="5" refY="5">
              <path d="M 0 0 L 10 5 L 0 10 z" />
            </marker>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let marker = defs?.childNodes.first as? SVGMarkerElement
        XCTAssertNotNil(marker)
        XCTAssertEqual(marker?.identifier, "arrow")
        XCTAssertEqual(marker?.markerWidth?.valueInSpecifiedUnits, 10.0)
    }

    // MARK: - Filter Tests

    func testParseFilter() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <filter id="blur">
              <feGaussianBlur in="SourceGraphic" stdDeviation="5" />
            </filter>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let filter = defs?.childNodes.first as? SVGFilterElement
        XCTAssertNotNil(filter)
        XCTAssertEqual(filter?.identifier, "blur")

        let blur = filter?.childNodes.first as? SVGFEGaussianBlurElement
        XCTAssertNotNil(blur)
        XCTAssertEqual(blur?.stdDeviation, "5")
    }

    func testParseComplexFilter() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <defs>
            <filter id="shadow">
              <feGaussianBlur in="SourceAlpha" stdDeviation="3" />
              <feOffset dx="2" dy="2" result="offsetblur" />
              <feBlend in="SourceGraphic" in2="offsetblur" mode="normal" />
            </filter>
          </defs>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let defs = result.document?.rootElement?.childNodes.first as? SVGDefsElement
        let filter = defs?.childNodes.first as? SVGFilterElement
        XCTAssertNotNil(filter)
        XCTAssertEqual(filter?.childNodes.count, 3)

        let blur = filter?.childNodes[0] as? SVGFEGaussianBlurElement
        let offset = filter?.childNodes[1] as? SVGFEOffsetElement
        let blend = filter?.childNodes[2] as? SVGFEBlendElement

        XCTAssertNotNil(blur)
        XCTAssertNotNil(offset)
        XCTAssertNotNil(blend)
    }

    // MARK: - Style Element Test

    func testParseStyle() async throws {
        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <style type="text/css">
            .red { fill: red; }
          </style>
        </svg>
        """

        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let style = result.document?.rootElement?.childNodes.first as? SVGStyleElement
        XCTAssertNotNil(style)
        XCTAssertEqual(style?.type, "text/css")
    }
}
