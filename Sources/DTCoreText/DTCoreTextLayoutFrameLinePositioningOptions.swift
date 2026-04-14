import Foundation

@objc public enum DTCoreTextLayoutFrameLinePositioningOptions: UInt {
  /// The line positioning algorithm is similar to how Safari positions lines
  case algorithmWebKit = 1
  /// The line positioning algorithm is how it was before the implementation of algorithmWebKit
  case algorithmLegacy = 2
}
