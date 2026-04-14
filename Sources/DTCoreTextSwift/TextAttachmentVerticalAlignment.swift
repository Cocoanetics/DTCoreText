import Foundation

/// Text Attachment vertical alignment
@objc(DTTextAttachmentVerticalAlignment)
public enum TextAttachmentVerticalAlignment: UInt {
  /// Baseline alignment (default)
  case baseline = 0
  /// Align with top edge
  case top
  /// Align with center
  case center
  /// Align with bottom edge
  case bottom
}
