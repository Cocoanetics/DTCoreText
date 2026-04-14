import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

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
