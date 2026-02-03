import XCTest
@testable import SVGKitDOM
@testable import SVGKitCore

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class ElementTests: XCTestCase {

    func testElementCreation() {
        let element = Element(name: "rect")

        XCTAssertEqual(element.tagName, "rect")
        XCTAssertEqual(element.localName, "rect")
        XCTAssertNil(element.prefix)
        XCTAssertNil(element.namespaceURI)
    }

    func testElementWithNamespace() {
        let element = Element(name: "svg", namespaceURI: "http://www.w3.org/2000/svg")

        XCTAssertEqual(element.namespaceURI, "http://www.w3.org/2000/svg")
        XCTAssertEqual(element.localName, "svg")
    }

    func testElementWithPrefix() {
        let element = Element(name: "xlink:href", prefix: "xlink")

        XCTAssertEqual(element.prefix, "xlink")
        XCTAssertEqual(element.localName, "href")
    }

    func testSetGetAttribute() {
        let element = Element(name: "rect")

        element.setAttribute("width", value: "100")
        XCTAssertEqual(element.getAttribute("width"), "100")
    }

    func testRemoveAttribute() {
        let element = Element(name: "rect")

        element.setAttribute("width", value: "100")
        XCTAssertTrue(element.hasAttribute("width"))

        element.removeAttribute("width")
        XCTAssertFalse(element.hasAttribute("width"))
        XCTAssertNil(element.getAttribute("width"))
    }

    func testGetAllAttributes() {
        let element = Element(name: "rect")

        element.setAttribute("x", value: "10")
        element.setAttribute("y", value: "20")
        element.setAttribute("width", value: "100")

        let attrs = element.getAllAttributes()
        XCTAssertEqual(attrs.count, 3)
        XCTAssertEqual(attrs["x"], "10")
        XCTAssertEqual(attrs["y"], "20")
        XCTAssertEqual(attrs["width"], "100")
    }

    func testGetElementsByTagName() {
        let svg = Element(name: "svg")
        let rect1 = Element(name: "rect")
        let rect2 = Element(name: "rect")
        let circle = Element(name: "circle")

        svg.appendChild(rect1)
        svg.appendChild(circle)
        circle.appendChild(rect2)

        let rects = svg.getElementsByTagName("rect")
        XCTAssertEqual(rects.count, 2)
    }

    func testGetElementById() {
        let svg = Element(name: "svg")
        let rect = Element(name: "rect")
        rect.setAttribute("id", value: "myRect")

        svg.appendChild(rect)

        let found = svg.getElementById("myRect")
        XCTAssertNotNil(found)
        XCTAssertTrue(found === rect)
    }

    func testSVGElementID() {
        let element = SVGElement(name: "rect")

        element.identifier = "testID"
        XCTAssertEqual(element.identifier, "testID")
        XCTAssertEqual(element.getAttribute("id"), "testID")
    }

    func testSVGElementClass() {
        let element = SVGElement(name: "rect")

        element.className = "my-class"
        XCTAssertEqual(element.className, "my-class")
        XCTAssertEqual(element.getAttribute("class"), "my-class")
    }

    func testSVGElementStyle() {
        let element = SVGElement(name: "rect")

        element.style = "fill: red; stroke: blue;"
        XCTAssertEqual(element.style, "fill: red; stroke: blue;")
    }

    func testSVGRectElement() {
        let rect = SVGRectElement()

        XCTAssertEqual(rect.tagName, "rect")

        rect.setAttribute("x", value: "10px")
        rect.setAttribute("y", value: "20%")
        rect.setAttribute("width", value: "100")
        rect.setAttribute("height", value: "50")

        XCTAssertNotNil(rect.x)
        XCTAssertEqual(rect.x?.unitType, .px)
        XCTAssertEqual(rect.x?.valueInSpecifiedUnits, 10)

        XCTAssertNotNil(rect.y)
        XCTAssertEqual(rect.y?.unitType, .percentage)
        XCTAssertEqual(rect.y?.valueInSpecifiedUnits, 20)
    }

    func testSVGCircleElement() {
        let circle = SVGCircleElement()

        XCTAssertEqual(circle.tagName, "circle")

        circle.setAttribute("cx", value: "50")
        circle.setAttribute("cy", value: "60")
        circle.setAttribute("r", value: "40")

        XCTAssertNotNil(circle.cx)
        XCTAssertNotNil(circle.cy)
        XCTAssertNotNil(circle.r)
    }

    func testSVGPathElement() {
        let path = SVGPathElement()

        XCTAssertEqual(path.tagName, "path")

        path.setAttribute("d", value: "M 10,10 L 90,90")
        XCTAssertEqual(path.d, "M 10,10 L 90,90")
    }

    func testSVGGElement() {
        let group = SVGGElement()

        XCTAssertEqual(group.tagName, "g")
    }

    func testSVGSVGElement() {
        let svg = SVGSVGElement()

        XCTAssertEqual(svg.tagName, "svg")
        XCTAssertTrue(svg.ownerSVGElement === svg)

        svg.setAttribute("width", value: "100")
        svg.setAttribute("height", value: "200")
        svg.setAttribute("viewBox", value: "0 0 100 200")

        XCTAssertNotNil(svg.width)
        XCTAssertNotNil(svg.height)
        XCTAssertEqual(svg.viewBox, "0 0 100 200")
    }

    func testSVGDocument() {
        let doc = SVGDocument()

        XCTAssertEqual(doc.nodeType, .document)
        XCTAssertNil(doc.rootElement)

        let svg = SVGSVGElement()
        doc.appendChild(svg)

        XCTAssertNotNil(doc.rootElement)
        XCTAssertTrue(doc.rootElement === svg)
    }

    func testSVGDocumentCreateElement() {
        let doc = SVGDocument()

        let rect = doc.createSVGElement("rect")
        XCTAssertTrue(rect is SVGRectElement)

        let circle = doc.createSVGElement("circle")
        XCTAssertTrue(circle is SVGCircleElement)

        let path = doc.createSVGElement("path")
        XCTAssertTrue(path is SVGPathElement)
    }

    func testSVGDocumentGetElementById() {
        let doc = SVGDocument()
        let svg = SVGSVGElement()
        let rect = SVGRectElement()
        rect.identifier = "testRect"

        doc.appendChild(svg)
        svg.appendChild(rect)

        let found = doc.getElementById("testRect")
        XCTAssertNotNil(found)
        XCTAssertTrue(found === rect)
    }

    func testGetBoolAttribute() {
        let element = SVGElement(name: "rect")

        element.setAttribute("visible", value: "true")
        XCTAssertTrue(element.getBoolAttribute("visible"))

        element.setAttribute("visible", value: "false")
        XCTAssertFalse(element.getBoolAttribute("visible"))

        element.setAttribute("visible", value: "1")
        XCTAssertTrue(element.getBoolAttribute("visible"))

        XCTAssertFalse(element.getBoolAttribute("nonexistent"))
    }

    func testGetFloatAttribute() {
        let element = SVGElement(name: "rect")

        element.setAttribute("opacity", value: "0.5")
        XCTAssertEqual(element.getFloatAttribute("opacity"), 0.5)

        XCTAssertNil(element.getFloatAttribute("nonexistent"))
    }
}
