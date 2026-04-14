import Foundation

public enum DTHTMLElementFloatStyle: UInt, Sendable {
  /// The element does not float
  case none = 0
  /// The element should float left-aligned
  case left
  /// The element should float right-aligned
  case right
}
