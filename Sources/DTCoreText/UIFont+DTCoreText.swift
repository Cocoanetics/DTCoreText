import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit

  /// Methods to translate from CTFont to UIFont
  extension UIFont {

    /// Creates a UIFont that matches the provided CTFont.
    /// - Parameter ctFont: A CTFontRef
    /// - Returns: The matching UIFont
    @objc public static func font(with ctFont: CTFont) -> UIFont? {
      let fontName = CTFontCopyName(ctFont, kCTFontFullNameKey) as String? ?? ""
      let fontSize = CTFontGetSize(ctFont)
      var font = UIFont(name: fontName, size: fontSize)

      // fix for missing HelveticaNeue-Italic font in iOS 7.0.x
      if font == nil && fontName == "HelveticaNeue-Italic" {
        font = UIFont(name: "HelveticaNeue-LightItalic", size: fontSize)
      }

      let matrix = CTFontGetMatrix(ctFont)
      if let font, !matrix.isIdentity {
        // Preserve synthetic transforms for both UIKit and Core Text runs.
        let descriptor = font.fontDescriptor.addingAttributes([
          UIFontDescriptor.AttributeName.matrix: NSValue(cgAffineTransform: matrix)
        ])
        return UIFont(descriptor: descriptor, size: fontSize)
      }

      return font
    }
  }

#endif
