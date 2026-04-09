import Foundation
import CoreText

#if canImport(UIKit)
import UIKit

/// Methods to translate from CTFont to UIFont
public extension UIFont {

    /// Creates a UIFont that matches the provided CTFont.
    /// - Parameter ctFont: A CTFontRef
    /// - Returns: The matching UIFont
    @objc static func font(with ctFont: CTFont) -> UIFont? {
        let fontName = CTFontCopyName(ctFont, kCTFontPostScriptNameKey) as String? ?? ""
        let fontSize = CTFontGetSize(ctFont)
        var font = UIFont(name: fontName, size: fontSize)

        // fix for missing HelveticaNeue-Italic font in iOS 7.0.x
        if font == nil && fontName == "HelveticaNeue-Italic" {
            font = UIFont(name: "HelveticaNeue-LightItalic", size: fontSize)
        }

        return font
    }
}

#endif
