import Foundation

/// Specialized subclass of HTMLElement representing a style block.
@objc(DTStylesheetHTMLElement)
open class StylesheetHTMLElement: HTMLElement {

  @objc open override func attributedString() -> NSAttributedString? {
    return nil
  }

  /// Parses the text children and assembles the resulting stylesheet.
  @objc open func stylesheet() -> CSSStylesheet {
    let text = self.text()
    return CSSStylesheet(styleBlock: text)
  }
}
