import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Specialized subclass of HTMLElement that deals with text. It represents a text node.
@objc(DTTextHTMLElement)
open class TextHTMLElement: HTMLElement {

    /// The text content of the element.
    /// Uses setValue to avoid shadowing the superclass text() method from HTMLParserNode.
    private var _text: String = ""

    @objc open func setText(_ text: String) {
        _text = text
    }

    @objc open func getText() -> String {
        return _text
    }

    /// Override to return our stored text instead of walking children.
    @objc open override func text() -> String {
        return _text
    }

    open override func _appendHTML(to string: NSMutableString, indentLevel: Int) {
        // indent to the level
        for _ in 0..<indentLevel {
            string.append("   ")
        }

        string.append("\"\((_text as NSString).stringByNormalizingWhitespace())\"\n")
    }

    @objc open override func attributedString() -> NSAttributedString? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        var text: String

        if _preserveNewlines {
            text = _text

            // PRE ignores the first \n
            if text.hasPrefix("\n") {
                text = String(text.dropFirst())
            }

            // PRE ignores the last \n
            if text.hasSuffix("\n") {
                text = String(text.dropLast())
            }

            // replace paragraph breaks with line breaks
            // using \r as to not confuse this with line feeds, but still get a single paragraph
            text = text.replacingOccurrences(of: "\n", with: "\r")
        } else if _containsAppleConvertedSpace {
            // replace nbsp; with regular space
            text = _text.replacingOccurrences(of: UNICODE_NON_BREAKING_SPACE, with: " ")
        } else {
            text = (_text as NSString).stringByNormalizingWhitespace() as String
        }

        let attributes = attributesForAttributedStringRepresentation() as! [NSAttributedString.Key: Any]

        if self.fontVariant == .normal {
            // make a new attributed string from the text
            return NSAttributedString(string: text, attributes: attributes)
        } else {
            if self.fontDescriptor.supportsNativeSmallCaps() {
                let smallDesc = self.fontDescriptor.copy() as! CoreTextFontDescriptor
                smallDesc.smallCapsFeature = true

                var smallAttributes = attributes

                let smallerFont = smallDesc.newMatchingFont()

                if let smallerFont = smallerFont {
                    #if canImport(UIKit)
                    let font = UIFont.font(with: smallerFont)
                    smallAttributes[.font] = font
                    #else
                    smallAttributes[.font] = smallerFont
                    #endif
                }

                return NSAttributedString(string: _text, attributes: smallAttributes)
            } else {
                return NSAttributedString.synthesizedSmallCapsAttributedString(withText: _text, attributes: attributes as NSDictionary)
            }
        }
    }
}
