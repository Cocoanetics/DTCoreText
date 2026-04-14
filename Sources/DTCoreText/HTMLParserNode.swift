import Foundation
import os

/// Represents one node in an HTML DOM tree.
open class HTMLParserNode: NSObject {

  @objc public var name: String
  @objc public var attributes: [String: String]?
  @objc public weak var parentNode: HTMLParserNode?

  private var childNodeStorage: [HTMLParserNode] = []
  private let lock = OSAllocatedUnfairLock()

  /// Designated initializer
  /// - Parameters:
  ///   - name: The element name
  ///   - attributes: The attributes dictionary
  public required init(name: String, attributes: [String: String]?) {
    self.name = name
    self.attributes = attributes
  }

  /// The child nodes of the receiver.
  public var children: [HTMLParserNode] {
    lock.lock()
    defer { lock.unlock() }
    return childNodeStorage
  }

  /// The last child node, or `nil` if the receiver has no children.
  public var lastChild: HTMLParserNode? {
    lock.lock()
    defer { lock.unlock() }
    return childNodeStorage.last
  }

  /// Adds a child node to the receiver.
  public func addChildNode(_ childNode: HTMLParserNode) {
    lock.lock()
    defer { lock.unlock() }

    childNode.parentNode = self
    childNodeStorage.append(childNode)
  }

  /// Removes a child node from the receiver.
  public func removeChildNode(_ childNode: HTMLParserNode) {
    lock.lock()
    defer { lock.unlock() }
    childNodeStorage.removeAll { $0 === childNode }
  }

  /// Removes all child nodes from the receiver.
  public func removeAllChildNodes() {
    lock.lock()
    defer { lock.unlock() }
    childNodeStorage.removeAll()
  }

  /// Concatenated contents of all text-node children.
  public func text() -> String {
    lock.lock()
    defer { lock.unlock() }

    var result = ""
    for child in childNodeStorage {
      if let textNode = child as? HTMLParserTextNode {
        result.append(textNode.characters)
      }
    }
    return result
  }

  // MARK: - Debug description

  func appendHTML(to string: inout String, indentLevel: Int) {
    lock.lock()
    defer { lock.unlock() }

    for _ in 0..<indentLevel { string.append("   ") }

    string.append("<\(name)")

    if let attrs = attributes {
      for key in attrs.keys.sorted() {
        if let value = attrs[key] {
          string.append(" \(key)=\"\(value)\"")
        }
      }
    }

    guard !childNodeStorage.isEmpty else {
      string.append(" \\>\n")
      return
    }

    string.append(">\n")

    for childNode in childNodeStorage {
      childNode.appendHTML(to: &string, indentLevel: indentLevel + 1)
    }

    for _ in 0..<indentLevel { string.append("   ") }

    string.append("</\(name)>\n")
  }

  /// Hierarchy representation of the receiver including all attributes and children.
  public override var debugDescription: String {
    var out = ""
    appendHTML(to: &out, indentLevel: 0)
    return out
  }
}
