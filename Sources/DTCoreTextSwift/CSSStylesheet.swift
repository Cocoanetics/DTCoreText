import Foundation

/// Represents a CSS style sheet used for specifying formatting for certain CSS selectors.
/// It supports matching styles by class, by id or by tag name.
@objc(DTCSSStylesheet)
open class CSSStylesheet: NSObject, NSCopying {

  private var _styles = NSMutableDictionary()
  private var _orderedSelectorWeights = NSMutableDictionary()
  private var _orderedSelectors = NSMutableArray()

  // MARK: - Creating Stylesheets

  nonisolated(unsafe) private static var _defaultStylesheet: CSSStylesheet?

  /// Creates the default stylesheet loaded from default.css.
  @objc public class func defaultStyleSheet() -> CSSStylesheet {
    if let existing = _defaultStylesheet {
      return existing
    }

    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    if _defaultStylesheet == nil {
      #if SWIFT_PACKAGE
        let path = Bundle.module.path(forResource: "default", ofType: "css")
      #else
        var path = Bundle(for: self).path(forResource: "default", ofType: "css")

        // Older integrations may place default.css into a separate Resources bundle.
        if path == nil {
          let resourcesBundlePath = Bundle(for: self).path(
            forResource: "Resources", ofType: "bundle")
          if let resourcesBundlePath = resourcesBundlePath {
            let resourcesBundle = Bundle(path: resourcesBundlePath)
            path = resourcesBundle?.path(forResource: "default", ofType: "css")
          }
        }
      #endif

      assert(path != nil, "Missing default.css")

      if let path = path {
        let cssString = try? String(contentsOfFile: path, encoding: .utf8)
        _defaultStylesheet = CSSStylesheet(styleBlock: cssString ?? "")
      }
    }

    return _defaultStylesheet!
  }

  /// Creates a stylesheet with a given style block.
  @objc public init(styleBlock css: String?) {
    super.init()

    if let css = css {
      parseStyleBlock(css)
    }
  }

  /// Creates a stylesheet from another stylesheet.
  @objc public init(stylesheet: CSSStylesheet) {
    super.init()
    mergeStylesheet(stylesheet)
  }

  open override var description: String {
    return _styles.description
  }

  // MARK: - Working with Style Blocks

