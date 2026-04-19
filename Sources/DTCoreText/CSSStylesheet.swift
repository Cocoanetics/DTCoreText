import Foundation
import os

/// A single parsed CSS rule — a map from property name (e.g. `color`, `font-size`) to its
/// value. Values are `Any` because the CSS parser may produce either a plain `String` or
/// an array of strings (for properties like `font-family` that take comma-separated lists).
public typealias CSSStyleRule = [String: Any]

/// Represents a CSS style sheet used for specifying formatting for certain CSS selectors.
/// It supports matching styles by class, by id or by tag name.
@objc(DTCSSStylesheet)
open class CSSStylesheet: NSObject, NSCopying {

  /// Parsed style rules keyed by CSS selector. Pure Swift storage — no Cocoa bridging
  /// in the hot path, so concurrent readers of the shared default stylesheet don't go
  /// through `_SwiftDeferredNSDictionary` wrappers that previously caused tagged-pointer
  /// type-confusion crashes in `mergeStylesheet` under test parallelism.
  private var stylesBySelector: [String: CSSStyleRule] = [:]
  private var orderedSelectorWeights: [String: Int] = [:]
  private var orderedSelectorsStorage: [String] = []

  /// Serializes concurrent access to this stylesheet's stored Swift collections.
  ///
  /// The shared default stylesheet (`defaultStyleSheet()`) is copied concurrently by
  /// multiple builder actors during test parallelism. Even though reads of an immutable
  /// Swift `Dictionary` are meant to be safe, in practice Swift's COW backing buffer
  /// refcounting and hash-table traversal from multiple threads at once can produce
  /// hard-to-diagnose segfaults. Serializing the read snapshot in `mergeStylesheet`
  /// (and matching the write side in `addStyles`) eliminates the window entirely.
  /// The lock is uncontended in normal use — only builder-setup copies of the default
  /// stylesheet take it, and those happen once per parse.
  private let _accessLock = OSAllocatedUnfairLock()

  // MARK: - Creating Stylesheets

  /// Lazily-initialized default stylesheet loaded from `default.css`.
  ///
  /// Initialization runs exactly once and is published with a release barrier via
  /// Swift's `static let` lowering (`swift_once`). That guarantees any thread that
  /// observes a non-nil `_defaultStylesheet` also observes every write performed
  /// by the initializer — fixing a publication race on ARM's weak memory model
  /// where concurrent first-time callers could see a half-constructed stylesheet
  /// whose `stylesBySelector` hadn't finished populating, leading to
  /// type-confusion crashes inside `mergeStylesheet`.
  nonisolated(unsafe) private static let _defaultStylesheet: CSSStylesheet = {
    #if SWIFT_PACKAGE
      let path = Bundle.module.path(forResource: "default", ofType: "css")
    #else
      var path = Bundle(for: CSSStylesheet.self).path(forResource: "default", ofType: "css")

      // Older integrations may place default.css into a separate Resources bundle.
      if path == nil {
        let resourcesBundlePath = Bundle(for: CSSStylesheet.self).path(
          forResource: "Resources", ofType: "bundle")
        if let resourcesBundlePath = resourcesBundlePath {
          let resourcesBundle = Bundle(path: resourcesBundlePath)
          path = resourcesBundle?.path(forResource: "default", ofType: "css")
        }
      }
    #endif

    assert(path != nil, "Missing default.css")

    if let path = path, let cssString = try? String(contentsOfFile: path, encoding: .utf8) {
      return CSSStylesheet(styleBlock: cssString)
    }
    return CSSStylesheet(styleBlock: "")
  }()

  /// Returns the shared default stylesheet loaded from `default.css`.
  @objc public class func defaultStyleSheet() -> CSSStylesheet {
    return _defaultStylesheet
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
    return stylesBySelector.description
  }

  // MARK: - Working with Style Blocks

