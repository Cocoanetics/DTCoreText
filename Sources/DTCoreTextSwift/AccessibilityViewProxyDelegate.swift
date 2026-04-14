#if canImport(UIKit) && !os(watchOS)
  import UIKit

  /// Protocol to provide custom views for accessibility elements representing a TextAttachment.
  @objc(DTAccessibilityViewProxyDelegate)
  public protocol AccessibilityViewProxyDelegate {
    /// Provides a view for an attachment.
    func view(for attachment: TextAttachment, proxy: AccessibilityViewProxy) -> UIView?
  }

#endif
