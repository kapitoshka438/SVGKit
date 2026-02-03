import Foundation

/// DOM Element node with attributes
/// W3C Spec: https://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html#ID-745549614
@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
open class Element: Node {
    /// Element tag name
    public var tagName: String {
        return nodeName
    }

    /// Element attributes
    private var attributes: [String: String] = [:]

    /// Namespace URI
    public var namespaceURI: String?

    /// Namespace prefix
    public var prefix: String?

    /// Local name (without prefix)
    public var localName: String

    /// Initialize an element
    /// - Parameters:
    ///   - name: Element name
    ///   - namespaceURI: Namespace URI (optional)
    ///   - prefix: Namespace prefix (optional)
    public init(name: String, namespaceURI: String? = nil, prefix: String? = nil) {
        self.namespaceURI = namespaceURI
        self.prefix = prefix

        // Extract local name
        if let colonIndex = name.firstIndex(of: ":") {
            self.localName = String(name[name.index(after: colonIndex)...])
        } else {
            self.localName = name
        }

        super.init(type: .element, name: name)
    }

    // MARK: - Attributes

    /// Get attribute value
    /// - Parameter name: Attribute name
    /// - Returns: Attribute value or nil
    public func getAttribute(_ name: String) -> String? {
        return attributes[name]
    }

    /// Set attribute value
    /// - Parameters:
    ///   - name: Attribute name
    ///   - value: Attribute value
    public func setAttribute(_ name: String, value: String) {
        attributes[name] = value
    }

    /// Remove an attribute
    /// - Parameter name: Attribute name
    public func removeAttribute(_ name: String) {
        attributes.removeValue(forKey: name)
    }

    /// Check if attribute exists
    /// - Parameter name: Attribute name
    /// - Returns: True if attribute exists
    public func hasAttribute(_ name: String) -> Bool {
        return attributes[name] != nil
    }

    /// Get all attributes
    public func getAllAttributes() -> [String: String] {
        return attributes
    }

    /// Get attribute names
    public var attributeNames: [String] {
        return Array(attributes.keys)
    }

    // MARK: - Element Lookup

    /// Get elements by tag name (recursive)
    /// - Parameter name: Tag name to search for
    /// - Returns: Array of matching elements
    public func getElementsByTagName(_ name: String) -> [Element] {
        var results: [Element] = []

        if self.tagName == name {
            results.append(self)
        }

        for child in childNodes {
            if let element = child as? Element {
                results.append(contentsOf: element.getElementsByTagName(name))
            }
        }

        return results
    }

    /// Get element by ID (recursive search)
    /// - Parameter id: Element ID
    /// - Returns: First element with matching ID
    public func getElementById(_ id: String) -> Element? {
        if getAttribute("id") == id {
            return self
        }

        for child in childNodes {
            if let element = child as? Element,
               let found = element.getElementById(id) {
                return found
            }
        }

        return nil
    }
}

// MARK: - CustomStringConvertible

@available(macOS 12.0, iOS 15.0, tvOS 15.0, *)
extension Element: CustomStringConvertible {
    public var description: String {
        var desc = "<\(tagName)"

        if !attributes.isEmpty {
            let attrs = attributes.map { "\($0.key)=\"\($0.value)\"" }.joined(separator: " ")
            desc += " \(attrs)"
        }

        if childNodes.isEmpty {
            desc += " />"
        } else {
            desc += ">..."
        }

        return desc
    }
}
