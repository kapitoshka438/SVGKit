import XCTest
@testable import SVGKitCore
@testable import SVGKitSwift
@testable import SVGKitRendering

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGImageExportTests: XCTestCase {

    func testExportPNGData() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="blue" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let pngData = await image.exportPNG(scale: 1.0)

        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData?.count ?? 0, 0)

        // Verify PNG signature
        if let data = pngData {
            let bytes = [UInt8](data.prefix(8))
            XCTAssertEqual(bytes[0], 0x89) // PNG signature
            XCTAssertEqual(bytes[1], 0x50) // P
            XCTAssertEqual(bytes[2], 0x4E) // N
            XCTAssertEqual(bytes[3], 0x47) // G
        }
    }

    func testExportPNGFile() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <circle cx="50" cy="50" r="40" fill="red" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_export.png")

        try await image.exportPNG(to: tempURL, scale: 2.0)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        let data = try Data(contentsOf: tempURL)
        XCTAssertGreaterThan(data.count, 0)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testExportPNGWithCustomSize() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">
          <rect x="5" y="5" width="40" height="40" fill="green" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let customSize = CGSize(width: 200, height: 200)
        let pngData = await image.exportPNG(size: customSize, scale: 1.0)

        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData?.count ?? 0, 0)
    }

    func testExportJPEGData() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="orange" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let jpegData = await image.exportJPEG(compressionQuality: 0.8)

        XCTAssertNotNil(jpegData)
        XCTAssertGreaterThan(jpegData?.count ?? 0, 0)

        // Verify JPEG signature
        if let data = jpegData {
            let bytes = [UInt8](data.prefix(3))
            XCTAssertEqual(bytes[0], 0xFF) // JPEG SOI marker
            XCTAssertEqual(bytes[1], 0xD8)
            XCTAssertEqual(bytes[2], 0xFF)
        }
    }

    func testExportJPEGFile() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <circle cx="50" cy="50" r="40" fill="purple" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_export.jpg")

        try await image.exportJPEG(to: tempURL, compressionQuality: 0.9)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        let data = try Data(contentsOf: tempURL)
        XCTAssertGreaterThan(data.count, 0)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testExportJPEGWithCustomBackground() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <circle cx="50" cy="50" r="40" fill="blue" fill-opacity="0.5" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let backgroundColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let jpegData = await image.exportJPEG(backgroundColor: backgroundColor)

        XCTAssertNotNil(jpegData)
        XCTAssertGreaterThan(jpegData?.count ?? 0, 0)
    }

    func testExportPDFData() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <rect x="10" y="10" width="80" height="80" fill="teal" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let pdfData = await image.exportPDF()

        XCTAssertNotNil(pdfData)
        XCTAssertGreaterThan(pdfData?.count ?? 0, 0)

        // Verify PDF signature
        if let data = pdfData {
            let bytes = [UInt8](data.prefix(5))
            XCTAssertEqual(bytes[0], 0x25) // %
            XCTAssertEqual(bytes[1], 0x50) // P
            XCTAssertEqual(bytes[2], 0x44) // D
            XCTAssertEqual(bytes[3], 0x46) // F
            XCTAssertEqual(bytes[4], 0x2D) // -
        }
    }

    func testExportPDFFile() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="150" height="150">
          <circle cx="75" cy="75" r="60" fill="maroon" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_export.pdf")

        try await image.exportPDF(to: tempURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

        let data = try Data(contentsOf: tempURL)
        XCTAssertGreaterThan(data.count, 0)

        // Clean up
        try? FileManager.default.removeItem(at: tempURL)
    }

    func testExportPDFWithCustomSize() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
          <rect x="10" y="10" width="80" height="80" fill="navy" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)
        let customSize = CGSize(width: 500, height: 500)
        let pdfData = await image.exportPDF(size: customSize)

        XCTAssertNotNil(pdfData)
        XCTAssertGreaterThan(pdfData?.count ?? 0, 0)
    }

    func testExportMultipleFormats() async throws {
        let svgString = """
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="80" height="80">
          <rect x="5" y="5" width="70" height="70" fill="olive" />
        </svg>
        """

        let image = try await SVGImage(string: svgString, baseURL: nil)

        // Export to all formats
        let pngData = await image.exportPNG()
        let jpegData = await image.exportJPEG()
        let pdfData = await image.exportPDF()

        XCTAssertNotNil(pngData)
        XCTAssertNotNil(jpegData)
        XCTAssertNotNil(pdfData)

        XCTAssertGreaterThan(pngData?.count ?? 0, 0)
        XCTAssertGreaterThan(jpegData?.count ?? 0, 0)
        XCTAssertGreaterThan(pdfData?.count ?? 0, 0)
    }
}
