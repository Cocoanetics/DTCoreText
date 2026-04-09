import Foundation

/// Represents one node in an HTML DOM tree.
@objc(DTHTMLParserNode)
open class HTMLParserNode: NSObject {

    @objc public var name: String
    @objc public var attributes: NSDictionary?
    @objc public weak var parentNode: HTMLParserNode?

    private var _childNodes: NSMutableArray?

    /// Designated initializer
    /// - Parameters:
    ///   - name: The element name
    ///   - attributes: The attributes dictionary
    @objc public required init(name: String, attributes: NSDictionary?) {
        self.name = name
        super.init()
        self.attributes = attributes
    }

    /// The child nodes of the receiver
    @objc public var childNodes: NSArray? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return _childNodes
    }

    /// Adds a child node to the receiver.
    /// - Parameter childNode: The child node to be appended to the list of children
    @objc public func addChildNode(_ childNode: HTMLParserNode) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if _childNodes == nil {
            _childNodes = NSMutableArray()
        }

        childNode.parentNode = self
        _childNodes?.add(childNode)
    }

    /// Removes a child node from the receiver
    /// - Parameter childNode: The child node to remove
    @objc public func removeChildNode(_ childNode: HTMLParserNode) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        _childNodes?.remove(childNode)
    }

    /// Removes all child nodes from the receiver
    @objc public func removeAllChildNodes() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        _childNodes?.removeAllObjects()
    }

    open override var description: String {
        return "<\(type(of: self)) name='\(name)'>"
    }

    func _appendHTML(to string: NSMutableString, indentLevel: Int) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        // indent to the level
        for _ in 0..<indentLevel {
            string.append("   ")
        }

        // write own name tag open
        string.append("<\(name)")

        // sort attribute names
        if let attrs = attributes as? [String: Any] {
            let sortedKeys = attrs.keys.sorted()
            for key in sortedKeys {
                if let value = attrs[key] {
                    string.append(" \(key)=\"\(value)\"")
                }
            }
        }

        guard let children = _childNodes, children.count > 0 else {
            string.append(" \\>\n")
            return
        }

        string.append(">\n")

        // output children
        for child in children {
            if let childNode = child as? HTMLParserNode {
                childNode._appendHTML(to: string, indentLevel: indentLevel + 1)
            }
        }

        // indent to the level
        for _ in 0..<indentLevel {
            string.append("   ")
        }

        // write own name tag close
        string.append("</\(name)>\n")
    }

    /// Hierarchy representation of the receiver including all attributes and children
    @objc open override var debugDescription: String {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let tmpString = NSMutableString()
        _appendHTML(to: tmpString, indentLevel: 0)
        return tmpString as String
    }

    /// Concatenated contents of all text nodes
    @objc public func text() -> String {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let result = NSMutableString()

        if let children = _childNodes {
            for child in children {
                if let textNode = child as? HTMLParserTextNode {
                    result.append(textNode.characters)
                }
            }
        }

        return result as String
    }
}
