import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

// MARK: - Attachment layout helpers

/// Layout size for any `NSTextAttachment`. For `TextAttachment` (the DTCoreText
/// subclass) this returns `displaySize`; for a plain `NSTextAttachment` we fall
/// back to `bounds.size` and then the image's intrinsic size.
internal func dtAttachmentLayoutSize(_ attachment: NSTextAttachment) -> CGSize {
  if let dt = attachment as? TextAttachment {
    return dt.displaySize
  }
  let bounds = attachment.bounds
  if bounds.size != .zero {
    return bounds.size
  }
  if let imageSize = attachment.image?.size, imageSize != .zero {
    return imageSize
  }
  return .zero
}

/// Ascent above the baseline for any `NSTextAttachment`. `TextAttachment`
/// honors its `verticalAlignment`; plain attachments derive ascent from the
/// `bounds` rectangle (whatever portion sits above the baseline).
internal func dtAttachmentLayoutAscent(_ attachment: NSTextAttachment) -> CGFloat {
  if let dt = attachment as? TextAttachment {
    return dt.ascentForLayout()
  }
  let bounds = attachment.bounds
  let height = dtAttachmentLayoutSize(attachment).height
  // With a zero-origin bounds rect the whole height sits above the baseline.
  // A negative origin.y pushes part of the glyph below the baseline; the
  // remainder above is the ascent.
  let ascent = height + bounds.origin.y
  return max(ascent, 0)
}

/// Descent below the baseline for any `NSTextAttachment`.
internal func dtAttachmentLayoutDescent(_ attachment: NSTextAttachment) -> CGFloat {
  if let dt = attachment as? TextAttachment {
    return dt.descentForLayout()
  }
  return max(-attachment.bounds.origin.y, 0)
}

// MARK: - CTRunDelegate factory

/// Creates a CTRunDelegate for text attachments.
///
/// The run delegate provides ascent, descent, and width callbacks that Core
/// Text queries during layout for embedded objects. The callbacks accept any
/// `NSTextAttachment`: `TextAttachment` (the DTCoreText subclass) reports its
/// `displaySize`/`ascentForLayout`/`descentForLayout`, while plain attachments
/// fall back to `bounds` / `image` via the helpers above.
///
/// - Parameter obj: The text attachment object. For layout to honor custom
///   metrics this must be an `NSTextAttachment` (or subclass).
/// - Returns: A CTRunDelegate, or nil if creation fails.
public func createEmbeddedObjectRunDelegate(_ obj: AnyObject?) -> CTRunDelegate? {
  guard let obj = obj else { return nil }

  var callbacks = CTRunDelegateCallbacks(
    version: kCTRunDelegateCurrentVersion,
    dealloc: { _ in
      // no-op
    },
    getAscent: { context in
      let attachment = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue()
      if let textAttachment = attachment as? NSTextAttachment {
        return dtAttachmentLayoutAscent(textAttachment)
      }
      return 0
    },
    getDescent: { context in
      let attachment = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue()
      if let textAttachment = attachment as? NSTextAttachment {
        return dtAttachmentLayoutDescent(textAttachment)
      }
      return 0
    },
    getWidth: { context in
      let attachment = Unmanaged<AnyObject>.fromOpaque(context).takeUnretainedValue()
      if let textAttachment = attachment as? NSTextAttachment {
        return dtAttachmentLayoutSize(textAttachment).width
      }
      return 35
    }
  )

  let pointer = Unmanaged.passUnretained(obj).toOpaque()
  return CTRunDelegateCreate(&callbacks, pointer)
}
