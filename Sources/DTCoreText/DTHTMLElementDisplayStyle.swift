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
  /// The element is a table cell (td, th)
  case tableCell
  /// The element is a table row (tr)
  case tableRow
  /// The element is a group of table rows (thead, tbody, tfoot)
  case tableRowGroup
}
