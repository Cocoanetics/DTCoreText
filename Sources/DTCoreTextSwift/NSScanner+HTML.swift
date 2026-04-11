//
//  NSScanner+HTML.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

import Foundation

/// Extensions for `Scanner` to deal with HTML-specific parsing, primarily CSS-related things.
extension Scanner {

  /// Scans a single CSS attribute (e.g. `color: red;`) out of a CSS style declaration.
  ///
  /// - Returns: A tuple of `(name, value)` on success, or `nil` if no valid attribute starts
  ///   at the current scan position. The `value` is either a `String` (for zero or one token)
  ///   or `[String]` (for comma-separated lists such as `font-family`).
  public func scanCSSAttribute() -> (name: String, value: Any)? {
    let initialScanLocation = currentIndex

    let whiteCharacterSet = CharacterSet.whitespacesAndNewlines

    var nonWhiteCommaCharacterSet = CharacterSet.whitespacesAndNewlines
    nonWhiteCommaCharacterSet.formUnion(CharacterSet(charactersIn: ";,"))
    nonWhiteCommaCharacterSet.invert()

    let cssStyleAttributeNameCharacterSet = NSCharacterSet.dt_cssStyleAttributeNameCharacterSet

    // scan attribute name
    guard let attrName = scanCharacters(from: cssStyleAttributeNameCharacterSet) else {
      return nil
    }

    // skip whitespace
    _ = scanCharacters(from: whiteCharacterSet)

    // expect :
    guard scanString(":") != nil else {
      currentIndex = initialScanLocation
      return nil
    }

    // skip whitespace
    _ = scanCharacters(from: whiteCharacterSet)

    var results: [String] = []
    var nextIterationAddsNewEntry = true

    while !isAtEnd && scanString(";") == nil && scanString("'';") == nil
      && scanString("\"\";") == nil
    {
      // skip whitespace
      _ = scanCharacters(from: whiteCharacterSet)

      if let quoteStr = scanCharacters(from: NSCharacterSet.dt_quoteCharacterSet) {
        // attribute is quoted
        guard let quotedValue = scanUpToString(quoteStr) else {
          currentIndex = initialScanLocation
          return nil
        }

        if nextIterationAddsNewEntry {
          results.append(quotedValue)
          nextIterationAddsNewEntry = false
        } else if let last = results.last {
          results[results.count - 1] = "\(last) \(quoteStr)\(quotedValue)\(quoteStr)"
        }

        // skip ending quote
        _ = scanString(quoteStr)
      } else if let scanned = scanString("rgb(") {
        let rgbContent = scanUpToString(";") ?? ""
        let formattedRGBString = "\(scanned)\(rgbContent)"

        if nextIterationAddsNewEntry {
          results.append(formattedRGBString)
          nextIterationAddsNewEntry = false
        } else if let last = results.last {
          results[results.count - 1] = "\(last) \(formattedRGBString)"
        }
      } else if let scanned = scanString(",") {
        var isStringOnlyCSSProperty = false

        if attrName == "font"
          || attrName.range(of: "color") != nil
          || attrName.range(of: "shadow") != nil
          || attrName.range(of: "background") != nil
        {
          if let last = results.last {
            results[results.count - 1] = "\(last)\(scanned)"
          }
          isStringOnlyCSSProperty = true
        }

        if !isStringOnlyCSSProperty {
          nextIterationAddsNewEntry = true
        }
      } else if let vs = scanCharacters(from: nonWhiteCommaCharacterSet) {
        if !vs.isEmpty && vs != "," {
          if nextIterationAddsNewEntry {
            results.append(vs)
            nextIterationAddsNewEntry = false
          } else if let last = results.last {
            results[results.count - 1] = "\(last) \(vs)"
          }
        }
      }

      // skip whitespace
      _ = scanCharacters(from: whiteCharacterSet)
    }

    let value: Any
    switch results.count {
    case 0: value = ""
    case 1: value = results[0]
    default: value = results
    }
    return (attrName, value)
  }

  /// Scans a CSS `url(...)` construct.
  ///
  /// - Returns: The decoded URL string (with HTML entities replaced), or `nil` if no
  ///   `url(...)` construct starts at the current scan position. Returns an empty string
  ///   for an empty construct like `url("")`.
  @discardableResult
  public func scanCSSURL() -> String? {
    guard scanString("url(") != nil else {
      return nil
    }

    let quoteCharacterSet = NSCharacterSet.dt_quoteCharacterSet
    var attrValue: String?

    if let quoteStr = scanCharacters(from: quoteCharacterSet) {
      if quoteStr.count == 1 {
        attrValue = scanUpToString(quoteStr)
        _ = scanString(quoteStr)
      } else {
        // most likely e.g. href=""
        attrValue = ""
      }

      attrValue = attrValue?.stringByReplacingHTMLEntities()
    } else if let scanned = scanUpToString(")") {
      // non-quoted attribute, ends at )
      attrValue = scanned.stringByReplacingHTMLEntities()
    }

    return attrValue
  }

  /// Scans a typical HTML color (hex, `rgb(...)`, or a named color).
  ///
  /// - Returns: A tuple of `(color, name)` on success, or `nil` if no valid color starts
  ///   at the current scan position. The scanner is left unchanged on failure.
  public func scanHTMLColor() -> (color: DTColor, name: String)? {
    let indexBefore = currentIndex

    var colorName: String?

    var tokenEndSet = CharacterSet.whitespacesAndNewlines
    tokenEndSet.insert(charactersIn: ",")

    if scanString("#") != nil {
      currentIndex = indexBefore
      colorName = scanUpToCharacters(from: tokenEndSet)
    } else if scanString("rgb") != nil {
      if scanUpToString(")") != nil {
        let str = self.string
        let afterRGB = str.index(after: currentIndex)
        if afterRGB <= str.endIndex {
          currentIndex = afterRGB
        }
        colorName = String(str[indexBefore..<currentIndex])
          .trimmingCharacters(in: .whitespacesAndNewlines)
      }
    } else {
      // could be a plain html color name
      colorName = scanCharacters(from: .alphanumerics)
    }

    guard let name = colorName,
      let color = DTColorCreateWithHTMLName(name)
    else {
      currentIndex = indexBefore
      return nil
    }

    return (color, name)
  }
}

// MARK: - Private helper to call stringByReplacingHTMLEntities on String

extension String {
  fileprivate func stringByReplacingHTMLEntities() -> String {
    return (self as NSString).stringByReplacingHTMLEntities()
  }
}