  func _uncompressShorthands(_ styles: NSMutableDictionary) {
    // list-style shorthand
    if let shortHand = (styles["list-style"] as? String)?.lowercased() {
      styles.removeObject(forKey: "list-style")

      if shortHand == "inherit" {
        styles["list-style-type"] = "inherit"
        styles["list-style-position"] = "inherit"
        return
      }

      let components = shortHand.components(separatedBy: .whitespaces)

      var typeWasSet = false
      var positionWasSet = false

      for oneComponent in components {
        if oneComponent.hasPrefix("url") {
          let scanner = Scanner(string: oneComponent)
          if scanner.scanCSSURL(nil) {
            styles["list-style-image"] = oneComponent
            continue
          }
        }

        if !typeWasSet {
          let listStyleType = CSSListStyle.listStyleType(from: oneComponent)
          if listStyleType != .invalid {
            styles["list-style-type"] = oneComponent
            typeWasSet = true
            continue
          }
        }

        if !positionWasSet {
          let listStylePosition = CSSListStyle.listStylePosition(from: oneComponent)
          if listStylePosition != .invalid {
            styles["list-style-position"] = oneComponent
            positionWasSet = true
            continue
          }
        }
      }
    }

    // font shorthand
    if let shortHand = styles["font"] as? String {
      var fontStyle = "normal"
      let validFontStyles = ["italic", "oblique"]

      var fontVariant = "normal"
      let validFontVariants = ["small-caps"]
      var fontVariantSet = false

      var fontWeight = "normal"
      let validFontWeights = [
        "bold", "bolder", "lighter", "100", "200", "300", "400", "500", "600", "700", "800", "900",
      ]
      var fontWeightSet = false

      var fontSize = "normal"
      let validFontSizes = [
        "xx-small", "x-small", "small", "medium", "large", "x-large", "xx-large", "larger",
        "smaller",
      ]
      var fontSizeSet = false

      let suffixesToIgnore = [
        "caption", "icon", "menu", "message-box", "small-caption", "status-bar", "inherit",
      ]

      var lineHeight = "normal"

      let fontFamily = NSMutableString()

      let components = shortHand.components(separatedBy: .whitespaces)

      for oneComponent in components {
        // try font size keywords
        if validFontSizes.contains(oneComponent) {
          fontSize = oneComponent
          fontSizeSet = true
          continue
        }

        if let slashIndex = oneComponent.range(of: "/") {
          // font-size / line-height
          fontSize = String(oneComponent[oneComponent.startIndex..<slashIndex.lowerBound])
          fontSizeSet = true
          lineHeight = String(oneComponent[slashIndex.upperBound...])
          continue
        } else {
          // length
          if oneComponent.hasSuffix("%") || oneComponent.hasSuffix("em")
            || oneComponent.hasSuffix("px") || oneComponent.hasSuffix("pt")
          {
            fontSize = oneComponent
            fontSizeSet = true
            continue
          }
        }

        if fontSizeSet {
          if suffixesToIgnore.contains(oneComponent) {
            break
          }

          // assume that this is part of font family
          if fontFamily.length > 0 {
            fontFamily.append(" ")
          }
          fontFamily.append(oneComponent)
        } else {
          if !fontWeightSet && validFontStyles.contains(oneComponent) {
            fontStyle = oneComponent
          } else if !fontVariantSet && validFontVariants.contains(oneComponent) {
            fontVariant = oneComponent
            fontVariantSet = true
          } else if !fontWeightSet && validFontWeights.contains(oneComponent) {
            fontWeight = oneComponent
            fontWeightSet = true
          }
        }
      }

      styles.removeObject(forKey: "font")

      // size and family are mandatory
      if fontSize.count > 0 && fontFamily.length > 0 {
        styles["font-style"] = fontStyle
        styles["font-weight"] = fontWeight
        styles["font-variant"] = fontVariant
        styles["font-size"] = fontSize
        styles["line-height"] = lineHeight
        styles["font-family"] = fontFamily as String
      }
    }

    // margin shorthand
    if let shortHand = styles["margin"] as? String {
      let parts = shortHand.components(separatedBy: " ")
      var top: String
      var right: String
      var bottom: String
      var left: String

      switch parts.count {
      case 4:
        top = parts[0]
        right = parts[1]
        bottom = parts[2]
        left = parts[3]
      case 3:
        top = parts[0]
        right = parts[1]
        bottom = parts[2]
        left = parts[1]
      case 2:
        top = parts[0]
        right = parts[1]
        bottom = parts[0]
        left = parts[1]
      default:
        top = parts[0]
        right = parts[0]
        bottom = parts[0]
        left = parts[0]
      }

      if styles["margin-top"] == nil { styles["margin-top"] = top }
      if styles["margin-right"] == nil { styles["margin-right"] = right }
      if styles["margin-bottom"] == nil { styles["margin-bottom"] = bottom }
      if styles["margin-left"] == nil { styles["margin-left"] = left }

      styles.removeObject(forKey: "margin")
    }

    // padding shorthand
    if let shortHand = styles["padding"] as? String {
      let parts = shortHand.components(separatedBy: " ")
      var top: String
      var right: String
      var bottom: String
      var left: String

      switch parts.count {
      case 4:
        top = parts[0]
        right = parts[1]
        bottom = parts[2]
        left = parts[3]
      case 3:
        top = parts[0]
        right = parts[1]
        bottom = parts[2]
        left = parts[1]
      case 2:
        top = parts[0]
        right = parts[1]
        bottom = parts[0]
        left = parts[1]
      default:
        top = parts[0]
        right = parts[0]
        bottom = parts[0]
        left = parts[0]
      }

      if styles["padding-top"] == nil { styles["padding-top"] = top }
      if styles["padding-right"] == nil { styles["padding-right"] = right }
      if styles["padding-bottom"] == nil { styles["padding-bottom"] = bottom }
      if styles["padding-left"] == nil { styles["padding-left"] = left }

      styles.removeObject(forKey: "padding")
    }

    // background shorthand
    if let shortHand = styles["background"] as? String {
      styles.removeObject(forKey: "background")

      let tokenDelimiters = CharacterSet.whitespacesAndNewlines
      let trimmedString = shortHand.trimmingCharacters(in: tokenDelimiters)
      let scanner = Scanner(string: trimmedString)

      while !scanner.isAtEnd {
        var colorName: NSString?
        if scanner.scanHTMLColor(nil, htmlName: &colorName) {
          if let colorName = colorName {
            styles["background-color"] = colorName as String
          }
          break
        }
        _ = scanner.scanUpToCharacters(from: tokenDelimiters)
      }
    }
  }

