//
//  NSString+CSS.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

import Foundation

// MARK: - Whitespace Check Helper (local)

private func isWhitespace(_ c: unichar) -> Bool {
    return c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0B || c == 0x0C || c == 0x0D || c == 0x85
}

/// Methods to make dealing with CSS strings easier.
extension NSString {

    /// Examine a string for all CSS styles that are applied to it and return a dictionary of those styles.
    @objc public func dictionaryOfCSSStyles() -> [String: Any] {
        let scanner = Scanner(string: self as String)

        var tmpDict = [String: Any]()

        autoreleasepool {
            var namePtr: NSString?
            var valuePtr: AnyObject?

            while scanner.scanCSSAttribute(&namePtr, value: &valuePtr) {
                if let name = namePtr as String?, let value = valuePtr {
                    tmpDict[name] = value
                }
            }
        }

        return tmpDict
    }

    /// Determines if the receiver contains a CSS length value.
    @objc public func isCSSLengthValue() -> Bool {
        let scanner = Scanner(string: self as String)

        if scanner.scanCharacters(from: NSCharacterSet.dt_cssLengthValueCharacterSet) == nil {
            return false
        }

        guard let unit = scanner.scanCharacters(from: NSCharacterSet.dt_cssLengthUnitCharacterSet) else {
            return true
        }

        if unit == "em" || unit == "px" || unit == "pt" {
            return true
        }

        return false
    }

    /// Calculates a pixel-based length from the receiver based on the current text size in pixels.
    @objc public func pixelSizeOfCSSMeasure(relativeToCurrentTextSize textSize: CGFloat, textScale: CGFloat) -> CGFloat {
        let stringLength = self.length
        guard stringLength > 0 else { return 0 }

        var characters = [unichar](repeating: 0, count: stringLength)
        self.getCharacters(&characters, range: NSRange(location: 0, length: stringLength))

        var value: CGFloat = 0
        var commaSeen = false
        var negative = false
        var digitsPastComma: UInt = 0
        var i = 0

        while i < stringLength {
            let ch = characters[i]

            if ch >= 0x30 && ch <= 0x39 { // '0'-'9'
                let digit = CGFloat(ch - 0x30)
                value *= 10.0
                value += digit

                if commaSeen {
                    digitsPastComma += 1
                }
            } else if ch == 0x2E { // '.'
                commaSeen = true
            } else if ch == 0x2D { // '-'
                negative = true
            } else {
                break
            }
            i += 1
        }

        if commaSeen {
            value /= pow(10.0, CGFloat(digitsPastComma))
        }

        // skip whitespace
        while i < stringLength && isWhitespace(characters[i]) {
            i += 1
        }

        if i < stringLength {
            let ch = characters[i]
            i += 1

            if ch == 0x25 { // '%'
                value *= textSize / 100.0
            } else if ch == 0x65 { // 'e'
                if i < stringLength && characters[i] == 0x6D { // 'm'
                    value *= textSize
                }
            } else if ch == 0x70 { // 'p'
                if i < stringLength {
                    if characters[i] == 0x78 { // 'x'
                        value *= textScale
                    } else if characters[i] == 0x74 { // 't'
                        value *= 1.3333
                        value *= textScale
                    }
                }
            }
        }

        if negative {
            value *= -1
        }

        return value
    }

