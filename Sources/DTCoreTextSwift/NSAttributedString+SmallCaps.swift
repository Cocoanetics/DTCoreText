import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#endif

/// Methods that generate an attributed string with Small Caps,
/// even if the used fonts don't support them natively.
public extension NSAttributedString {

    /// Creates an NSAttributedString from the given text and attributes and synthesizes small caps.
    /// For fonts without native small caps support, lowercase characters are uppercased with a reduced font size.
    /// - Parameters:
    ///   - text: The string to convert into an attributed string
    ///   - attributes: A dictionary with attributes for the attributed string
    /// - Returns: An attributed string with synthesized small caps, or nil if no font descriptor is found.
    @objc(dtct_synthesizedSmallCapsAttributedStringWithText:attributes:)
    class func synthesizedSmallCapsAttributedString(withText text: String, attributes: NSDictionary) -> NSAttributedString? {
        guard let fontDescriptor = attributes.dtct_fontDescriptor() else {
            return nil
        }

        guard let smallerFontDesc = fontDescriptor.copy() as? CoreTextFontDescriptor else {
            return nil
        }
        smallerFontDesc.pointSize *= 0.7

        guard let smallerFont = smallerFontDesc.newMatchingFont() else {
            return nil
        }

        let smallAttributes = NSMutableDictionary(dictionary: attributes)

        #if canImport(UIKit)
        let uiFont = UIFont(name: CTFontCopyPostScriptName(smallerFont) as String, size: CTFontGetSize(smallerFont)) ?? UIFont.systemFont(ofSize: CTFontGetSize(smallerFont))
        smallAttributes[NSAttributedString.Key.font] = uiFont
        #else
        smallAttributes[NSAttributedString.Key.font] = smallerFont
        #endif

        let tmpString = NSMutableAttributedString()
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil

        let lowerCaseChars = CharacterSet.lowercaseLetters

        while !scanner.isAtEnd {
            if let part = scanner.scanCharacters(from: lowerCaseChars) {
                let upper = part.uppercased()
                let partString = NSAttributedString(string: upper, attributes: smallAttributes as? [NSAttributedString.Key: Any])
                tmpString.append(partString)
            }

            if let part = scanner.scanUpToCharacters(from: lowerCaseChars) {
                let partString = NSAttributedString(string: part, attributes: attributes as? [NSAttributedString.Key: Any])
                tmpString.append(partString)
            }
        }

        return tmpString
    }
}
