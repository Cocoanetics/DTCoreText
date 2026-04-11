import Foundation

/// Specialized subclass of HTMLParserNode that represents text inside a node
@objc(DTHTMLParserTextNode)
open class HTMLParserTextNode: HTMLParserNode {

  /// The character contents of the text node
  @objc public private(set) var characters: String

  /// Designated initializer with the characters that make up the text.
  /// - Parameter characters: The characters of the string
  @objc public init(characters: String) {
    self.characters = characters
    super.init(name: "#TEXT#", attributes: nil)
  }

  public required init(name: String, attributes: NSDictionary?) {
    self.characters = ""
    super.init(name: name, attributes: attributes)
  }

  open override var description: String {
    return "<\(type(of: self)) content='\(characters)'>"
  }

  override func appendHTML(to string: NSMutableString, indentLevel: Int) {
    // indent to the level
    for _ in 0..<indentLevel {
      string.append("   ")
    }

    let normalized = characters.normalizingWhitespace()
    string.append("\"\(normalized)\"\n")
  }
}
