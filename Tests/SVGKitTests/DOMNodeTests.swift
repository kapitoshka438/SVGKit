import XCTest
@testable import SVGKitDOM

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
final class DOMNodeTests: XCTestCase {

    func testNodeCreation() {
        let node = Node(type: .element, name: "svg")

        XCTAssertEqual(node.nodeType, .element)
        XCTAssertEqual(node.nodeName, "svg")
        XCTAssertNil(node.nodeValue)
        XCTAssertNil(node.parentNode)
        XCTAssertEqual(node.childNodes.count, 0)
    }

    func testAppendChild() {
        let parent = Node(type: .element, name: "svg")
        let child = Node(type: .element, name: "rect")

        parent.appendChild(child)

        XCTAssertEqual(parent.childNodes.count, 1)
        XCTAssertTrue(parent.childNodes[0] === child)
        XCTAssertTrue(child.parentNode === parent)
    }

    func testRemoveChild() {
        let parent = Node(type: .element, name: "svg")
        let child = Node(type: .element, name: "rect")

        parent.appendChild(child)
        XCTAssertEqual(parent.childNodes.count, 1)

        parent.removeChild(child)
        XCTAssertEqual(parent.childNodes.count, 0)
        XCTAssertNil(child.parentNode)
    }

    func testFirstChild() {
        let parent = Node(type: .element, name: "svg")
        let child1 = Node(type: .element, name: "rect")
        let child2 = Node(type: .element, name: "circle")

        XCTAssertNil(parent.firstChild)

        parent.appendChild(child1)
        parent.appendChild(child2)

        XCTAssertTrue(parent.firstChild === child1)
    }

    func testLastChild() {
        let parent = Node(type: .element, name: "svg")
        let child1 = Node(type: .element, name: "rect")
        let child2 = Node(type: .element, name: "circle")

        XCTAssertNil(parent.lastChild)

        parent.appendChild(child1)
        parent.appendChild(child2)

        XCTAssertTrue(parent.lastChild === child2)
    }

    func testPreviousSibling() {
        let parent = Node(type: .element, name: "svg")
        let child1 = Node(type: .element, name: "rect")
        let child2 = Node(type: .element, name: "circle")
        let child3 = Node(type: .element, name: "path")

        parent.appendChild(child1)
        parent.appendChild(child2)
        parent.appendChild(child3)

        XCTAssertNil(child1.previousSibling)
        XCTAssertTrue(child2.previousSibling === child1)
        XCTAssertTrue(child3.previousSibling === child2)
    }

    func testNextSibling() {
        let parent = Node(type: .element, name: "svg")
        let child1 = Node(type: .element, name: "rect")
        let child2 = Node(type: .element, name: "circle")
        let child3 = Node(type: .element, name: "path")

        parent.appendChild(child1)
        parent.appendChild(child2)
        parent.appendChild(child3)

        XCTAssertTrue(child1.nextSibling === child2)
        XCTAssertTrue(child2.nextSibling === child3)
        XCTAssertNil(child3.nextSibling)
    }

    func testInsertBefore() {
        let parent = Node(type: .element, name: "svg")
        let child1 = Node(type: .element, name: "rect")
        let child2 = Node(type: .element, name: "circle")
        let newChild = Node(type: .element, name: "path")

        parent.appendChild(child1)
        parent.appendChild(child2)

        parent.insertBefore(newChild, refChild: child2)

        XCTAssertEqual(parent.childNodes.count, 3)
        XCTAssertTrue(parent.childNodes[0] === child1)
        XCTAssertTrue(parent.childNodes[1] === newChild)
        XCTAssertTrue(parent.childNodes[2] === child2)
        XCTAssertTrue(newChild.parentNode === parent)
    }

    func testInsertBeforeWithNilReference() {
        let parent = Node(type: .element, name: "svg")
        let child1 = Node(type: .element, name: "rect")
        let newChild = Node(type: .element, name: "path")

        parent.appendChild(child1)
        parent.insertBefore(newChild, refChild: nil)

        XCTAssertEqual(parent.childNodes.count, 2)
        XCTAssertTrue(parent.childNodes[1] === newChild)
    }

    func testNodeType() {
        let element = Node(type: .element, name: "svg")
        let text = Node(type: .text, name: "#text")
        let comment = Node(type: .comment, name: "#comment")

        XCTAssertEqual(element.nodeType, .element)
        XCTAssertEqual(text.nodeType, .text)
        XCTAssertEqual(comment.nodeType, .comment)
    }

    func testNodeValue() {
        let node = Node(type: .text, name: "#text")
        XCTAssertNil(node.nodeValue)

        node.nodeValue = "Hello, World!"
        XCTAssertEqual(node.nodeValue, "Hello, World!")
    }

    func testComplexTree() {
        // Create a more complex tree:
        // svg
        //   ├─ g
        //   │  ├─ rect
        //   │  └─ circle
        //   └─ path

        let svg = Node(type: .element, name: "svg")
        let g = Node(type: .element, name: "g")
        let rect = Node(type: .element, name: "rect")
        let circle = Node(type: .element, name: "circle")
        let path = Node(type: .element, name: "path")

        svg.appendChild(g)
        g.appendChild(rect)
        g.appendChild(circle)
        svg.appendChild(path)

        XCTAssertEqual(svg.childNodes.count, 2)
        XCTAssertEqual(g.childNodes.count, 2)
        XCTAssertTrue(g.parentNode === svg)
        XCTAssertTrue(rect.parentNode === g)
        XCTAssertTrue(circle.parentNode === g)
        XCTAssertTrue(path.parentNode === svg)

        XCTAssertTrue(g.nextSibling === path)
        XCTAssertTrue(path.previousSibling === g)
        XCTAssertTrue(rect.nextSibling === circle)
    }
}
