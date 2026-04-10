import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Convenience methods for editors dealing with Core Text attribute dictionaries.
extension NSDictionary {

  /// Whether the font in the receiver's attributes is bold.
  @objc(dtct_isBold)
  public func dtct_isBold() -> Bool {
    return dtct_fontDescriptor()?.boldTrait ?? false
  }

  /// Whether the font in the receiver's attributes is italic.
  @objc(dtct_isItalic)
  public func dtct_isItalic() -> Bool {
    return dtct_fontDescriptor()?.italicTrait ?? false
  }

  /// Whether the receiver's attributes contains underlining.
  @objc(dtct_isUnderline)
  public func dtct_isUnderline() -> Bool {
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
  public func dtct_isStrikethrough() -> Bool {
    if let strikethroughStyle = self[NSAttributedString.Key.strikethroughStyle.rawValue]
      as? NSNumber
    {
      return strikethroughStyle.boolValue
    }

    return false
  }

  /// The header level of the receiver
  @objc(dtct_headerLevel)
  public func dtct_headerLevel() -> Int {
    return (self[DTHeaderLevelAttribute as String] as? NSNumber)?.intValue ?? 0
  }

  /// Whether the receiver's attributes contain a TextAttachment
  @objc(dtct_hasAttachment)
  public func dtct_hasAttachment() -> Bool {
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
  public func dtct_paragraphStyle() -> CoreTextParagraphStyle? {
    // Try both the raw string key and the Key type (NSDictionary bridging may produce either)
    let nsValue =
      self[NSAttributedString.Key.paragraphStyle.rawValue]
      ?? self[NSAttributedString.Key.paragraphStyle]
    if let nsParagraphStyle = nsValue as? NSParagraphStyle {
      return CoreTextParagraphStyle.paragraphStyle(withNSParagraphStyle: nsParagraphStyle)
    }

    if let ctParagraphStyle = self[kCTParagraphStyleAttributeName as String] {
      let ctPS = unsafeBitCast(ctParagraphStyle as AnyObject, to: CTParagraphStyle.self)
      return CoreTextParagraphStyle(ctParagraphStyle: ctPS)
    }

    return nil
  }

  /// Retrieves the CoreTextFontDescriptor from the receiver's attributes.
  @objc(dtct_fontDescriptor)
  public func dtct_fontDescriptor() -> CoreTextFontDescriptor? {
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
  public func dtct_foregroundColor() -> DTColor {
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
  public func dtct_backgroundColor() -> DTColor? {
    let backgroundValue = self[NSAttributedString.Key.backgroundColor.rawValue]

    #if canImport(UIKit)
      if let color = backgroundValue as? UIColor {
        return color
      }
    #elseif canImport(AppKit)
      if let color = backgroundValue as? NSColor {
        return color
      }
    #endif

    if let cgColorObj = backgroundValue,
      CFGetTypeID(cgColorObj as CFTypeRef) == CGColor.typeID
    {
      let cgColor = unsafeBitCast(cgColorObj as AnyObject, to: CGColor.self)
      return DTColor(cgColor: cgColor)
    }

    return nil
  }

  /// The text kerning value
  @objc(dtct_kerning)
  public func dtct_kerning() -> CGFloat {
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
  public func dtct_backgroundStrokeColor() -> DTColor? {
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
  public func dtct_backgroundStrokeWidth() -> CGFloat {
    return (self[DTBackgroundStrokeWidthAttribute as String] as? NSNumber)?.doubleValue.toCGFloat
      ?? 0
  }

  /// The background corner radius
  @objc(dtct_backgroundCornerRadius)
  public func dtct_backgroundCornerRadius() -> CGFloat {
    return (self[DTBackgroundCornerRadiusAttribute as String] as? NSNumber)?.doubleValue.toCGFloat
      ?? 0
  }
}

extension Double {
  fileprivate var toCGFloat: CGFloat { CGFloat(self) }
}

// MARK: - Swift Dictionary Extensions

extension Dictionary where Key == NSAttributedString.Key, Value == Any {

  public func dtct_paragraphStyle() -> CoreTextParagraphStyle? {
    return (self as NSDictionary).dtct_paragraphStyle()
  }

  public func dtct_fontDescriptor() -> CoreTextFontDescriptor? {
    return (self as NSDictionary).dtct_fontDescriptor()
  }

  public func dtct_foregroundColor() -> DTColor {
    return (self as NSDictionary).dtct_foregroundColor()
  }

  public func dtct_backgroundColor() -> DTColor? {
    return (self as NSDictionary).dtct_backgroundColor()
  }
}

extension Dictionary where Key == String, Value == Any {

  public func dtct_paragraphStyle() -> CoreTextParagraphStyle? {
    return (self as NSDictionary).dtct_paragraphStyle()
  }

  public func dtct_fontDescriptor() -> CoreTextFontDescriptor? {
    return (self as NSDictionary).dtct_fontDescriptor()
  }

  public func dtct_foregroundColor() -> DTColor {
    return (self as NSDictionary).dtct_foregroundColor()
  }

  public func dtct_backgroundColor() -> DTColor? {
    return (self as NSDictionary).dtct_backgroundColor()
  }
}
