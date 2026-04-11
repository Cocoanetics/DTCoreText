import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Methods for appending NSString instances to mutable attributed strings
extension NSMutableAttributedString {

  /// Fast last-character test that avoids bridging the whole backing store
  /// through a Swift `String`. Essential inside parser flush loops that can
  /// be invoked hundreds of thousands of times on a large document.
  @objc public func dt_hasSuffixCharacter(from characterSet: CharacterSet) -> Bool {
    guard length > 0 else { return false }
    let lastChar = mutableString.character(at: length - 1)
    guard let scalar = Unicode.Scalar(lastChar) else { return false }
    return characterSet.contains(scalar)
  }

  /// Fast first-character test, same rationale as `dt_hasSuffixCharacter`.
  @objc public func dt_hasPrefixCharacter(from characterSet: CharacterSet) -> Bool {
    guard length > 0 else { return false }
    let firstChar = mutableString.character(at: 0)
    guard let scalar = Unicode.Scalar(firstChar) else { return false }
    return characterSet.contains(scalar)
  }

  /// Legacy up-migration: scan the receiver for the internal `DTTextListsAttribute` key,
  /// copy each array onto the corresponding paragraph style's `textLists`, and strip the
  /// old attribute. Call this at every public entry point that accepts externally-supplied
  /// attributed strings so that DTCoreText's own code paths can rely on
  /// `NSParagraphStyle.textLists` as the single source of truth.
  ///
  /// No-op for attributed strings produced by current DTCoreText code (they already carry
  /// `textLists` on the paragraph style, and do not set `DTTextListsAttribute`). Only
  /// attributed strings persisted under the pre-migration scheme need this.
  @objc public func dtct_migrateLegacyListAttribute() {
    let listsKey = NSAttributedString.Key(rawValue: DTTextListsAttribute)
    let paragraphKey = NSAttributedString.Key.paragraphStyle
    let fullRange = NSRange(location: 0, length: length)

    var foundAny = false

    enumerateAttribute(listsKey, in: fullRange, options: []) { value, range, _ in
      guard let lists = value as? [NSTextList], !lists.isEmpty else { return }
      foundAny = true

      // Walk the run and rewrite each sub-range's paragraph style to include the lists.
      enumerateAttribute(paragraphKey, in: range, options: []) { psValue, psRange, _ in
        let mps: NSMutableParagraphStyle
        if let existing = psValue as? NSParagraphStyle {
          mps = existing.mutableCopy() as! NSMutableParagraphStyle
        } else {
          mps = NSMutableParagraphStyle()
        }
        if mps.textLists != lists {
          mps.textLists = lists
        }
        addAttribute(paragraphKey, value: mps, range: psRange)
      }
    }

    if foundAny {
      removeAttribute(listsKey, range: fullRange)
    }
  }
}

extension NSMutableAttributedString {

  /// Appends a string with the same attributes as the end of this string.
  /// Removes attachment placeholders and field attributes from the appended part.
  @objc(dtct_appendString:)
  public func dtct_appendString(_ string: String) {
    let length = self.length

    let appendString: NSAttributedString
    if length > 0 {
      let attributes = NSMutableDictionary(
        dictionary: self.attributes(at: length - 1, effectiveRange: nil))
      // remove image placeholder to prevent duplication
      attributes.removeObject(forKey: NSAttributedString.Key.attachment)
      attributes.removeObject(forKey: kCTRunDelegateAttributeName as String)
      // remove field attribute
      attributes.removeObject(forKey: DTFieldAttribute as String)

      appendString = NSAttributedString(
        string: string, attributes: attributes as? [NSAttributedString.Key: Any])
    } else {
      appendString = NSAttributedString(string: string)
    }

    self.append(appendString)
  }

  /// Appends a string with a given paragraph style and font to this string.
  @objc(dtct_appendString:withParagraphStyle:fontDescriptor:)
  public func dtct_appendString(
    _ string: String, withParagraphStyle paragraphStyle: CoreTextParagraphStyle?,
    fontDescriptor: CoreTextFontDescriptor?
  ) {
    let selfLengthBefore = self.length

    self.mutableString.append(string)

    let appendedStringRange = NSRange(
      location: selfLengthBefore, length: (string as NSString).length)

    if paragraphStyle != nil || fontDescriptor != nil {
      let attributes = NSMutableDictionary()

      if let paragraphStyle = paragraphStyle {
        let style = paragraphStyle.nsParagraphStyle()
        attributes[NSAttributedString.Key.paragraphStyle] = style
      }

      if let fontDescriptor = fontDescriptor {
        if let newFont = fontDescriptor.newMatchingFont() {
          #if canImport(UIKit)
            let uiFont =
              UIFont(
                name: CTFontCopyPostScriptName(newFont) as String, size: CTFontGetSize(newFont))
              ?? UIFont.systemFont(ofSize: CTFontGetSize(newFont))
            attributes[NSAttributedString.Key.font] = uiFont
          #else
            attributes[NSAttributedString.Key.font] = newFont
          #endif
        }
      }

      self.setAttributes(attributes as? [NSAttributedString.Key: Any], range: appendedStringRange)
    } else {
      self.setAttributes([:], range: appendedStringRange)
    }
  }

