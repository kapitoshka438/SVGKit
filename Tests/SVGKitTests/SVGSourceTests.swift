import XCTest
@testable import SVGKitCore

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGSourceTests: XCTestCase {

    // MARK: - Enum Cases

    func testFileSource() {
        let url = URL(fileURLWithPath: "/tmp/test.svg")
        let source = SVGSource.file(url)

        switch source {
        case .file(let fileURL):
            XCTAssertEqual(fileURL, url)
        default:
            XCTFail("Expected file source")
        }
    }

    func testURLSource() {
        let url = URL(string: "https://example.com/test.svg")!
        let source = SVGSource.url(url)

        switch source {
        case .url(let remoteURL):
            XCTAssertEqual(remoteURL, url)
        default:
            XCTFail("Expected URL source")
        }
    }

    func testDataSource() {
        let data = Data("test".utf8)
        let baseURL = URL(string: "https://example.com/")
        let source = SVGSource.data(data, baseURL: baseURL)

        switch source {
        case .data(let sourceData, let sourceBaseURL):
            XCTAssertEqual(sourceData, data)
            XCTAssertEqual(sourceBaseURL, baseURL)
        default:
            XCTFail("Expected data source")
        }
    }

    func testStringSource() {
        let string = "<svg></svg>"
        let baseURL = URL(string: "https://example.com/")
        let source = SVGSource.string(string, baseURL: baseURL)

        switch source {
        case .string(let sourceString, let sourceBaseURL):
            XCTAssertEqual(sourceString, string)
            XCTAssertEqual(sourceBaseURL, baseURL)
        default:
            XCTFail("Expected string source")
        }
    }

    // MARK: - Base URL

    func testBaseURLForFile() {
        let url = URL(fileURLWithPath: "/path/to/file.svg")
        let source = SVGSource.file(url)

        XCTAssertEqual(source.baseURL?.path, "/path/to")
    }

    func testBaseURLForURL() {
        let url = URL(string: "https://example.com/images/test.svg")!
        let source = SVGSource.url(url)

        // deletingLastPathComponent adds trailing slash for directory URLs
        XCTAssertTrue(source.baseURL?.absoluteString.hasPrefix("https://example.com/images") ?? false)
    }

    func testBaseURLForDataWithURL() {
        let data = Data()
        let baseURL = URL(string: "https://example.com/")
        let source = SVGSource.data(data, baseURL: baseURL)

        XCTAssertEqual(source.baseURL, baseURL)
    }

    func testBaseURLForDataWithoutURL() {
        let data = Data()
        let source = SVGSource.data(data, baseURL: nil)

        XCTAssertNil(source.baseURL)
    }

    func testBaseURLForStringWithURL() {
        let string = "<svg></svg>"
        let baseURL = URL(string: "https://example.com/")
        let source = SVGSource.string(string, baseURL: baseURL)

        XCTAssertEqual(source.baseURL, baseURL)
    }

    func testBaseURLForStringWithoutURL() {
        let string = "<svg></svg>"
        let source = SVGSource.string(string, baseURL: nil)

        XCTAssertNil(source.baseURL)
    }

    // MARK: - Cache Key

    func testCacheKeyUniqueness() {
        let url1 = URL(fileURLWithPath: "/tmp/test1.svg")
        let url2 = URL(fileURLWithPath: "/tmp/test2.svg")

        let source1 = SVGSource.file(url1)
        let source2 = SVGSource.file(url2)

        XCTAssertNotEqual(source1.cacheKey, source2.cacheKey)
    }

    func testCacheKeyConsistency() {
        let url = URL(fileURLWithPath: "/tmp/test.svg")
        let source1 = SVGSource.file(url)
        let source2 = SVGSource.file(url)

        XCTAssertEqual(source1.cacheKey, source2.cacheKey)
    }

    // MARK: - Approximate Length

    func testApproximateLengthForData() {
        let data = Data("test data".utf8)
        let source = SVGSource.data(data, baseURL: nil)

        XCTAssertEqual(source.approximateLengthInBytes, UInt64(data.count))
    }

    func testApproximateLengthForString() {
        let string = "test string"
        let source = SVGSource.string(string, baseURL: nil)

        XCTAssertEqual(source.approximateLengthInBytes, UInt64(string.utf8.count))
    }

    func testApproximateLengthForURL() {
        let url = URL(string: "https://example.com/test.svg")!
        let source = SVGSource.url(url)

        // URL sources don't know size until downloaded
        XCTAssertNil(source.approximateLengthInBytes)
    }

    // MARK: - Data Loading

    func testLoadDataFromString() throws {
        let svgString = "<svg></svg>"
        let source = SVGSource.string(svgString, baseURL: nil)

        let data = try source.loadData()
        let loadedString = String(data: data, encoding: .utf8)

        XCTAssertEqual(loadedString, svgString)
    }

    func testLoadDataFromData() throws {
        let testData = Data("test".utf8)
        let source = SVGSource.data(testData, baseURL: nil)

        let loadedData = try source.loadData()

        XCTAssertEqual(loadedData, testData)
    }

    func testLoadDataFromExistingFile() throws {
        // Use a test SVG file from resources
        let testSVGPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/TestSVGs/simple-rect.svg")

        let source = SVGSource.file(testSVGPath)
        let data = try source.loadData()

        XCTAssertGreaterThan(data.count, 0)
        XCTAssertTrue(String(data: data, encoding: .utf8)?.contains("<svg") ?? false)
    }

    func testLoadDataFromNonExistentFile() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID()).svg")
        let source = SVGSource.file(url)

        XCTAssertThrowsError(try source.loadData()) { error in
            guard case SVGError.cannotReadFile = error else {
                XCTFail("Expected cannotReadFile error")
                return
            }
        }
    }

    // MARK: - Async Loading

    func testLoadDataAsyncFromString() async throws {
        let svgString = "<svg></svg>"
        let source = SVGSource.string(svgString, baseURL: nil)

        let data = try await source.loadDataAsync()
        let loadedString = String(data: data, encoding: .utf8)

        XCTAssertEqual(loadedString, svgString)
    }

    func testLoadDataAsyncFromData() async throws {
        let testData = Data("test".utf8)
        let source = SVGSource.data(testData, baseURL: nil)

        let loadedData = try await source.loadDataAsync()

        XCTAssertEqual(loadedData, testData)
    }

    // MARK: - Input Stream

    func testCreateInputStream() throws {
        let svgString = "<svg></svg>"
        let source = SVGSource.string(svgString, baseURL: nil)

        let stream = try source.createInputStream()

        XCTAssertNotNil(stream)
        stream.open()
        defer { stream.close() }

        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = stream.read(&buffer, maxLength: buffer.count)

        XCTAssertGreaterThan(bytesRead, 0)
    }

    // MARK: - Convenience Initializers

    func testNamedResourceInitializer() throws {
        // This will fail if no such resource exists, but tests the API
        XCTAssertThrowsError(try SVGSource.named("nonexistent-resource")) { error in
            guard case SVGError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error")
                return
            }
        }
    }

    func testURLStringInitializer() throws {
        let source = try SVGSource.url(string: "https://example.com/test.svg")

        switch source {
        case .url(let url):
            XCTAssertEqual(url.absoluteString, "https://example.com/test.svg")
        default:
            XCTFail("Expected URL source")
        }
    }

    func testInvalidURLStringInitializer() {
        // URL(string:) is very permissive, but empty string should fail
        XCTAssertThrowsError(try SVGSource.url(string: "")) { error in
            guard case SVGError.invalidURL = error else {
                XCTFail("Expected invalidURL error, got \(error)")
                return
            }
        }
    }

    // MARK: - Relative Path Resolution

    func testRelativePathResolutionForFile() throws {
        let baseURL = URL(fileURLWithPath: "/path/to/file.svg")
        let source = SVGSource.file(baseURL)

        let relativeSource = try source.sourceFromRelativePath("other.svg")

        switch relativeSource {
        case .file(let url):
            XCTAssertEqual(url.path, "/path/to/other.svg")
        default:
            XCTFail("Expected file source")
        }
    }

    func testRelativePathResolutionForURL() throws {
        let baseURL = URL(string: "https://example.com/images/test.svg")!
        let source = SVGSource.url(baseURL)

        let relativeSource = try source.sourceFromRelativePath("other.svg")

        switch relativeSource {
        case .url(let url):
            XCTAssertEqual(url.absoluteString, "https://example.com/images/other.svg")
        default:
            XCTFail("Expected URL source")
        }
    }

    func testRelativePathResolutionFailsWithoutBaseURL() {
        let source = SVGSource.data(Data(), baseURL: nil)

        XCTAssertThrowsError(try source.sourceFromRelativePath("other.svg")) { error in
            guard case SVGError.invalidSource = error else {
                XCTFail("Expected invalidSource error")
                return
            }
        }
    }

    // MARK: - Hashable & Equatable

    func testHashable() {
        let url = URL(fileURLWithPath: "/tmp/test.svg")
        let source1 = SVGSource.file(url)
        let source2 = SVGSource.file(url)
        let source3 = SVGSource.file(URL(fileURLWithPath: "/tmp/other.svg"))

        var set = Set<SVGSource>()
        set.insert(source1)
        set.insert(source2)
        set.insert(source3)

        XCTAssertEqual(set.count, 2) // source1 and source2 are equal
    }

    func testEquatable() {
        let url = URL(fileURLWithPath: "/tmp/test.svg")
        let source1 = SVGSource.file(url)
        let source2 = SVGSource.file(url)
        let source3 = SVGSource.file(URL(fileURLWithPath: "/tmp/other.svg"))

        XCTAssertEqual(source1, source2)
        XCTAssertNotEqual(source1, source3)
    }
}
