//
//  NSScanner+HTML.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

import Foundation

/// Extensions for NSScanner to deal with HTML-specific parsing, primarily CSS-related things.
extension Scanner {

  /// Scans for a CSS attribute used in CSS style sheets.
  @objc public func scanCSSAttribute(
    _ name: AutoreleasingUnsafeMutablePointer<NSString?>?,
    value: AutoreleasingUnsafeMutablePointer<AnyObject?>?
  ) -> Bool {
    var attrName: NSString?

    let initialScanLocation = currentIndex

    let whiteCharacterSet = CharacterSet.whitespacesAndNewlines

    var nonWhiteCharacterSet = CharacterSet.whitespacesAndNewlines
    nonWhiteCharacterSet.formUnion(CharacterSet(charactersIn: ";"))
    nonWhiteCharacterSet.invert()

    var nonWhiteCommaCharacterSet = CharacterSet.whitespacesAndNewlines
    nonWhiteCommaCharacterSet.formUnion(CharacterSet(charactersIn: ";,"))
    nonWhiteCommaCharacterSet.invert()

    let cssStyleAttributeNameCharacterSet = NSCharacterSet.dt_cssStyleAttributeNameCharacterSet

    // scan attribute name
    guard let scannedName = scanCharacters(from: cssStyleAttributeNameCharacterSet) else {
      return false
    }
    attrName = scannedName as NSString

    // skip whitespace
    _ = scanCharacters(from: whiteCharacterSet)

    // expect :
    guard scanString(":") != nil else {
      currentIndex = initialScanLocation
      return false
    }

    // skip whitespace
    _ = scanCharacters(from: whiteCharacterSet)

    let results = NSMutableArray()
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
          return false
        }

        if nextIterationAddsNewEntry {
          results.add(quotedValue)
          nextIterationAddsNewEntry = false
        } else {
          let combined = "\(results.lastObject!) \(quoteStr)\(quotedValue)\(quoteStr)"
          results.removeLastObject()
          results.add(combined)
        }

        // skip ending quote
        _ = scanString(quoteStr)
      } else {
        // attribute is not quoted
        if let scanned = scanString("rgb(") {
          if scanned == "rgb(" {
            let rgbContent = scanUpToString(";") ?? ""
            let formattedRGBString = "rgb(\(rgbContent)"

            if nextIterationAddsNewEntry {
              results.add(formattedRGBString)
              nextIterationAddsNewEntry = false
            } else {
              let combined = "\(results.lastObject!) \(formattedRGBString)"
              results.removeLastObject()
              results.add(combined)
            }
          }
        } else if let scanned = scanString(",") {
          var isStringOnlyCSSProperty = false

          if scanned != "," {
            results.add(scanned)
          } else if let name = attrName as String?,
            name == "font" || name.range(of: "color") != nil || name.range(of: "shadow") != nil
              || name.range(of: "background") != nil
          {
            let combined = "\(results.lastObject!)\(scanned)"
            results.removeLastObject()
            results.add(combined)
            isStringOnlyCSSProperty = true
          }

          if scanned == "," && !isStringOnlyCSSProperty {
            nextIterationAddsNewEntry = true
          }
        } else if let vs = scanCharacters(from: nonWhiteCommaCharacterSet) {
          if !vs.isEmpty && vs != "," {
            if nextIterationAddsNewEntry {
              results.add(vs)
              nextIterationAddsNewEntry = false
            } else {
              let combined = "\(results.lastObject!) \(vs)"
              results.removeLastObject()
              results.add(combined)
            }
          }
        }
      }

      // skip whitespace
      _ = scanCharacters(from: whiteCharacterSet)
    }

    // Success
    if let name = name {
      name.pointee = attrName
    }

    if let value = value {
      if results.count == 0 {
        value.pointee = "" as NSString
      } else if results.count == 1 {
        value.pointee = results[0] as AnyObject
      } else {
        value.pointee = results
      }
    }

    return true
  }

  /// Scans for URLs used in CSS style sheets.
  @objc public func scanCSSURL(_ urlString: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    guard scanString("url(") != nil else {
      return false
    }

    let quoteCharacterSet = NSCharacterSet.dt_quoteCharacterSet
    var attrValue: NSString?

    if let quoteStr = scanCharacters(from: quoteCharacterSet) {
      if quoteStr.count == 1 {
        attrValue = scanUpToString(quoteStr) as NSString?
        _ = scanString(quoteStr)
      } else {
        // most likely e.g. href=""
        attrValue = "" as NSString
      }

      // decode HTML entities
      attrValue = (attrValue as String?)?.stringByReplacingHTMLEntities() as NSString? ?? attrValue
    } else {
      // non-quoted attribute, ends at )
      if let scanned = scanUpToString(")") {
        attrValue = scanned.stringByReplacingHTMLEntities() as NSString
      }
    }

    urlString?.pointee = attrValue

    return true
  }

  /// Scans for a typical HTML color.
  @objc public func scanHTMLColor(_ color: AutoreleasingUnsafeMutablePointer<DTColor?>?) -> Bool {
    return scanHTMLColor(color, htmlName: nil)
  }

  /// Scans for a typical HTML color, returning both the color and its name.
  @objc public func scanHTMLColor(
    _ color: AutoreleasingUnsafeMutablePointer<DTColor?>?,
    htmlName name: AutoreleasingUnsafeMutablePointer<NSString?>?
  ) -> Bool {
    let indexBefore = currentIndex

    var colorName: NSString?

    var tokenEndSet = CharacterSet.whitespacesAndNewlines
    tokenEndSet.insert(charactersIn: ",")

    if scanString("#") != nil {
      currentIndex = indexBefore
      colorName = scanUpToCharacters(from: tokenEndSet) as NSString?
    } else if scanString("rgb") != nil {
      if scanUpToString(")") != nil {
        let str = self.string
        let afterRGB = str.index(after: currentIndex)
        if afterRGB <= str.endIndex {
          currentIndex = afterRGB
        }
        let startIdx = str.index(indexBefore, offsetBy: 0)
        colorName =
          String(str[startIdx..<currentIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
          as NSString
      }
    } else {
      // could be a plain html color name
      colorName = scanCharacters(from: .alphanumerics) as NSString?
    }

    var foundColor: DTColor?

    if let colorName = colorName as String? {
      foundColor = DTColorCreateWithHTMLName(colorName)
    }

    guard let resultColor = foundColor else {
      currentIndex = indexBefore
      return false
    }

    color?.pointee = resultColor
    name?.pointee = colorName

    return true
  }
}

// MARK: - Private helper to call stringByReplacingHTMLEntities on String

extension String {
  fileprivate func stringByReplacingHTMLEntities() -> String {
    return (self as NSString).stringByReplacingHTMLEntities()
  }
}
