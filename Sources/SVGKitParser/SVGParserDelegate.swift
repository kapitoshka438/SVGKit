import Foundation
import OSLog
import SVGKitCore
import SVGKitDOM

/// XMLParser delegate bridge for SVGParser
/// Handles XMLParser callbacks and dispatches to parser extensions
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
internal final class SVGParserDelegate: NSObject, XMLParserDelegate {
    /// Parser extensions
    private let extensions: [any ParserExtension]

    /// Source being parsed
    private let source: SVGSource

    /// Element stack
    private var elementStack: [any DOMNode] = []

    /// Character data buffer
    private var characterBuffer: String = ""

    /// The document being built
    private(set) var document: SVGDocument?

    /// Parsing errors
    private(set) var errors: [SVGError] = []

    /// Parsing warnings
    private(set) var warnings: [String] = []

    /// Namespace prefix to URI mapping
    private var namespacePrefixes: [String: String] = [
        "svg": "http://www.w3.org/2000/svg",
        "xlink": "http://www.w3.org/1999/xlink"
    ]

    /// Logger
    private let logger = SVGLogger.parser

    /// Initialize delegate
    /// - Parameters:
    ///   - extensions: Parser extensions
    ///   - source: Source being parsed
    init(extensions: [any ParserExtension], source: SVGSource) {
        self.extensions = extensions
        self.source = source
        super.init()
    }

    // MARK: - XMLParserDelegate

    func parserDidStartDocument(_ parser: XMLParser) {
        document = SVGDocument()
        elementStack = [document!]
        logger.debug("Parser started document")
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        logger.debug("Parser ended document")
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        // Process accumulated character data for parent element
        if !characterBuffer.isEmpty {
            if let parent = elementStack.last,
               !characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let textNode = document!.createTextNode(characterBuffer)
                parent.appendChild(textNode)
            }
            characterBuffer = ""
        }

        // Extract namespace and local name
        let namespace = namespaceURI ?? "http://www.w3.org/2000/svg"
        let localName: String
        let prefix: String?

        if let qName = qName, qName.contains(":") {
            let parts = qName.split(separator: ":", maxSplits: 1)
            prefix = String(parts[0])
            localName = String(parts[1])
        } else {
            prefix = nil
            localName = elementName
        }

        logger.debug("Start element: \(localName) in namespace: \(namespace)")

        // Find extension to handle this element
        guard let ext = findExtension(for: localName, namespace: namespace) else {
            warnings.append("No parser extension found for element: \(localName) in namespace: \(namespace)")
            logger.warning("No parser extension for: \(localName)")

            // Create generic element as fallback
            let element = SVGElement(name: elementName, namespaceURI: namespace)
            for (key, value) in attributeDict {
                element.setAttribute(key, value: value)
            }

            if let parent = elementStack.last {
                parent.appendChild(element)
            }
            elementStack.append(element)
            return
        }

        // Create parser context
        let context = ParserContext(
            source: source,
            parentNode: elementStack.last,
            characterData: ""
        )

        // Call extension synchronously
        do {
            let node = try ext.handleStartElement(
                localName: localName,
                prefix: prefix,
                namespace: namespace,
                attributes: attributeDict,
                context: context
            )

            if let node = node {
                // Append to parent
                if let parent = elementStack.last {
                    parent.appendChild(node)
                }

                // Register ID if it's an element with id attribute
                if let element = node as? Element,
                   let id = element.getAttribute("id") {
                    document?.registerElementID(element, id: id)
                }

                elementStack.append(node)
            }
        } catch {
            errors.append(.parsingFailed("Error handling element \(localName): \(error.localizedDescription)"))
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        // Process accumulated character data
        if !characterBuffer.isEmpty {
            if let current = elementStack.last,
               !characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let textNode = document!.createTextNode(characterBuffer)
                current.appendChild(textNode)
            }
            characterBuffer = ""
        }

        guard let current = elementStack.last else {
            warnings.append("Unexpected end element: \(elementName)")
            return
        }

        let namespace = namespaceURI ?? "http://www.w3.org/2000/svg"
        let localName = elementName.split(separator: ":").last.map(String.init) ?? elementName

        logger.debug("End element: \(localName)")

        // Find extension and call handleEndElement
        if let ext = findExtension(for: localName, namespace: namespace) {
            let context = ParserContext(
                source: source,
                parentNode: current.parentNode,
                characterData: ""
            )

            do {
                try ext.handleEndElement(node: current, context: context)
            } catch {
                errors.append(.parsingFailed("Error ending element \(localName): \(error.localizedDescription)"))
            }
        }

        elementStack.removeLast()
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        characterBuffer += string
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        errors.append(.malformedXML(parseError.localizedDescription))
        logger.error("Parse error: \(parseError.localizedDescription)")
    }

    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        warnings.append("Validation error: \(validationError.localizedDescription)")
        logger.warning("Validation error: \(validationError.localizedDescription)")
    }

    // MARK: - Helpers

    private func findExtension(for localName: String, namespace: String) -> (any ParserExtension)? {
        extensions.first { ext in
            ext.supportedNamespaces.contains(namespace) &&
            ext.supportedElements.contains(localName)
        }
    }
}
