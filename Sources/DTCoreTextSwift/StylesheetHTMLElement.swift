import Foundation

/// Specialized subclass of HTMLElement representing a style block.
open class StylesheetHTMLElement: HTMLElement {

  open override func attributedString() -> NSAttributedString? {
    return nil
  }

  /// Parses the text children and assembles the resulting stylesheet.
  open func stylesheet() -> CSSStylesheet {
    let text = self.text()
    return CSSStylesheet(styleBlock: text)
  }
}
