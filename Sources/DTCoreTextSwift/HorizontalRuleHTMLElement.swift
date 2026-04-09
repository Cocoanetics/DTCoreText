import Foundation

/// Specialized subclass of HTMLElement that represents a horizontal rule.
@objc(DTHorizontalRuleHTMLElement)
open class HorizontalRuleHTMLElement: HTMLElement {

    @objc open override func attributesForAttributedStringRepresentation() -> NSDictionary {
        let dict = super.attributesForAttributedStringRepresentation().mutableCopy() as! NSMutableDictionary
        dict[NSAttributedString.Key(rawValue: DTHorizontalRuleStyleAttribute)] = NSNumber(value: true)
        return dict
    }

    @objc open override func attributedString() -> NSAttributedString? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        let attributes = attributesForAttributedStringRepresentation()
        return NSAttributedString(string: "\n", attributes: attributes as? [NSAttributedString.Key: Any])
    }
}
