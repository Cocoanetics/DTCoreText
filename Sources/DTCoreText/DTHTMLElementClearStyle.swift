import Foundation

/// The sides on which an element does not allow earlier floated content,
/// from the CSS `clear` property.
public enum DTHTMLElementClearStyle: UInt, Sendable {
  /// The element is not moved below floated content
  case none = 0
  /// The element begins below left-floated content
  case left
  /// The element begins below right-floated content
  case right
  /// The element begins below all floated content
  case both
}
