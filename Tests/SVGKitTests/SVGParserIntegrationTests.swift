import XCTest
@testable import SVGKitCore
@testable import SVGKitParser
@testable import SVGKitDOM

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGParserIntegrationTests: XCTestCase {

    func testParseSimpleRect() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess, "Parse should succeed")
        XCTAssertNotNil(result.document)
        XCTAssertNotNil(result.document?.rootElement)
        XCTAssertEqual(result.document?.rootElement?.tagName, "svg")

        // Check rect element
        let rects = result.document?.getElementsByTagName("rect")
        XCTAssertEqual(rects?.count, 1)
        XCTAssertEqual(rects?.first?.getAttribute("fill"), "blue")
    }

    func testParseSimpleCircle() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <circle cx="50" cy="50" r="40" fill="red" stroke="black" stroke-width="2" />
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.document?.rootElement)

        let circles = result.document?.getElementsByTagName("circle")
        XCTAssertEqual(circles?.count, 1)

        if let circle = circles?.first as? SVGCircleElement {
            XCTAssertEqual(circle.getAttribute("cx"), "50")
            XCTAssertEqual(circle.getAttribute("cy"), "50")
            XCTAssertEqual(circle.getAttribute("r"), "40")
            XCTAssertEqual(circle.getAttribute("fill"), "red")
        } else {
            XCTFail("Circle should be SVGCircleElement")
        }
    }

    func testParsePath() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <path d="M 10,30 L 90,30 L 50,80 Z" fill="green" />
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let paths = result.document?.getElementsByTagName("path")
        XCTAssertEqual(paths?.count, 1)

        if let path = paths?.first as? SVGPathElement {
            XCTAssertEqual(path.d, "M 10,30 L 90,30 L 50,80 Z")
            XCTAssertEqual(path.getAttribute("fill"), "green")
        } else {
            XCTFail("Path should be SVGPathElement")
        }
    }

    func testParseGroupWithMultipleElements() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
          <g id="myGroup" fill="blue">
            <rect x="10" y="10" width="50" height="50" />
            <circle cx="100" cy="100" r="30" />
          </g>
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        // Find group
        let group = result.document?.getElementById("myGroup")
        XCTAssertNotNil(group)
        XCTAssertEqual(group?.tagName, "g")
        XCTAssertEqual(group?.getAttribute("fill"), "blue")

        // Check children
        XCTAssertEqual(group?.childNodes.count, 2)
    }

    func testParseSVGAttributes() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="300" height="200" viewBox="0 0 300 200">
          <rect x="0" y="0" width="100%" height="100%" fill="white" />
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let svg = result.document?.rootElement as? SVGSVGElement
        XCTAssertNotNil(svg)
        XCTAssertEqual(svg?.getAttribute("width"), "300")
        XCTAssertEqual(svg?.getAttribute("height"), "200")
        XCTAssertEqual(svg?.viewBox, "0 0 300 200")
    }

    func testParseElementWithID() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <rect id="myRect" x="10" y="10" width="50" height="50" />
          <circle id="myCircle" cx="100" cy="100" r="30" />
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        // Test getElementById
        let rect = result.document?.getElementById("myRect")
        XCTAssertNotNil(rect)
        XCTAssertEqual(rect?.tagName, "rect")

        let circle = result.document?.getElementById("myCircle")
        XCTAssertNotNil(circle)
        XCTAssertEqual(circle?.tagName, "circle")
    }

    func testParseFromFile() async throws {
        // Use test file
        let testSVGPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/TestSVGs/simple-rect.svg")

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.file(testSVGPath)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.document?.rootElement)

        let svg = result.document?.rootElement as? SVGSVGElement
        XCTAssertNotNil(svg)
    }

    func testParseInvalidXML() async throws {
        let invalidSVG = """
        <svg xmlns="http://www.w3.org/2000/svg">
          <rect x="10" y="10" width="50" height="50"
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(invalidSVG, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertFalse(result.isSuccess)
        XCTAssertFalse(result.errors.isEmpty)
    }

    func testParseEmptySVG() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.document?.rootElement)
        XCTAssertEqual(result.document?.rootElement?.childNodes.count, 0)
    }

    func testParseNestedGroups() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <g id="outer">
            <g id="inner">
              <rect id="deepRect" x="0" y="0" width="10" height="10" />
            </g>
          </g>
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let rect = result.document?.getElementById("deepRect")
        XCTAssertNotNil(rect)

        // Check parent chain
        XCTAssertNotNil(rect?.parentNode)
        XCTAssertEqual((rect?.parentNode as? Element)?.getAttribute("id"), "inner")
    }

    func testParseSVGLengthAttributes() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg">
          <rect x="10px" y="20%" width="50em" height="100" />
        </svg>
        """

        let parser = SVGParser(extensions: [SVGElementParserExtension()])
        let source = SVGSource.string(svgString, baseURL: nil)
        let result = try await parser.parse(from: source)

        XCTAssertTrue(result.isSuccess)

        let rects = result.document?.getElementsByTagName("rect")
        XCTAssertEqual(rects?.count, 1)

        if let rect = rects?.first as? SVGRectElement {
            XCTAssertNotNil(rect.x)
            XCTAssertEqual(rect.x?.unitType, .px)
            XCTAssertEqual(rect.x?.valueInSpecifiedUnits, 10)

            XCTAssertNotNil(rect.y)
            XCTAssertEqual(rect.y?.unitType, .percentage)
            XCTAssertEqual(rect.y?.valueInSpecifiedUnits, 20)

            XCTAssertNotNil(rect.width)
            XCTAssertEqual(rect.width?.unitType, .ems)
            XCTAssertEqual(rect.width?.valueInSpecifiedUnits, 50)
        } else {
            XCTFail("Should be SVGRectElement")
        }
    }
}
