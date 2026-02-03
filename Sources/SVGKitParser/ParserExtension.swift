import Foundation
import SVGKitCore
@preconcurrency import SVGKitDOM

/// Protocol for parser extensions
/// Allows modular parsing of different XML namespaces and elements
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public protocol ParserExtension: Sendable {
    /// XML namespaces this extension handles
    var supportedNamespaces: Set<String> { get }

    /// XML element names this extension handles (local names without prefix)
    var supportedElements: Set<String> { get }

    /// Handle the start of an element
    /// - Parameters:
    ///   - localName: Element name without namespace prefix
    ///   - prefix: Namespace prefix (if any)
    ///   - namespace: Full namespace URI
    ///   - attributes: Element attributes
    ///   - context: Parsing context
    /// - Returns: The created DOM node, or nil to skip this element
    func handleStartElement(
        localName: String,
        prefix: String?,
        namespace: String,
        attributes: [String: String],
        context: ParserContext
    ) throws -> (any DOMNode)?

    /// Handle the end of an element
    /// Called for post-processing (e.g., text content handling)
    /// - Parameters:
    ///   - node: The node that was created
    ///   - context: Parsing context
    func handleEndElement(
        node: any DOMNode,
        context: ParserContext
    ) throws
}

/// Default implementation for handleEndElement (most elements don't need it)
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension ParserExtension {
    public func handleEndElement(
        node: any DOMNode,
        context: ParserContext
    ) throws {
        // Default: do nothing
    }
}

/// Context passed to parser extensions
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
public struct ParserContext: Sendable {
    /// The source being parsed
    public let source: SVGSource

    /// Current parent node
    public let parentNode: (any DOMNode)?

    /// Accumulated character data (for text nodes)
    public let characterData: String

    /// Create a new parser context
    public init(
        source: SVGSource,
        parentNode: (any DOMNode)?,
        characterData: String = ""
    ) {
        self.source = source
        self.parentNode = parentNode
        self.characterData = characterData
    }

    /// Create a new context with updated parent
    public func withParent(_ newParent: any DOMNode) -> ParserContext {
        ParserContext(
            source: source,
            parentNode: newParent,
            characterData: characterData
        )
    }

    /// Create a new context with updated character data
    public func withCharacterData(_ data: String) -> ParserContext {
        ParserContext(
            source: source,
            parentNode: parentNode,
            characterData: characterData + data
        )
    }

    /// Create a new context clearing character data
    public func clearingCharacterData() -> ParserContext {
        ParserContext(
            source: source,
            parentNode: parentNode,
            characterData: ""
        )
    }
}
