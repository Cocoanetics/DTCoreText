import Foundation

/// Specialized subclass of HTMLElement that represents a line break.
open class BreakHTMLElement: HTMLElement {

  open override func attributedString() -> NSAttributedString? {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    let attributes = attributesForAttributedStringRepresentation()
    return NSAttributedString(
      string: UNICODE_LINE_FEED, attributes: attributes as? [NSAttributedString.Key: Any])
  }
}
