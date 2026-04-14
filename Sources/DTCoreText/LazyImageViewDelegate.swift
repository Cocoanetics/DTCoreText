#if canImport(UIKit) && !os(watchOS)
  import UIKit

  /// Delegate protocol for `LazyImageView` to report downloaded image dimensions.
  @objc(DTLazyImageViewDelegate)
  public protocol LazyImageViewDelegate: AnyObject {
    /// Called when the image size becomes known.
    @objc optional func lazyImageView(
      _ lazyImageView: LazyImageView, didChangeImageSize size: CGSize)
  }

#endif