  private func _addStyleRule(_ rule: String, withSelector selectors: String) {
    let split = selectors.components(separatedBy: ",")

    for selector in split {
      var cleanSelector = selector.trimmingCharacters(in: .whitespacesAndNewlines)

      let ruleDictionary = NSMutableDictionary(
        dictionary: (rule as NSString).dictionaryOfCSSStyles())

      // remove !important, we're ignoring these
      for oneKey in ruleDictionary.allKeys.compactMap({ $0 as? String }) {
        if let value = ruleDictionary[oneKey] as? String {
          if let range = value.range(of: "!important", options: .caseInsensitive) {
            var cleaned = value
            cleaned.removeSubrange(range)
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            ruleDictionary[oneKey] = cleaned
          }
        } else if let value = ruleDictionary[oneKey] as? [String] {
          var newVal = value
          for i in 0..<newVal.count {
            if let range = newVal[i].range(of: "!important", options: .caseInsensitive) {
              var s = newVal[i]
              s.removeSubrange(range)
              s = s.trimmingCharacters(in: .whitespacesAndNewlines)
              newVal[i] = s
            }
          }
          ruleDictionary[oneKey] = newVal
        }
      }

      // need to uncompress because otherwise we might get shorthands and non-shorthands together
      _uncompressShorthands(ruleDictionary)

      // check if there is a pseudo selector
      if let colonRange = cleanSelector.range(of: ":") {
        let pseudoSelector = String(
          cleanSelector[cleanSelector.index(after: colonRange.lowerBound)...])
        cleanSelector = String(cleanSelector[cleanSelector.startIndex..<colonRange.lowerBound])

        // prefix all rules with the pseudo-selector
        let keys = ruleDictionary.allKeys.compactMap { $0 as? String }
        for oneRuleKey in keys {
          let value = ruleDictionary[oneRuleKey]!
          let prefixedKey = "\(pseudoSelector):\(oneRuleKey)"
          ruleDictionary[prefixedKey] = value
          ruleDictionary.removeObject(forKey: oneRuleKey)
        }
      }

      if let existingRulesForSelector = _styles[cleanSelector] as? NSDictionary {
        let tmpDict = existingRulesForSelector.mutableCopy() as! NSMutableDictionary
        tmpDict.addEntries(from: ruleDictionary as! [AnyHashable: Any])
        _addStyles(tmpDict, withSelector: cleanSelector)
      } else {
        _addStyles(ruleDictionary, withSelector: cleanSelector)
      }
    }
  }

  /// Parses a style block string and adds the found style rules to the receiver.
  @objc open func parseStyleBlock(_ css: String) {
    var braceMarker = css.startIndex
    var braceLevel = 0
    var selector = ""

    var i = css.startIndex
    while i < css.endIndex {
      let c = css[i]

      if c == "/" {
        let nextIndex = css.index(after: i)
        if nextIndex < css.endIndex && css[nextIndex] == "*" {
          // skip comment until closing /
          var j = css.index(after: nextIndex)
          while j < css.endIndex {
            if css[j] == "/" {
              break
            }
            j = css.index(after: j)
          }

          if j < css.endIndex {
            braceMarker = css.index(after: j)
            i = j
            i = css.index(after: i)
            continue
          } else {
            return
          }
        }
      }

      if c == "{" {
        if braceLevel == 0 {
          selector = String(css[braceMarker..<i])
          let selectorParts = selector.components(separatedBy: " ")
          let cleanParts = selectorParts.filter { !$0.isEmpty }
          selector = cleanParts.joined(separator: " ")
          braceMarker = css.index(after: i)
        }
        braceLevel += 1
      } else if c == "}" {
        if braceLevel == 1 {
          let rule = String(css[braceMarker..<i])
          _addStyleRule(rule, withSelector: selector)
          braceMarker = css.index(after: i)
        } else if braceLevel < 1 {
          braceMarker = css.index(after: braceMarker)
        }

        braceLevel = max(braceLevel - 1, 0)
      }

      i = css.index(after: i)
    }
  }

