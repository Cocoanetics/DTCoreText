import Foundation

/// Methods to implement for attachments to support output to HTML.
@objc(DTTextAttachmentHTMLPersistence)
public protocol TextAttachmentHTMLPersistence {
  /// Creates a HTML representation of the receiver
  func stringByEncodingAsHTML() -> String
}
