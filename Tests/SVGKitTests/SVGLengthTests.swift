import XCTest
@testable import SVGKitCore

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class SVGLengthTests: XCTestCase {

    func testInitWithValueAndUnit() {
        let length = SVGLength(value: 10, unit: .px)
        XCTAssertEqual(length.valueInSpecifiedUnits, 10)
        XCTAssertEqual(length.unitType, .px)
    }

    func testZeroLength() {
        let zero = SVGLength.zero
        XCTAssertEqual(zero.valueInSpecifiedUnits, 0)
        XCTAssertEqual(zero.unitType, .number)
    }

    func testInitFromStringWithPixels() {
        let length = SVGLength(string: "100px")
        XCTAssertNotNil(length)
        XCTAssertEqual(length?.valueInSpecifiedUnits, 100)
        XCTAssertEqual(length?.unitType, .px)
    }

    func testInitFromStringWithPercentage() {
        let length = SVGLength(string: "50%")
        XCTAssertNotNil(length)
        XCTAssertEqual(length?.valueInSpecifiedUnits, 50)
        XCTAssertEqual(length?.unitType, .percentage)
    }

    func testInitFromStringWithEm() {
        let length = SVGLength(string: "2em")
        XCTAssertNotNil(length)
        XCTAssertEqual(length?.valueInSpecifiedUnits, 2)
        XCTAssertEqual(length?.unitType, .ems)
    }

    func testInitFromStringWithNumber() {
        let length = SVGLength(string: "42")
        XCTAssertNotNil(length)
        XCTAssertEqual(length?.valueInSpecifiedUnits, 42)
        XCTAssertEqual(length?.unitType, .number)
    }

    func testInitFromStringWithWhitespace() {
        let length = SVGLength(string: "  25px  ")
        XCTAssertNotNil(length)
        XCTAssertEqual(length?.valueInSpecifiedUnits, 25)
        XCTAssertEqual(length?.unitType, .px)
    }

    func testInitFromInvalidString() {
        let length = SVGLength(string: "invalid")
        XCTAssertNil(length)
    }

    func testValueAsString() {
        XCTAssertEqual(SVGLength(value: 10, unit: .px).valueAsString, "10.0px")
        XCTAssertEqual(SVGLength(value: 50, unit: .percentage).valueAsString, "50.0%")
        XCTAssertEqual(SVGLength(value: 2, unit: .ems).valueAsString, "2.0em")
        XCTAssertEqual(SVGLength(value: 42, unit: .number).valueAsString, "42.0")
    }

    func testPixelsValueWithDefaultContext() {
        let context = SVGRenderContext()
        let length = SVGLength(value: 10, unit: .px)
        XCTAssertEqual(length.pixelsValue(in: context), 10, accuracy: 0.01)
    }

    func testPixelsValueWithEm() {
        let context = SVGRenderContext(fontSize: 16.0)
        let length = SVGLength(value: 2, unit: .ems)
        XCTAssertEqual(length.pixelsValue(in: context), 32, accuracy: 0.01)
    }

    func testPixelsValueWithInches() {
        let context = SVGRenderContext(pixelsPerInch: 96.0)
        let length = SVGLength(value: 1, unit: .in)
        XCTAssertEqual(length.pixelsValue(in: context), 96, accuracy: 0.01)
    }

    func testPixelsValueWithCentimeters() {
        let context = SVGRenderContext(pixelsPerInch: 96.0)
        let length = SVGLength(value: 2.54, unit: .cm)
        XCTAssertEqual(length.pixelsValue(in: context), 96, accuracy: 0.1)
    }

    func testPixelsValueWithPercentageAndDimension() {
        let context = SVGRenderContext()
        let length = SVGLength(value: 50, unit: .percentage)
        XCTAssertEqual(length.pixelsValue(withDimension: 200, in: context), 100, accuracy: 0.01)
    }

    func testEquality() {
        let length1 = SVGLength(value: 10, unit: .px)
        let length2 = SVGLength(value: 10, unit: .px)
        let length3 = SVGLength(value: 20, unit: .px)
        let length4 = SVGLength(value: 10, unit: .ems)

        XCTAssertEqual(length1, length2)
        XCTAssertNotEqual(length1, length3)
        XCTAssertNotEqual(length1, length4)
    }

    func testHashable() {
        let length1 = SVGLength(value: 10, unit: .px)
        let length2 = SVGLength(value: 10, unit: .px)
        let length3 = SVGLength(value: 20, unit: .px)

        var set = Set<SVGLength>()
        set.insert(length1)
        set.insert(length2)
        set.insert(length3)

        XCTAssertEqual(set.count, 2)  // length1 and length2 are equal
    }

    func testCodable() throws {
        let length = SVGLength(value: 42.5, unit: .px)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(length)
        let decoded = try decoder.decode(SVGLength.self, from: data)

        XCTAssertEqual(decoded.valueInSpecifiedUnits, length.valueInSpecifiedUnits)
        XCTAssertEqual(decoded.unitType, length.unitType)
    }
}