  /// Merges styles from given stylesheet into the receiver.
  @objc open func mergeStylesheet(_ stylesheet: CSSStylesheet) {
    let otherKeys = stylesheet.orderedSelectors()

    for oneKey in otherKeys {
      guard let key = oneKey as? String else { continue }
      let existingStyles = _styles[key] as? NSDictionary
      let stylesToMerge = stylesheet.styles()[key] as? NSDictionary

      if let existingStyles = existingStyles, let stylesToMerge = stylesToMerge {
        let mutableStyles = existingStyles.mutableCopy() as! NSMutableDictionary
        mutableStyles.addEntries(from: stylesToMerge as! [AnyHashable: Any])
        _addStyles(mutableStyles, withSelector: key)
      } else if let stylesToMerge = stylesToMerge {
        _addStyles(stylesToMerge, withSelector: key)
      }
    }
  }

  private func _addStyles(_ styles: NSDictionary, withSelector selector: String) {
    // Always copy to avoid sharing references with other stylesheets (e.g. the default)
    _styles[selector] = styles.copy() as! NSDictionary

    if !_orderedSelectors.contains(selector) {
      _orderedSelectors.add(selector)
      _orderedSelectorWeights[selector] = NSNumber(value: _weightForSelector(selector))
    }
  }

  // MARK: - Accessing Style Information

  /// Returns a dictionary that contains the merged style for a given element.
  @objc open func mergedStyleDictionary(
    for element: HTMLElement, matchedSelectors: AutoreleasingUnsafeMutablePointer<NSSet?>?,
    ignoreInlineStyle: Bool
  ) -> NSDictionary? {
    let tmpDict = NSMutableDictionary()

    // Get based on element
    if let byTagName = _styles[element.name] as? NSDictionary {
      tmpDict.addEntries(from: byTagName as! [AnyHashable: Any])
    }

    // Get based on class(es)
    let classString = (element.attributes as? [String: Any])?["class"] as? String
    let classes = classString?.components(separatedBy: " ") ?? []

    // Cascaded selectors with more than one part are sorted by specificity
    let matchingCascadingSelectors = self.matchingComplexCascadingSelectors(for: element)
    matchingCascadingSelectors.sort { s1, s2 in
      guard let sel1 = s1 as? String, let sel2 = s2 as? String else { return .orderedSame }
      var weight1 = (_orderedSelectorWeights[sel1] as? NSNumber)?.intValue ?? 0
      var weight2 = (_orderedSelectorWeights[sel2] as? NSNumber)?.intValue ?? 0

      if weight1 == weight2 {
        weight1 += _orderedSelectors.index(of: sel1)
        weight2 += _orderedSelectors.index(of: sel2)
      }

      if weight1 > weight2 { return .orderedDescending }
      if weight1 < weight2 { return .orderedAscending }
      return .orderedSame
    }

    var tmpMatchedSelectors: NSMutableSet? = nil
    if matchedSelectors != nil {
      tmpMatchedSelectors = NSMutableSet()
    }

    // Apply complex cascading selectors first, then apply most specific selectors
    for cascadingSelector in matchingCascadingSelectors {
      guard let sel = cascadingSelector as? String else { continue }
      if let byCascadingSelector = _styles[sel] as? NSDictionary {
        tmpDict.addEntries(from: byCascadingSelector as! [AnyHashable: Any])
        tmpMatchedSelectors?.add(sel)
      }
    }

    // Applied the parameter element's classes last
    for className in classes {
      let classRule = ".\(className)"
      if let byClass = _styles[classRule] as? NSDictionary {
        tmpDict.addEntries(from: byClass as! [AnyHashable: Any])
        tmpMatchedSelectors?.add(className)
      }

      let classAndTagRule = "\(element.name).\(className)"
      if let byClassAndName = _styles[classAndTagRule] as? NSDictionary {
        tmpDict.addEntries(from: byClassAndName as! [AnyHashable: Any])
        tmpMatchedSelectors?.add(classAndTagRule)
      }
    }

    // Get based on id
    if let elementId = (element.attributes as? [String: Any])?["id"] as? String {
      let idRule = "#\(elementId)"
      if let byID = _styles[idRule] as? NSDictionary {
        tmpDict.addEntries(from: byID as! [AnyHashable: Any])
        tmpMatchedSelectors?.add(idRule)
      }
    }

    if !ignoreInlineStyle {
      // Get tag's local style attribute
      if let styleString = (element.attributes as? [String: Any])?["style"] as? String,
        !styleString.isEmpty
      {
        let localStyles = NSMutableDictionary(
          dictionary: (styleString as NSString).dictionaryOfCSSStyles())

        // need to uncompress because otherwise we might get shorthands and non-shorthands together
        _uncompressShorthands(localStyles)

        tmpDict.addEntries(from: localStyles as! [AnyHashable: Any])
      }
    }

    if tmpDict.count > 0 {
      if let tmpMatchedSelectors = tmpMatchedSelectors, tmpMatchedSelectors.count > 0 {
        matchedSelectors?.pointee = tmpMatchedSelectors.copy() as? NSSet
      }
      return tmpDict
    }

    return nil
  }

