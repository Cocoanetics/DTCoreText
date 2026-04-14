import Foundation

/// CSS list marker types that `NSTextList.MarkerFormat` does not cover natively.
public enum DTTextListCustomMarker: Int {
  case none = 0
  case inherit = 1
  case decimalLeadingZero = 2
  case plus = 3
  case underscore = 4
  case image = 5
}
