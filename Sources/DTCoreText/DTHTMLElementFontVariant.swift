import Foundation

public enum DTHTMLElementFontVariant: UInt, Sendable {
  /// The element inherits the font variant
  case inherit = 0
  /// The element uses the normal font variant
  case normal
  /// The element should display in small caps
  case smallCaps
}
