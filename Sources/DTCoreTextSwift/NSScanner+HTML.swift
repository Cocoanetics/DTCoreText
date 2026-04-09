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
    @objc public func scanCSSAttribute(_ name: AutoreleasingUnsafeMutablePointer<NSString?>?, value: AutoreleasingUnsafeMutablePointer<AnyObject?>?) -> Bool {
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
        var scannedName: NSString?
        guard scanCharacters(from: cssStyleAttributeNameCharacterSet, into: &scannedName) else {
            return false
        }
        attrName = scannedName

        // skip whitespace
        scanCharacters(from: whiteCharacterSet, into: nil)

        // expect :
        guard scanString(":", into: nil) else {
            currentIndex = initialScanLocation
            return false
        }

        // skip whitespace
        scanCharacters(from: whiteCharacterSet, into: nil)

        let results = NSMutableArray()
        var nextIterationAddsNewEntry = true

        while !isAtEnd && !scanString(";", into: nil) && !scanString("'';", into: nil) && !scanString("\"\";", into: nil) {
            // skip whitespace
            scanCharacters(from: whiteCharacterSet, into: nil)

            var quote: NSString?
            if scanCharacters(from: NSCharacterSet.dt_quoteCharacterSet, into: &quote), let quoteStr = quote as String? {
                var quotedValue: NSString?

                // attribute is quoted
                if !scanUpTo(quoteStr, into: &quotedValue) {
                    currentIndex = initialScanLocation
                    return false
                } else {
                    if let qv = quotedValue as String? {
                        if nextIterationAddsNewEntry {
                            results.add(qv)
                            nextIterationAddsNewEntry = false
                        } else {
                            let combined = "\(results.lastObject!) \(quoteStr)\(qv)\(quoteStr)"
                            results.removeLastObject()
                            results.add(combined)
                        }
                    }
                }

                // skip ending quote
                scanString(quoteStr, into: nil)
            } else {
                // attribute is not quoted
                var valueString: NSString?

                if scanString("rgb(", into: &valueString) {
                    if (valueString as String?) == "rgb(" {
                        var rgbContent: NSString?
                        scanUpTo(";", into: &rgbContent)
                        let formattedRGBString = "rgb(\(rgbContent ?? "")"

                        if nextIterationAddsNewEntry {
                            results.add(formattedRGBString)
                            nextIterationAddsNewEntry = false
                        } else {
                            let combined = "\(results.lastObject!) \(formattedRGBString)"
                            results.removeLastObject()
                            results.add(combined)
                        }
                    }
                } else if scanString(",", into: &valueString) {
                    var isStringOnlyCSSProperty = false

                    if (valueString as String?) != "," {
                        results.add((valueString as String?) ?? "")
                    } else if let name = attrName as String?,
                              (name == "font" ||
                               name.range(of: "color") != nil ||
                               name.range(of: "shadow") != nil ||
                               name.range(of: "background") != nil) {
                        let combined = "\(results.lastObject!)\(valueString!)"
                        results.removeLastObject()
                        results.add(combined)
                        isStringOnlyCSSProperty = true
                    }

                    if (valueString as String?) == "," && !isStringOnlyCSSProperty {
                        nextIterationAddsNewEntry = true
                    }
                } else if scanCharacters(from: nonWhiteCommaCharacterSet, into: &valueString) {
                    if let vs = valueString as String?, !vs.isEmpty && vs != "," {
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
            scanCharacters(from: whiteCharacterSet, into: nil)
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
        guard scanString("url(", into: nil) else {
            return false
        }

        let quoteCharacterSet = NSCharacterSet.dt_quoteCharacterSet
        var attrValue: NSString?

        var quote: NSString?
        if scanCharacters(from: quoteCharacterSet, into: &quote) {
            if let quoteStr = quote as String?, quoteStr.count == 1 {
                scanUpTo(quoteStr, into: &attrValue)
                scanString(quoteStr, into: nil)
            } else {
                // most likely e.g. href=""
                attrValue = "" as NSString
            }

            // decode HTML entities
            attrValue = (attrValue as String?)?.stringByReplacingHTMLEntities() as NSString? ?? attrValue
        } else {
            // non-quoted attribute, ends at )
            if scanUpTo(")", into: &attrValue) {
                attrValue = (attrValue as String?)?.stringByReplacingHTMLEntities() as NSString? ?? attrValue
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
    @objc public func scanHTMLColor(_ color: AutoreleasingUnsafeMutablePointer<DTColor?>?, htmlName name: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        let indexBefore = currentIndex

        var colorName: NSString?

        var tokenEndSet = CharacterSet.whitespacesAndNewlines
        tokenEndSet.insert(charactersIn: ",")

        if scanString("#", into: nil) {
            currentIndex = indexBefore
            scanUpToCharacters(from: tokenEndSet, into: &colorName)
        } else if scanString("rgb", into: nil) {
            if scanUpTo(")", into: nil) {
                let str = self.string
                let afterRGB = str.index(after: currentIndex)
                if afterRGB <= str.endIndex {
                    currentIndex = afterRGB
                }
                let startIdx = str.index(indexBefore, offsetBy: 0)
                colorName = String(str[startIdx..<currentIndex]).trimmingCharacters(in: .whitespacesAndNewlines) as NSString
            }
        } else {
            // could be a plain html color name
            scanCharacters(from: .alphanumerics, into: &colorName)
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

private extension String {
    func stringByReplacingHTMLEntities() -> String {
        return (self as NSString).stringByReplacingHTMLEntities()
    }
}
