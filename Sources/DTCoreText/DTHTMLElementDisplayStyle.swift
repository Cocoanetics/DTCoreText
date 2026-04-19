import Foundation

public enum DTHTMLElementDisplayStyle: UInt, Sendable {
  /// The element is inline text
  case inline = 0
  /// The element is not displayed
  case none
  /// The element is a block
  case block
  /// The element is an item in a list
  case listItem
  /// The element is a table
  case table
}
