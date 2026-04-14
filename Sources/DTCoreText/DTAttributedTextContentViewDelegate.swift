#if canImport(UIKit) && !os(watchOS)
  import UIKit

  /// Protocol to provide custom views for elements in an `AttributedTextContentView`.
  /// Also receives notifications before/after drawing.
  @objc public protocol DTAttributedTextContentViewDelegate: NSObjectProtocol {

    /// Called before a layout frame is drawn.
    @objc optional func attributedTextContentView(
      _ attributedTextContentView: AttributedTextContentView,
      willDrawLayoutFrame layoutFrame: CoreTextLayoutFrame,
      in context: CGContext)

    /// Called after a layout frame is drawn.
    @objc optional func attributedTextContentView(
      _ attributedTextContentView: AttributedTextContentView,
      didDrawLayoutFrame layoutFrame: CoreTextLayoutFrame,
      in context: CGContext)

    /// Called before a text block background is drawn. Return `true` to draw the default background fill.
    @objc optional func attributedTextContentView(
      _ attributedTextContentView: AttributedTextContentView,
      shouldDrawBackgroundFor textBlock: TextBlock,
      frame: CGRect,
      context: CGContext,
      forLayoutFrame layoutFrame: CoreTextLayoutFrame
    ) -> Bool

    /// Provide a custom view for an attachment (e.g. an image view).
    @objc optional func attributedTextContentView(
      _ attributedTextContentView: AttributedTextContentView,
      viewForAttachment attachment: TextAttachment,
      frame: CGRect
    ) -> UIView?

    /// Provide a custom view/button for a hyperlink.
    @objc optional func attributedTextContentView(
      _ attributedTextContentView: AttributedTextContentView,
      viewForLink url: URL,
      identifier: String,
      frame: CGRect
    ) -> UIView?

    /// Provide a generic custom view for an attributed string element.
    @objc optional func attributedTextContentView(
      _ attributedTextContentView: AttributedTextContentView,
      viewForAttributedString string: NSAttributedString,
      frame: CGRect
    ) -> UIView?
  }

#endif
