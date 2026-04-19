import Foundation

/// Specialized subclass of HTMLParserNode that represents text inside a node.
open class HTMLParserTextNode: HTMLParserNode {

  /// The character contents of the text node
  public private(set) var characters: String

  /// Designated initializer with the characters that make up the text.
  /// - Parameter characters: The characters of the string
  public init(characters: String) {
    self.characters = characters
    super.init(name: "#TEXT#", attributes: nil)
  }

  public required init(name: String, attributes: [String: String]?) {
    self.characters = ""
    super.init(name: name, attributes: attributes)
  }

  override func appendHTML(to string: inout String, indentLevel: Int) {
    for _ in 0..<indentLevel { string.append("   ") }
    string.append("\"\(characters.normalizingWhitespace())\"\n")
  }
}
