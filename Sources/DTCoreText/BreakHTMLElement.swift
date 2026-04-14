import Foundation

/// Specialized subclass of HTMLElement that represents a line break.
open class BreakHTMLElement: HTMLElement {

  open override func attributedString() -> NSAttributedString? {
    _outputLock.lock()
    defer { _outputLock.unlock() }

    let attributes = attributesForAttributedStringRepresentation()
    return NSAttributedString(
      string: UNICODE_LINE_FEED, attributes: attributes as? [NSAttributedString.Key: Any])
  }
}
