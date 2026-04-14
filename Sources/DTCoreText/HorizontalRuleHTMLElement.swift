import Foundation

/// Specialized subclass of HTMLElement that represents a horizontal rule.
open class HorizontalRuleHTMLElement: HTMLElement {

  open override func attributesForAttributedStringRepresentation() -> NSDictionary {
    let dict =
      super.attributesForAttributedStringRepresentation().mutableCopy() as! NSMutableDictionary
    dict[NSAttributedString.Key(rawValue: DTHorizontalRuleStyleAttribute)] = NSNumber(value: true)
    return dict
  }

  open override func attributedString() -> NSAttributedString? {
    _outputLock.lock()
    defer { _outputLock.unlock() }

    let attributes = attributesForAttributedStringRepresentation()
    return NSAttributedString(
      string: "\n", attributes: attributes as? [NSAttributedString.Key: Any])
  }
}
