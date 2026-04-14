import Foundation

/// The drawing options for CoreTextLayoutFrame.
@objc(DTCoreTextLayoutFrameDrawingOptions)
public enum CoreTextLayoutFrameDrawingOptions: UInt {
  /// Default method draws links and attachments.
  case `default` = 1
  /// Links are not drawn.
  case omitLinks = 2
  /// Text attachments are omitted from drawing.
  case omitAttachments = 4
  /// Links are displayed highlighted.
  case drawLinksHighlighted = 8
}