    /// Decodes edge inset values from the CSS attribute string.
    @objc public func dtEdgeInsets(relativeToCurrentTextSize textSize: CGFloat, textScale: CGFloat) -> DTEdgeInsets {
        var edgeInsets = DTEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        if self.length > 0 {
            let parts = self.components(separatedBy: " ")

            if parts.count == 4 {
                edgeInsets.top = (parts[0] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.right = (parts[1] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.bottom = (parts[2] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.left = (parts[3] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
            } else if parts.count == 3 {
                edgeInsets.top = (parts[0] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.right = (parts[1] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.bottom = (parts[2] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.left = edgeInsets.right
            } else if parts.count == 2 {
                edgeInsets.top = (parts[0] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.right = (parts[1] as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets.bottom = edgeInsets.top
                edgeInsets.left = edgeInsets.right
            } else {
                let paddingAmount = self.pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: textScale)
                edgeInsets = DTEdgeInsets(top: paddingAmount, left: paddingAmount, bottom: paddingAmount, right: paddingAmount)
            }
        }

        return edgeInsets
    }

    /// Parse CSS shadow styles out of this string.
    @objc public func arrayOfCSSShadows(withCurrentTextSize textSize: CGFloat, currentColor color: DTColor?) -> [Any]? {
        let trimmedString = self.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedString == "none" {
            return nil
        }

        let scanner = Scanner(string: trimmedString)

        var tokenEndSet = CharacterSet.whitespacesAndNewlines
        tokenEndSet.insert(charactersIn: ",")

        var tmpArray = [[String: Any]]()

        while !scanner.isAtEnd {
            var shadowColor: DTColor?
            var colorPtr: DTColor?

            if scanner.scanHTMLColor(&colorPtr) {
                shadowColor = colorPtr

                // format: <color> <length> <length> <length>?
                if let offsetXString = scanner.scanUpToCharacters(from: tokenEndSet),
                   let offsetYString = scanner.scanUpToCharacters(from: tokenEndSet) {
                    // blur is optional
                    let blurString = scanner.scanUpToCharacters(from: tokenEndSet)

                    let offsetX = (offsetXString as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: 1.0)
                    let offsetY = (offsetYString as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: 1.0)
                    let offset = CGSize(width: offsetX, height: offsetY)
                    let blur = blurString != nil ? (blurString! as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: 1.0) : 0

                    #if os(iOS)
                    let offsetValue = NSValue(cgSize: offset)
                    #else
                    let offsetValue = NSValue(size: offset)
                    #endif

                    var shadowDict: [String: Any] = [
                        "Offset": offsetValue,
                        "Blur": NSNumber(value: Double(blur)),
                    ]
                    if let sc = shadowColor {
                        shadowDict["Color"] = sc
                    }
                    tmpArray.append(shadowDict)
                }
            } else {
                // format: <length> <length> <length>? <color>?
                if let offsetXString = scanner.scanUpToCharacters(from: tokenEndSet),
                   let offsetYString = scanner.scanUpToCharacters(from: tokenEndSet) {
                    // blur is optional
                    var blurString: String?
                    if !scanner.scanHTMLColor(&colorPtr) {
                        blurString = scanner.scanUpToCharacters(from: tokenEndSet)
                        if blurString != nil {
                            _ = scanner.scanHTMLColor(&colorPtr)
                        }
                    }
                    shadowColor = colorPtr

                    if shadowColor == nil {
                        shadowColor = color
                    }

                    let offsetX = (offsetXString as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: 1.0)
                    let offsetY = (offsetYString as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: 1.0)
                    let offset = CGSize(width: offsetX, height: offsetY)
                    let blur = blurString != nil ? (blurString! as NSString).pixelSizeOfCSSMeasure(relativeToCurrentTextSize: textSize, textScale: 1.0) : 0

                    #if os(iOS)
                    let offsetValue = NSValue(cgSize: offset)
                    #else
                    let offsetValue = NSValue(size: offset)
                    #endif

                    var shadowDict: [String: Any] = [
                        "Offset": offsetValue,
                        "Blur": NSNumber(value: Double(blur)),
                    ]
                    if let sc = shadowColor {
                        shadowDict["Color"] = sc
                    }
                    tmpArray.append(shadowDict)
                }
            }

            // now there should be a comma
            if scanner.scanString(",") == nil {
                break
            }
        }

        return tmpArray.isEmpty ? nil : tmpArray
    }

    /// Decodes a content attribute which might contain unicode sequences.
    @objc public func stringByDecodingCSSContentAttribute() -> String {
        let length = self.length
        guard length > 0 else { return "" }

        var characters = [unichar](repeating: 0, count: length)
        self.getCharacters(&characters, range: NSRange(location: 0, length: length))

        var final_ = [unichar](repeating: 0, count: length)
        var outChars = 0

        var inEscapedSequence = false
        var decodedChar: unichar = 0
        var escapedCharacterCount: UInt = 0

        for idx in 0..<length {
            let character = characters[idx]

            if inEscapedSequence && escapedCharacterCount < 4 {
                if character == 0x5C { // '\\'
                    final_[outChars] = 0x5C
                    outChars += 1
                    inEscapedSequence = false
                } else if (character >= 0x30 && character <= 0x39) || // 0-9
                          (character >= 0x41 && character <= 0x46) || // A-F
                          (character >= 0x61 && character <= 0x66) {  // a-f
                    decodedChar &*= 16

                    if character >= 0x30 && character <= 0x39 {
                        decodedChar &+= character &- 0x30
                    } else if character >= 0x41 && character <= 0x46 {
                        decodedChar &+= character &- 0x41 &+ 10
                    } else if character >= 0x61 && character <= 0x66 {
                        decodedChar &+= character &- 0x61 &+ 10
                    }

                    escapedCharacterCount += 1
                } else {
                    // illegal character following slash
                    final_[outChars] = 0x5C
                    outChars += 1
                    final_[outChars] = character
                    outChars += 1
                    inEscapedSequence = false
                }
            } else {
                if inEscapedSequence {
                    // output what we have decoded so far
                    final_[outChars] = decodedChar
                    outChars += 1
                }

                if character == 0x5C { // '\\'
                    decodedChar = 0
                    escapedCharacterCount = 0
                    inEscapedSequence = true
                } else {
                    inEscapedSequence = false
                    final_[outChars] = character
                    outChars += 1
                }
            }
        }

        // if string ended in escaped sequence we still need to output
        if inEscapedSequence {
            final_[outChars] = decodedChar
            outChars += 1
        }

        return String(utf16CodeUnits: final_, count: outChars)
    }
}
