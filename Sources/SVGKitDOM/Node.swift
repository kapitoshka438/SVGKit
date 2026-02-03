import Foundation

/// Node type enumeration matching W3C DOM Level 2
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public enum NodeType: Int, Sendable {
    case element = 1
    case attribute = 2
    case text = 3
    case cdataSection = 4
    case entityReference = 5
    case entity = 6
    case processingInstruction = 7
    case comment = 8
    case document = 9
    case documentType = 10
    case documentFragment = 11
    case notation = 12
}

/// Base protocol for all DOM nodes
/// W3C Spec: https://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html#ID-1950641247
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public protocol DOMNode: AnyObject {
    /// The type of this node
    var nodeType: NodeType { get }

    /// The name of this node
    var nodeName: String { get }

    /// The value of this node (null for most node types)
    var nodeValue: String? { get set }

    /// The parent node (null for root nodes)
    var parentNode: (any DOMNode)? { get set }

    /// Child nodes
    var childNodes: [any DOMNode] { get }

    /// First child node
    var firstChild: (any DOMNode)? { get }

    /// Last child node
    var lastChild: (any DOMNode)? { get }

    /// Previous sibling
    var previousSibling: (any DOMNode)? { get }

    /// Next sibling
    var nextSibling: (any DOMNode)? { get }

    /// Append a child node
    @discardableResult
    func appendChild(_ node: any DOMNode) -> any DOMNode

    /// Remove a child node
    @discardableResult
    func removeChild(_ node: any DOMNode) -> any DOMNode

    /// Insert a node before a reference node
    @discardableResult
    func insertBefore(_ newNode: any DOMNode, refChild: (any DOMNode)?) -> any DOMNode
}

/// Base implementation of DOMNode
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
open class Node: DOMNode {
    public let nodeType: NodeType
    public var nodeName: String
    public var nodeValue: String?
    public weak var parentNode: (any DOMNode)?

    private var _childNodes: [any DOMNode] = []

    public var childNodes: [any DOMNode] {
        return _childNodes
    }

    public var firstChild: (any DOMNode)? {
        return _childNodes.first
    }

    public var lastChild: (any DOMNode)? {
        return _childNodes.last
    }

    public var previousSibling: (any DOMNode)? {
        guard let parent = parentNode as? Node,
              let index = parent._childNodes.firstIndex(where: { $0 === self }),
              index > 0 else {
            return nil
        }
        return parent._childNodes[index - 1]
    }

    public var nextSibling: (any DOMNode)? {
        guard let parent = parentNode as? Node,
              let index = parent._childNodes.firstIndex(where: { $0 === self }),
              index < parent._childNodes.count - 1 else {
            return nil
        }
        return parent._childNodes[index + 1]
    }

    public init(type: NodeType, name: String) {
        self.nodeType = type
        self.nodeName = name
        self.nodeValue = nil
    }

    @discardableResult
    public func appendChild(_ node: any DOMNode) -> any DOMNode {
        _childNodes.append(node)
        node.parentNode = self
        return node
    }

    @discardableResult
    public func removeChild(_ node: any DOMNode) -> any DOMNode {
        if let index = _childNodes.firstIndex(where: { $0 === node }) {
            _childNodes.remove(at: index)
            node.parentNode = nil
        }
        return node
    }

    @discardableResult
    public func insertBefore(_ newNode: any DOMNode, refChild: (any DOMNode)?) -> any DOMNode {
        if let refChild = refChild,
           let index = _childNodes.firstIndex(where: { $0 === refChild }) {
            _childNodes.insert(newNode, at: index)
        } else {
            _childNodes.append(newNode)
        }
        newNode.parentNode = self
        return newNode
    }
}