  func uncompressShorthands(_ styles: inout CSSStyleRule) {
    // list-style shorthand
    if let shortHand = (styles["list-style"] as? String)?.lowercased() {
      styles.removeValue(forKey: "list-style")

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
          if scanner.scanCSSURL() != nil {
            styles["list-style-image"] = oneComponent
            continue
          }
        }

        if !typeWasSet {
          if DTTextList.isValidListStyleTypeString(oneComponent) {
            styles["list-style-type"] = oneComponent
            typeWasSet = true
            continue
          }
        }

        if !positionWasSet {
          if DTTextList.isValidListStylePositionString(oneComponent) {
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

      styles.removeValue(forKey: "font")

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

      styles.removeValue(forKey: "margin")
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

      styles.removeValue(forKey: "padding")
    }

    // background shorthand
    if let shortHand = styles["background"] as? String {
      styles.removeValue(forKey: "background")

      let tokenDelimiters = CharacterSet.whitespacesAndNewlines
      let trimmedString = shortHand.trimmingCharacters(in: tokenDelimiters)
      let scanner = Scanner(string: trimmedString)

      while !scanner.isAtEnd {
        if let result = scanner.scanHTMLColor() {
          styles["background-color"] = result.name
          break
        }
        _ = scanner.scanUpToCharacters(from: tokenDelimiters)
      }
    }
  }

  private func addStyleRule(_ rule: String, withSelector selectors: String) {
    let split = selectors.components(separatedBy: ",")

    for selector in split {
      var cleanSelector = selector.trimmingCharacters(in: .whitespacesAndNewlines)

      var ruleDictionary: CSSStyleRule = rule.dictionaryOfCSSStyles()

      // remove !important, we're ignoring these
      for oneKey in Array(ruleDictionary.keys) {
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
      uncompressShorthands(&ruleDictionary)

      // check if there is a pseudo selector
      if let colonRange = cleanSelector.range(of: ":") {
        let pseudoSelector = String(
          cleanSelector[cleanSelector.index(after: colonRange.lowerBound)...])
        cleanSelector = String(cleanSelector[cleanSelector.startIndex..<colonRange.lowerBound])

        // prefix all rules with the pseudo-selector
        var prefixed: CSSStyleRule = [:]
        for (k, v) in ruleDictionary {
          prefixed["\(pseudoSelector):\(k)"] = v
        }
        ruleDictionary = prefixed
      }

      if let existingRulesForSelector = stylesBySelector[cleanSelector] {
        var merged = existingRulesForSelector
        for (k, v) in ruleDictionary {
          merged[k] = v
        }
        addStyles(merged, withSelector: cleanSelector)
      } else {
        addStyles(ruleDictionary, withSelector: cleanSelector)
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
          addStyleRule(rule, withSelector: selector)
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
  ///
  /// Reads the source's Swift storage directly (same-file `private` access allows it) and
  /// merges via Swift value-type dictionaries. No Cocoa bridging, no `_SwiftDeferredNSDictionary`
  /// wrappers — so concurrent callers copying the shared default stylesheet don't race on
  /// lazy-bridged views of the same backing storage. Swift dictionaries with value semantics
  /// are safe for concurrent reads when not mutated.
  @objc open func mergeStylesheet(_ stylesheet: CSSStylesheet) {
    // Snapshot the source under its access lock. This decouples us from any concurrent
    // reader/writer and gives us pure Swift value-type copies we can iterate freely.
    let (selectorsSnapshot, stylesSnapshot) = stylesheet._lockedSnapshot()

    for key in selectorsSnapshot {
      guard let stylesToMerge = stylesSnapshot[key] else { continue }

      if var existingStyles = stylesBySelector[key] {
        for (k, v) in stylesToMerge {
          existingStyles[k] = v
        }
        addStyles(existingStyles, withSelector: key)
      } else {
        addStyles(stylesToMerge, withSelector: key)
      }
    }
  }

  private func addStyles(_ styles: CSSStyleRule, withSelector selector: String) {
    _accessLock.lock()
    defer { _accessLock.unlock() }
    stylesBySelector[selector] = styles

    if !orderedSelectorsStorage.contains(selector) {
      orderedSelectorsStorage.append(selector)
      orderedSelectorWeights[selector] = weightForSelector(selector)
    }
  }

  /// Returns a point-in-time snapshot of the selectors and styles under the access lock.
  /// Paired with `addStyles`'s write lock so readers never see a torn state.
  private func _lockedSnapshot() -> (selectors: [String], styles: [String: CSSStyleRule]) {
    _accessLock.lock()
    defer { _accessLock.unlock() }
    return (orderedSelectorsStorage, stylesBySelector)
  }

  // MARK: - Accessing Style Information

  /// Computes the merged CSS style for a given element, together with the set of selectors
  /// that contributed to the match.
  ///
  /// Pure-Swift surface. Returns `nil` for `styles` when no rules match (the `matched`
  /// set will also be empty in that case).
  public func mergedStyles(for element: HTMLElement, ignoreInlineStyle: Bool) -> (
    styles: CSSStyleRule?, matched: Set<String>
  ) {
    var merged: CSSStyleRule = [:]
    var matchedSelectorSet = Set<String>()

    // Get based on element tag name
    if let byTagName = stylesBySelector[element.name] {
      for (k, v) in byTagName { merged[k] = v }
    }

    // Get based on class(es)
    let attrs = element.attributes
    let classString = attrs?["class"]
    let classes = classString?.components(separatedBy: " ") ?? []

    // Cascaded selectors with more than one part are sorted by specificity
    let matchingCascading = self.matchingComplexCascadingSelectors(for: element).sorted {
      sel1, sel2 in
      var weight1 = orderedSelectorWeights[sel1] ?? 0
      var weight2 = orderedSelectorWeights[sel2] ?? 0
      if weight1 == weight2 {
        weight1 += orderedSelectorsStorage.firstIndex(of: sel1) ?? 0
        weight2 += orderedSelectorsStorage.firstIndex(of: sel2) ?? 0
      }
      return weight1 < weight2  // ascending — so more specific wins via later merge
    }

    // Apply complex cascading selectors first, then most specific
    for sel in matchingCascading {
      if let byCascadingSelector = stylesBySelector[sel] {
        for (k, v) in byCascadingSelector { merged[k] = v }
        matchedSelectorSet.insert(sel)
      }
    }

    // Apply the parameter element's classes last
    for className in classes {
      let classRule = ".\(className)"
      if let byClass = stylesBySelector[classRule] {
        for (k, v) in byClass { merged[k] = v }
        matchedSelectorSet.insert(className)
      }

      let classAndTagRule = "\(element.name).\(className)"
      if let byClassAndName = stylesBySelector[classAndTagRule] {
        for (k, v) in byClassAndName { merged[k] = v }
        matchedSelectorSet.insert(classAndTagRule)
      }
    }

    // Get based on id
    if let elementId = attrs?["id"] {
      let idRule = "#\(elementId)"
      if let byID = stylesBySelector[idRule] {
        for (k, v) in byID { merged[k] = v }
        matchedSelectorSet.insert(idRule)
      }
    }

    if !ignoreInlineStyle {
      if let styleString = attrs?["style"], !styleString.isEmpty {
        var localStyles: CSSStyleRule = styleString.dictionaryOfCSSStyles()
        uncompressShorthands(&localStyles)
        for (k, v) in localStyles { merged[k] = v }
      }
    }

    return (merged.isEmpty ? nil : merged, matchedSelectorSet)
  }

  /// Returns a dictionary of the styles of the receiver.
  ///
  /// This is a one-shot bridging wrapper for the legacy `@objc` surface — internally,
  /// DTCoreText uses pure Swift access to `stylesBySelector`. Each call constructs a
  /// fresh `NSDictionary` with independent storage, so the returned value is not a
  /// lazy wrapper over the receiver's Swift storage and can be consumed safely.
  @objc open func styles() -> NSDictionary {
    return NSDictionary(dictionary: stylesBySelector)
  }

  /// Returns an ordered (by declaration) set of the selectors for all of the styles.
  ///
  /// One-shot bridging wrapper; see `styles()` for the rationale.
  @objc open func orderedSelectors() -> NSArray {
    return NSArray(array: orderedSelectorsStorage)
  }

  // MARK: - Complex Cascading Selectors

  private func matchingComplexCascadingSelectors(for element: HTMLElement) -> [String] {
    var matchedSelectors: [String] = []

    for selectorStr in orderedSelectorsStorage {

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
              let currentElementId = currentElement.attributes?["id"]
              if let currentElementId = currentElementId,
                String(selectorPart.dropFirst()) == currentElementId
              {
                matched = true
                break
              }
            } else if selectorPart.hasPrefix(".") {
              let currentElementClassesString = currentElement.attributes?["class"]
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
          matchedSelectors.append(selectorStr)
        }
      }
    }

    return matchedSelectors
  }

  // This computes the specificity for a given selector
  func weightForSelector(_ selector: String) -> Int {
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
