import XCTest
@testable import SVGKitCore
@testable import SVGKitParser
@testable import SVGKitDOM

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGParserTests: XCTestCase {

    func testParserInitialization() {
        let parser = SVGParser()
        XCTAssertNotNil(parser)
    }

    func testParserWithExtensions() {
        let extension1 = SVGElementParserExtension()
        let parser = SVGParser(extensions: [extension1])
        XCTAssertNotNil(parser)
    }

    func testParsePlaceholder() async throws {
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
    }

    func testParserContext() {
        let source = SVGSource.string("<svg></svg>", baseURL: nil)
        let context = ParserContext(source: source, parentNode: nil)

        XCTAssertNotNil(context.source)
        XCTAssertNil(context.parentNode)
        XCTAssertEqual(context.characterData, "")
    }

    func testParserContextWithCharacterData() {
        let source = SVGSource.string("<svg></svg>", baseURL: nil)
        let context = ParserContext(source: source, parentNode: nil)

        let newContext = context.withCharacterData("test")
        XCTAssertEqual(newContext.characterData, "test")

        let clearedContext = newContext.clearingCharacterData()
        XCTAssertEqual(clearedContext.characterData, "")
    }

    func testAddExtension() async {
        let parser = SVGParser()
        let extension1 = SVGElementParserExtension()

        await parser.addExtension(extension1)

        XCTAssertTrue(true)
    }

    func testParseResult() {
        let document = SVGDocument()
        let result = ParseResult(document: document, errors: [], warnings: [])

        XCTAssertTrue(result.isSuccess)
        XCTAssertNotNil(result.document)
        XCTAssertEqual(result.errors.count, 0)
        XCTAssertEqual(result.warnings.count, 0)
    }

    func testParseResultWithErrors() {
        let error = SVGError.parsingFailed("Test error")
        let result = ParseResult(document: nil, errors: [error], warnings: [])

        XCTAssertFalse(result.isSuccess)
        XCTAssertNil(result.document)
        XCTAssertEqual(result.errors.count, 1)
    }

    func testSVGElementParserExtension() {
        let ext = SVGElementParserExtension()

        XCTAssertTrue(ext.supportedNamespaces.contains("http://www.w3.org/2000/svg"))
        XCTAssertTrue(ext.supportedElements.contains("svg"))
        XCTAssertTrue(ext.supportedElements.contains("rect"))
        XCTAssertTrue(ext.supportedElements.contains("circle"))
        XCTAssertTrue(ext.supportedElements.contains("path"))
    }
}
