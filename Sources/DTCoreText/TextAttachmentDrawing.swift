import CoreGraphics
import Foundation

/// Methods to implement for attachments to support inline drawing.
@objc(DTTextAttachmentDrawing)
public protocol TextAttachmentDrawing {
  /// Draws the contents of the receiver into a graphics context
  func draw(in rect: CGRect, context: CGContext)
}
