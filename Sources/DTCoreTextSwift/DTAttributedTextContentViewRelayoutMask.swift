#if canImport(UIKit) && !os(watchOS)

  /// Option set controlling when the content view relayouts its text on bounds changes.
  public struct DTAttributedTextContentViewRelayoutMask: OptionSet, @unchecked Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }

    /// Never relayout automatically.
    public static let never = DTAttributedTextContentViewRelayoutMask([])

    /// Relayout when the width changes.
    public static let onWidthChanged = DTAttributedTextContentViewRelayoutMask(rawValue: 1 << 0)

    /// Relayout when the height changes.
    public static let onHeightChanged = DTAttributedTextContentViewRelayoutMask(rawValue: 1 << 1)
  }

#endif
