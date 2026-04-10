import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Specialized subclass of HTMLElement that represents a hyperlink.
@objc(DTAnchorHTMLElement)
open class AnchorHTMLElement: HTMLElement {

  /// Foreground text color of the receiver when highlighted
  @objc open var highlightedTextColor: DTColor?

  @objc open override func applyStyleDictionary(_ styles: NSDictionary) {
    super.applyStyleDictionary(styles)

    // get highlight color from a:active pseudo-selector
    if let activeColor = styles["active:color"] as? String {
      self.highlightedTextColor = DTColorCreateWithHTMLName(activeColor)
    }
  }

  @objc open override func attributedString() -> NSAttributedString? {
    // super returns a mutable attributed string
    guard
      let mutableAttributedString = super.attributedString()?.mutableCopy()
        as? NSMutableAttributedString
    else {
      return nil
    }

    if let highlightedTextColor = highlightedTextColor {
      let range = NSRange(location: 0, length: mutableAttributedString.length)

      // this additional attribute keeps the highlight color
      mutableAttributedString.addAttribute(
        NSAttributedString.Key(rawValue: DTLinkHighlightColorAttribute),
        value: highlightedTextColor, range: range)

      // we need to set the text color via the graphics context
      mutableAttributedString.addAttribute(
        NSAttributedString.Key(rawValue: kCTForegroundColorFromContextAttributeName as String),
        value: NSNumber(value: true), range: range)
    }

    return mutableAttributedString
  }
}
