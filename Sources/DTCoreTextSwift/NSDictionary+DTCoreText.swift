import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Convenience methods for editors dealing with Core Text attribute dictionaries.
public extension NSDictionary {

    /// Whether the font in the receiver's attributes is bold.
    @objc(dtct_isBold)
    func dtct_isBold() -> Bool {
        return dtct_fontDescriptor()?.boldTrait ?? false
    }

    /// Whether the font in the receiver's attributes is italic.
    @objc(dtct_isItalic)
    func dtct_isItalic() -> Bool {
        return dtct_fontDescriptor()?.italicTrait ?? false
    }

    /// Whether the receiver's attributes contains underlining.
    @objc(dtct_isUnderline)
    func dtct_isUnderline() -> Bool {
        if let underlineStyle = self[kCTUnderlineStyleAttributeName as String] as? NSNumber {
            return underlineStyle.intValue != Int32(CTUnderlineStyle().rawValue)
        }

        if let underlineStyle = self[NSAttributedString.Key.underlineStyle.rawValue] as? NSNumber {
            return underlineStyle.intValue != NSUnderlineStyle().rawValue
        }

        return false
    }

    /// Whether the receiver's attributes contains strike-through.
    @objc(dtct_isStrikethrough)
    func dtct_isStrikethrough() -> Bool {
        if let strikethroughStyle = self[DTStrikeOutAttribute as String] as? NSNumber {
            return strikethroughStyle.boolValue
        }

        if let strikethroughStyle = self[NSAttributedString.Key.strikethroughStyle.rawValue] as? NSNumber {
            return strikethroughStyle.boolValue
        }

        return false
    }

    /// The header level of the receiver
    @objc(dtct_headerLevel)
    func dtct_headerLevel() -> Int {
        return (self[DTHeaderLevelAttribute as String] as? NSNumber)?.intValue ?? 0
    }

    /// Whether the receiver's attributes contain a TextAttachment
    @objc(dtct_hasAttachment)
    func dtct_hasAttachment() -> Bool {
        if self[NSAttributedString.Key.attachment.rawValue] != nil {
            return true
        }
        if self["NSAttachment"] != nil {
            return true
        }
        return false
    }

    /// Retrieves the CoreTextParagraphStyle from the receiver's attributes.
    @objc(dtct_paragraphStyle)
    func dtct_paragraphStyle() -> CoreTextParagraphStyle? {
        if let nsParagraphStyle = self[NSAttributedString.Key.paragraphStyle.rawValue] as? NSParagraphStyle {
            return CoreTextParagraphStyle(nsParagraphStyle: nsParagraphStyle)
        }

        if let ctParagraphStyle = self[kCTParagraphStyleAttributeName as String] {
            let ctPS = unsafeBitCast(ctParagraphStyle as AnyObject, to: CTParagraphStyle.self)
            return CoreTextParagraphStyle(ctParagraphStyle: ctPS)
        }

        return nil
    }

    /// Retrieves the CoreTextFontDescriptor from the receiver's attributes.
    @objc(dtct_fontDescriptor)
    func dtct_fontDescriptor() -> CoreTextFontDescriptor? {
        if let ctFont = self[kCTFontAttributeName as String] {
            let font = unsafeBitCast(ctFont as AnyObject, to: CTFont.self)
            return CoreTextFontDescriptor.fontDescriptor(for: font)
        }

        #if canImport(UIKit)
        if let uiFont = self[NSAttributedString.Key.font.rawValue] as? UIFont {
            let ctFont = DTCTFontCreateWithUIFont(uiFont)
            return CoreTextFontDescriptor.fontDescriptor(for: ctFont)
        }
        #endif

        return nil
    }

    /// Retrieves the foreground color.
    @objc(dtct_foregroundColor)
    func dtct_foregroundColor() -> DTColor {
        #if canImport(UIKit)
        if let color = self[NSAttributedString.Key.foregroundColor.rawValue] as? UIColor {
            return color
        }
        #elseif canImport(AppKit)
        if let color = self[NSAttributedString.Key.foregroundColor.rawValue] as? NSColor {
            return color
        }
        #endif

        if let cgColorObj = self[kCTForegroundColorAttributeName as String] {
            let cgColor = unsafeBitCast(cgColorObj as AnyObject, to: CGColor.self)
            #if canImport(UIKit)
            return DTColor(cgColor: cgColor)
            #else
            return DTColor(cgColor: cgColor) ?? DTColor.black
            #endif
        }

        return DTColor.black
    }

    /// Retrieves the background color.
    @objc(dtct_backgroundColor)
    func dtct_backgroundColor() -> DTColor? {
        if let cgColorObj = self[DTBackgroundColorAttribute as String] {
            if CFGetTypeID(cgColorObj as CFTypeRef) == CGColor.typeID {
                let cgColor = unsafeBitCast(cgColorObj as AnyObject, to: CGColor.self)
                #if canImport(UIKit)
                return DTColor(cgColor: cgColor)
                #else
                return DTColor(cgColor: cgColor)
                #endif
            }
        }

        #if canImport(UIKit)
        if let color = self[NSAttributedString.Key.backgroundColor.rawValue] as? UIColor {
            return color
        }
        #elseif canImport(AppKit)
        if let color = self[NSAttributedString.Key.backgroundColor.rawValue] as? NSColor {
            return color
        }
        #endif

        return nil
    }

    /// The text kerning value
    @objc(dtct_kerning)
    func dtct_kerning() -> CGFloat {
        if let kerningNum = self[NSAttributedString.Key.kern.rawValue] as? NSNumber {
            return CGFloat(kerningNum.floatValue)
        }

        if let kerningNum = self[kCTKernAttributeName as String] as? NSNumber {
            return CGFloat(kerningNum.floatValue)
        }

        return 0
    }

    /// Retrieves the background stroke color.
    @objc(dtct_backgroundStrokeColor)
    func dtct_backgroundStrokeColor() -> DTColor? {
        if let cgColorObj = self[DTBackgroundStrokeColorAttribute as String] {
            if CFGetTypeID(cgColorObj as CFTypeRef) == CGColor.typeID {
                let cgColor = unsafeBitCast(cgColorObj as AnyObject, to: CGColor.self)
                #if canImport(UIKit)
                return DTColor(cgColor: cgColor)
                #else
                return DTColor(cgColor: cgColor)
                #endif
            }
        }
        return nil
    }

    /// The background stroke width
    @objc(dtct_backgroundStrokeWidth)
    func dtct_backgroundStrokeWidth() -> CGFloat {
        return (self[DTBackgroundStrokeWidthAttribute as String] as? NSNumber)?.doubleValue.toCGFloat ?? 0
    }

    /// The background corner radius
    @objc(dtct_backgroundCornerRadius)
    func dtct_backgroundCornerRadius() -> CGFloat {
        return (self[DTBackgroundCornerRadiusAttribute as String] as? NSNumber)?.doubleValue.toCGFloat ?? 0
    }
}

private extension Double {
    var toCGFloat: CGFloat { CGFloat(self) }
}