  /// Adds the paragraph terminator and makes sure that the previous font and paragraph styles extend to include it
  @objc(dtct_appendEndOfParagraph)
  public func dtct_appendEndOfParagraph() {
    let length = self.length

    assert(length > 0, "Cannot append end of paragraph to empty string")

    let attributes = self.attributes(at: length - 1, effectiveRange: nil)

    var appendAttributes: [NSAttributedString.Key: Any] = [:]

    if let font = attributes[.font] {
      appendAttributes[.font] = font
    }

    if let paragraphStyle = attributes[.paragraphStyle] {
      appendAttributes[.paragraphStyle] = paragraphStyle
    }

    // transfer blocks
    if let blocks = attributes[NSAttributedString.Key(DTTextBlocksAttribute as String)] {
      appendAttributes[NSAttributedString.Key(DTTextBlocksAttribute as String)] = blocks
    }

    // List metadata is carried by the paragraph style (transferred just above).

    // transfer foreground color
    if let foregroundColor = attributes[.foregroundColor] {
      appendAttributes[.foregroundColor] = foregroundColor
    }

    let newlineString = NSAttributedString(string: "\n", attributes: appendAttributes)
    self.append(newlineString)
  }

  // MARK: - Working with Custom HTML Attributes

  /// Adds a custom HTML attribute with the given value on the given range.
  @objc(dtct_addHTMLAttribute:value:range:replaceExisting:)
  public func dtct_addHTMLAttribute(
    _ name: String, value: Any, range: NSRange, replaceExisting: Bool
  ) {
    let safeRange = NSIntersectionRange(range, NSRange(location: 0, length: self.length))
    let customKey = NSAttributedString.Key(DTCustomAttributesAttribute as String)

    self.beginEditing()

    let indexesToSet = NSMutableIndexSet(indexesIn: range)

    self.enumerateAttribute(customKey, in: safeRange, options: []) {
      dictionary, effectiveRange, _ in
      if let dict = dictionary as? NSDictionary {
        if dict[name] != nil && !replaceExisting {
          indexesToSet.remove(in: effectiveRange)
        }
      }
    }

    indexesToSet.enumerateRanges(in: safeRange, options: []) { indexRange, _ in
      self.enumerateAttribute(customKey, in: indexRange, options: []) {
        dictionary, effectiveRange, _ in
        if let dict = dictionary as? NSDictionary {
          let mutableDict = dict.mutableCopy() as! NSMutableDictionary
          mutableDict[name] = value
          self.addAttribute(
            customKey, value: mutableDict.copy() as! NSDictionary, range: effectiveRange)
        } else {
          let newDict: NSDictionary = [name: value]
          self.addAttribute(customKey, value: newDict, range: effectiveRange)
        }
      }
    }

    self.endEditing()
  }

  /// Removes the custom HTML attribute with the given name from the given range.
  @objc(dtct_removeHTMLAttribute:range:)
  public func dtct_removeHTMLAttribute(_ name: String, range: NSRange) {
    let safeRange = NSIntersectionRange(range, NSRange(location: 0, length: self.length))
    let customKey = NSAttributedString.Key(DTCustomAttributesAttribute as String)

    self.beginEditing()

    self.enumerateAttribute(customKey, in: safeRange, options: []) {
      dictionary, effectiveRange, _ in
      guard let dict = dictionary as? NSDictionary else { return }

      if dict[name] != nil {
        let mutableDict = dict.mutableCopy() as! NSMutableDictionary
        mutableDict.removeObject(forKey: name)

        if mutableDict.count > 0 {
          self.addAttribute(
            customKey, value: mutableDict.copy() as! NSDictionary, range: effectiveRange)
        } else {
          self.removeAttribute(customKey, range: effectiveRange)
        }
      }
    }

    self.endEditing()
  }
}