  /// Returns a dictionary of the styles of the receiver.
  @objc open func styles() -> NSDictionary {
    return _styles
  }

  /// Returns an ordered (by declaration) set of the selectors for all of the styles.
  @objc open func orderedSelectors() -> NSArray {
    return _orderedSelectors
  }

  // MARK: - Complex Cascading Selectors

  private func matchingComplexCascadingSelectors(for element: HTMLElement) -> NSMutableArray {
    let matchedSelectors = NSMutableArray()

    for selector in _orderedSelectors {
      guard let selectorStr = selector as? String else { continue }

      // We only process the selector if it has more than 1 part
      guard selectorStr.contains(" ") else { continue }

      let selectorParts = selectorStr.components(separatedBy: " ")

      if selectorParts.count < 2 { continue }

      var nextElement: HTMLElement? = element

      // Walking up the hierarchy so start at the right side of the selector and work to the left
      for j in stride(from: selectorParts.count - 1, through: 0, by: -1) {
        let selectorPart = selectorParts[j]
        var matched = false

        if !selectorPart.isEmpty {
          while let currentElement = nextElement {
            nextElement = currentElement.parentElement()

            if selectorPart.hasPrefix("#") {
              let currentElementId = (currentElement.attributes as? [String: Any])?["id"] as? String
              if let currentElementId = currentElementId,
                String(selectorPart.dropFirst()) == currentElementId
              {
                matched = true
                break
              }
            } else if selectorPart.hasPrefix(".") {
              let currentElementClassesString =
                (currentElement.attributes as? [String: Any])?["class"] as? String
              let currentElementClasses =
                currentElementClassesString?.components(separatedBy: " ") ?? []

              for currentElementClass in currentElementClasses {
                if currentElementClass == String(selectorPart.dropFirst()) {
                  matched = true
                  break
                }
              }

              if matched { break }
            } else if selectorPart == currentElement.name && selectorParts.count > 1 {
              matched = true
              break
            }

            // break if the right most portion of the selector doesn't match the target element
            if !matched && currentElement === element {
              break
            }
          }
        }

        if !matched {
          break
        }

        // Only match if we really are on the last part of the selector and all other parts have matched
        if j == 0 && matched && !matchedSelectors.contains(selectorStr) {
          matchedSelectors.add(selectorStr)
        }
      }
    }

    return matchedSelectors
  }

  // This computes the specificity for a given selector
  func _weightForSelector(_ selector: String) -> Int {
    if selector.isEmpty { return 0 }

    var weight = 0

    let selectorParts = selector.components(separatedBy: " ")
    for selectorPart in selectorParts {
      if selectorPart.isEmpty { continue }

      if selectorPart.hasPrefix("#") {
        weight += 100
      } else if selectorPart.hasPrefix(".") {
        weight += 10
      } else {
        weight += 1
      }
    }

    return weight
  }

  // MARK: - NSCopying

  open func copy(with zone: NSZone? = nil) -> Any {
    return CSSStylesheet(stylesheet: self)
  }
}
