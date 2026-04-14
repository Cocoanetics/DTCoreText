import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

import os

/// Central HTML element class. Has a factory method that creates specific subclasses
/// for known tags (e.g. BreakHTMLElement, AnchorHTMLElement, etc.).
open class HTMLElement: HTMLParserNode {

  public required init(name: String, attributes: [String: String]?) {
    super.init(name: name, attributes: attributes)
    // didSet doesn't fire during init, so manually decode size from attributes
    _updateSizeFromAttributes()
  }

  // MARK: - Exposed IVARs (for subclass access)

  internal var _fontDescriptor: CoreTextFontDescriptor?
  internal var _paragraphStyle: CoreTextParagraphStyle?
  internal var _textAttachment: TextAttachment?
  private var _textAttachmentAlignment: TextAttachmentVerticalAlignment = .baseline
  private var _link: URL?
  private var _anchorName: String?

  internal var _textColor: DTColor?
  internal var _backgroundColor: DTColor?

  private var _backgroundStrokeColor: DTColor?
  private var _backgroundStrokeWidth: CGFloat = 0
  private var _backgroundCornerRadius: CGFloat = 0

  private var _underlineStyle: CTUnderlineStyle = .init(rawValue: 0)
  private var _underlineColor: DTColor?

  private var _beforeContent: String?
  private var _linkGUID: String?

  internal var _strikeOut: Bool = false
  private var _superscriptStyle: Int = 0
  private var _headerLevel: Int = 0

  private var _shadows: [Any]?

  private var _displayStyle: DTHTMLElementDisplayStyle = .inline
  private var _floatStyle: DTHTMLElementFloatStyle = .none

  internal var _isColorInherited: Bool = false
  internal var _preserveNewlines: Bool = false
  internal var _containsAppleConvertedSpace: Bool = false

  private var _fontVariant: DTHTMLElementFontVariant = .normal

  internal var _textScale: CGFloat = 0
  internal var _size: CGSize = .zero

  private var _styles: [String: Any]?
  private var _didOutput: Bool = false

  internal var _margins: UIEdgeInsets = .zero
  internal var _padding: UIEdgeInsets = .zero

  internal var _listIndent: CGFloat = 0
  private var _pTextIndent: CGFloat = 0
  private var _letterSpacing: CGFloat = 0

  private var _shouldProcessCustomHTMLAttributes: Bool = false

  private var _currentTextSize: CGFloat = 0

  private var _CSSClassNamesToIgnoreForCustomAttributes: Set<String>?

  // MARK: - Class initialization

  /// Thread-safe registry of tag-name → HTMLElement subclass mappings.
  private static let _elementClasses = OSAllocatedUnfairLock<[String: AnyClass]>(
    initialState: [
      "a": AnchorHTMLElement.self,
      "br": BreakHTMLElement.self,
      "hr": HorizontalRuleHTMLElement.self,
      "li": ListItemHTMLElement.self,
      "style": StylesheetHTMLElement.self,
      "img": TextAttachmentHTMLElement.self,
      "object": TextAttachmentHTMLElement.self,
      "video": TextAttachmentHTMLElement.self,
      "iframe": TextAttachmentHTMLElement.self,
    ])

  // MARK: - Creating HTML Elements

  /// Factory method that creates the appropriate element subclass for the given
  /// tag name, and installs attributes and creation-time options.
  public class func element(
    name: String, attributes: [String: String]?, options: [String: Any]?
  ) -> HTMLElement {
    let lowercaseName = name.lowercased()

    // look for specialized class
    var cls: AnyClass? = _elementClasses.withLock { $0[lowercaseName] }

    if cls == nil {
      // see if this is a custom attachment class
      if TextAttachment.registeredClass(forTagName: name) != nil {
        cls = TextAttachmentHTMLElement.self
      } else {
        cls = HTMLElement.self
      }
    }

    let elementClass = cls as! HTMLElement.Type

    if elementClass == TextAttachmentHTMLElement.self {
      return TextAttachmentHTMLElement(name: name, attributes: attributes, options: options)
    }

    return elementClass.init(name: name, attributes: attributes)
  }

  /// Internal initializer with options (for subclasses that need it).
  open func initializeWithOptions(_ options: [String: Any]?) {
    // base class does nothing with options
  }

  // MARK: - Creating Attributed Strings

  /// The dictionary of Core Text attributes for creating an NSAttributedString representation.
  open func attributesForAttributedStringRepresentation() -> NSDictionary {
    let tmpDict = NSMutableDictionary()

    // add text attachment
    if let textAttachment = _textAttachment {
      #if canImport(UIKit)
        // need run delegate for sizing (only supported on iOS)
        let embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(textAttachment)
        tmpDict[NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)] =
          embeddedObjectRunDelegate
      #endif

      // add attachment
      tmpDict[NSAttributedString.Key.attachment] = textAttachment

      // remember original paragraphSpacing
      tmpDict[NSAttributedString.Key(rawValue: DTAttachmentParagraphSpacingAttribute)] = NSNumber(
        value: Double(self.paragraphStyle.paragraphSpacing))
    }

    if let fontDescriptor = _fontDescriptor {
      let font = fontDescriptor.newMatchingFont()

      if let font = font {
        #if canImport(UIKit)
          let uiFont = UIFont.font(with: font)
          tmpDict[NSAttributedString.Key.font] = uiFont
        #else
          tmpDict[NSAttributedString.Key.font] = font
        #endif

        // use this font to adjust the values needed for the run delegate during layout time
        _textAttachment?.adjustVerticalAlignment(for: font)
      }
    }

    // add hyperlink
    if let link = _link {
      tmpDict[NSAttributedString.Key(rawValue: DTLinkAttribute)] = link
      if let linkGUID = _linkGUID {
        tmpDict[NSAttributedString.Key(rawValue: DTGUIDAttribute)] = linkGUID
      }
    }

    // add anchor
    if let anchorName = _anchorName {
      tmpDict[NSAttributedString.Key(rawValue: DTAnchorAttribute)] = anchorName
    }

    // add strikeout if applicable
    if _strikeOut {
      tmpDict[NSAttributedString.Key.strikethroughStyle] = NSNumber(
        value: NSUnderlineStyle.single.rawValue)
    }

    // set underline style
    if _underlineStyle.rawValue != 0 {
      tmpDict[NSAttributedString.Key.underlineStyle] = NSNumber(
        value: NSUnderlineStyle.single.rawValue)
    }

    // set underline color
    if let underlineColor = _underlineColor {
      tmpDict[NSAttributedString.Key.underlineColor] = underlineColor
    }

    if let textColor = _textColor {
      tmpDict[NSAttributedString.Key.foregroundColor] = textColor
    }

    if let backgroundColor = _backgroundColor {
      tmpDict[NSAttributedString.Key.backgroundColor] = backgroundColor
    }

    if _superscriptStyle != 0 {
      tmpDict[NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)] = NSNumber(
        value: _superscriptStyle)
    }

    // add paragraph style
    if let paragraphStyle = _paragraphStyle {
      let style = paragraphStyle.nsParagraphStyle()
      tmpDict[NSAttributedString.Key.paragraphStyle] = style
    }

    // add shadow array if applicable
    if let shadows = _shadows, !shadows.isEmpty {
      let nsShadows = shadows.compactMap { entry -> NSShadow? in
        guard let dict = entry as? [String: Any] else { return nil }
        let s = NSShadow()
        #if canImport(UIKit)
          s.shadowOffset = (dict["Offset"] as? NSValue)?.cgSizeValue ?? .zero
        #else
          s.shadowOffset = (dict["Offset"] as? NSValue)?.sizeValue ?? .zero
        #endif
        s.shadowColor = dict["Color"] as? DTColor
        s.shadowBlurRadius = CGFloat((dict["Blur"] as? NSNumber)?.floatValue ?? 0)
        return s
      }

      if nsShadows.count == 1 {
        // Single shadow: use native .shadow so CTRunDraw handles it
        tmpDict[NSAttributedString.Key.shadow] = nsShadows[0]
      } else if nsShadows.count > 1 {
        // Multiple shadows: only set DTShadowsAttribute so CTRunDraw
        // doesn't draw its own shadow that would conflict with our
        // multi-shadow rendering.
        tmpDict[NSAttributedString.Key(rawValue: DTShadowsAttribute)] = nsShadows
      }
    }

    if _letterSpacing != 0 {
      tmpDict[NSAttributedString.Key.kern] = NSNumber(value: Double(_letterSpacing))
    }

    if _headerLevel != 0 {
      tmpDict[NSAttributedString.Key(rawValue: DTHeaderLevelAttribute)] = NSNumber(
        value: _headerLevel)
    }

    // List metadata rides on `NSParagraphStyle.textLists` (set by
    // `CoreTextParagraphStyle.nsParagraphStyle()`), so no separate attribute write.

    if let textBlocks = _paragraphStyle?.textBlocks {
      tmpDict[NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] = textBlocks
    }

    if let backgroundStrokeColor = _backgroundStrokeColor {
      tmpDict[NSAttributedString.Key(rawValue: DTBackgroundStrokeColorAttribute)] =
        backgroundStrokeColor.cgColor
    }

    if _backgroundStrokeWidth != 0 {
      tmpDict[NSAttributedString.Key(rawValue: DTBackgroundStrokeWidthAttribute)] = NSNumber(
        value: Double(_backgroundStrokeWidth))
    }

    if _backgroundCornerRadius != 0 {
      tmpDict[NSAttributedString.Key(rawValue: DTBackgroundCornerRadiusAttribute)] = NSNumber(
        value: Double(_backgroundCornerRadius))
    }

    return tmpDict
  }

  /// Child nodes of the receiver, filtered to `HTMLElement` instances.
  internal var elementChildren: [HTMLElement] {
    return self.children.compactMap { $0 as? HTMLElement }
  }

  /// Whether this element still requires output.
  open func needsOutput() -> Bool {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    let children = self.elementChildren
    if children.isEmpty { return true }

    for oneChild in children {
      if oneChild.displayStyle == .none { continue }
      if !oneChild.didOutput { return true }
    }
    return false
  }

  private func _isNotChildOfList() -> Bool {
    guard let parent = self.parentElement() else { return true }
    if parent.displayStyle == .listItem { return false }
    if parent.displayStyle == .block && (parent.name == "ol" || parent.name == "ul") {
      return false
    }
    return true
  }

  private func _addCustomHTMLAttributes(to attributedString: NSMutableAttributedString) {
    let attributesToIgnore = type(of: self).attributesToIgnoreForCustomAttributesAttribute
    let entireString = NSRange(location: 0, length: attributedString.length)

    guard let attrs = self.attributes else { return }

    for (key, value) in attrs {
      if attributesToIgnore.contains(key) { continue }
      if key == "class" && value == "Apple-converted-space" { continue }

      var val: Any = value

      if let cssNames = _CSSClassNamesToIgnoreForCustomAttributes, key == "class" {
        let components = value.components(separatedBy: .whitespacesAndNewlines)
        let kept = components.filter { !cssNames.contains($0) }
        if kept.isEmpty { continue }
        val = kept.joined(separator: " ")
      }

      attributedString.dtct_addHTMLAttribute(
        key, value: val, range: entireString, replaceExisting: false)
    }
  }

  /// Creates an NSAttributedString that represents the receiver including all its children.
  open func attributedString() -> NSAttributedString? {
    objc_sync_enter(self)
    defer { objc_sync_exit(self) }

    if _displayStyle == .none || _didOutput { return nil }

    let attributes = attributesForAttributedStringRepresentation() as! [NSAttributedString.Key: Any]

    var tmpString: NSMutableAttributedString

    if _textAttachment != nil {
      tmpString = NSMutableAttributedString(
        string: UNICODE_OBJECT_PLACEHOLDER, attributes: attributes)
    } else {
      tmpString = NSMutableAttributedString()

      var previousChild: HTMLElement? = nil
      let children = self.elementChildren

      if children.isEmpty {
        // no children, nothing to do
        return _finishAttributedString(tmpString, attributes: attributes)
      }

      for oneChild in children {
        if oneChild.displayStyle == .none { continue }

        // if previous node was inline and this child is block, need a newline
        if let prev = previousChild, prev.displayStyle == .inline, oneChild.displayStyle == .block {
          // trim off whitespace suffix
          while tmpString.dt_hasSuffixCharacter(
            from: NSCharacterSet.dt_ignorableWhitespaceCharacterSet)
          {
            tmpString.deleteCharacters(in: NSRange(location: tmpString.length - 1, length: 1))
          }
          // paragraph break
          tmpString.dtct_appendString("\n")
        }

        let nodeString = oneChild.attributedString()

        if var ns = nodeString {
          if !oneChild._containsAppleConvertedSpace {
            // we already have a white space in the string so far
            if tmpString.dt_hasSuffixCharacter(
              from: NSCharacterSet.dt_ignorableWhitespaceCharacterSet)
            {
              let charactersToIgnore = CharacterSet(charactersIn: " \n\t")
              let mutableNS = ns.mutableCopy() as! NSMutableAttributedString

              // Strip leading whitespace in place rather than rebuilding the
              // attributed string on every iteration (which is O(N) per char).
              while mutableNS.length > 0
                && mutableNS.dt_hasPrefixCharacter(from: charactersToIgnore)
              {
                let field =
                  mutableNS.attribute(
                    NSAttributedString.Key(rawValue: DTFieldAttribute), at: 0, effectiveRange: nil)
                  as? String
                if field == DTListPrefixField { break }

                let isHR =
                  (mutableNS.attribute(
                    NSAttributedString.Key(rawValue: DTHorizontalRuleStyleAttribute), at: 0,
                    effectiveRange: nil) as? NSNumber)?.boolValue ?? false
                if isHR { break }

                mutableNS.deleteCharacters(in: NSRange(location: 0, length: 1))
              }

              ns = mutableNS
            }
          }

          tmpString.append(ns)
        }

        previousChild = oneChild
      }
    }

    return _finishAttributedString(tmpString, attributes: attributes)
  }

  private func _finishAttributedString(
    _ tmpString: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]
  ) -> NSMutableAttributedString {
    // block-level elements get space trimmed and a newline
    if _displayStyle != .inline {
      // trim off whitespace prefix
      while tmpString.string.hasPrefix(" ") {
        tmpString.deleteCharacters(in: NSRange(location: 0, length: 1))
      }
      // trim off whitespace suffix
      while tmpString.string.hasSuffix(" ") {
        tmpString.deleteCharacters(in: NSRange(location: tmpString.length - 1, length: 1))
      }

      if self.name != "html" && self.name != "body" {
        if !tmpString.string.hasSuffix("\n") {
          if tmpString.length > 0 {
            tmpString.dtct_appendEndOfParagraph()
          } else {
            let attributedString = NSAttributedString(string: "\n", attributes: attributes)
            tmpString.append(attributedString)
          }
        }
      }
    }

    // make sure the last sub-paragraph has no less than the specified paragraph spacing
    if self.displayStyle == .block && tmpString.length > 0 {
      if _isNotChildOfList() {
        let paragraphRange = (tmpString.string as NSString).rangeOfParagraph(
          at: UInt(tmpString.length - 1))

        if let paraStyle = tmpString.attribute(
          .paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
        {
          let paragraphStyle = CoreTextParagraphStyle.paragraphStyle(
            withNSParagraphStyle: paraStyle)

          if paragraphStyle.paragraphSpacing < self.paragraphStyle.paragraphSpacing {
            paragraphStyle.paragraphSpacing = self.paragraphStyle.paragraphSpacing
            let newParaStyle = paragraphStyle.nsParagraphStyle()
            tmpString.addAttribute(.paragraphStyle, value: newParaStyle, range: paragraphRange)
          }
        }
      }
    }

    // add the custom attributes
    if _shouldProcessCustomHTMLAttributes {
      _addCustomHTMLAttributes(to: tmpString)
    }

    return tmpString
  }

  // MARK: - Working with CSS Styles

  private func _parseEdgeInsets(
    from stylesDict: [String: Any], forAttributesWithPrefix prefix: String,
    writingDirection: CTWritingDirection, intoEdgeInsets insets: inout UIEdgeInsets
  ) -> Bool {
    var edgeInsets = insets
    var didModify = false

    guard !stylesDict.isEmpty else { return false }

    let isWebKitAttribute = prefix.hasPrefix("-webkit")

    var leftKey = "-left"
    if isWebKitAttribute {
      leftKey = (writingDirection == .rightToLeft) ? "-end" : "-start"
    }

    var rightKey = "-right"
    if isWebKitAttribute {
      rightKey = (writingDirection == .rightToLeft) ? "-start" : "-end"
    }

    let topKey = isWebKitAttribute ? "-before" : "-top"
    let bottomKey = isWebKitAttribute ? "-after" : "-bottom"


    for oneKey in stylesDict.keys {
      guard oneKey.hasPrefix(prefix) else { continue }
      guard let attributeValue = stylesDict[oneKey] as? String else { continue }

      if oneKey.contains("-") {
        let fontSize = _fontDescriptor?.pointSize ?? 12
        if oneKey.hasSuffix(leftKey) {
          edgeInsets.left = (attributeValue as NSString).pixelSizeOfCSSMeasure(
            relativeToCurrentTextSize: fontSize, textScale: _textScale)
          didModify = true
        } else if oneKey.hasSuffix(bottomKey) {
          edgeInsets.bottom = (attributeValue as NSString).pixelSizeOfCSSMeasure(
            relativeToCurrentTextSize: fontSize, textScale: _textScale)
          didModify = true
        } else if oneKey.hasSuffix(rightKey) {
          edgeInsets.right = (attributeValue as NSString).pixelSizeOfCSSMeasure(
            relativeToCurrentTextSize: fontSize, textScale: _textScale)
          didModify = true
        } else if oneKey.hasSuffix(topKey) {
          edgeInsets.top = (attributeValue as NSString).pixelSizeOfCSSMeasure(
            relativeToCurrentTextSize: fontSize, textScale: _textScale)
          didModify = true
        }
      } else {
        edgeInsets = (attributeValue as NSString).dtEdgeInsets(
          relativeToCurrentTextSize: _fontDescriptor?.pointSize ?? 12, textScale: _textScale)
        didModify = true
      }
    }

    if didModify { insets = edgeInsets }
    return didModify
  }

  /// Applies the style information contained in a styles dictionary to the receiver.
  open func applyStyles(_ styles: [String: Any]) {
    guard !styles.isEmpty else { return }
    _styles = styles

    // writing direction
    if let directionStr = styles["direction"] as? String {
      if directionStr == "rtl" {
        _paragraphStyle?.baseWritingDirection = .rightToLeft
      } else if directionStr == "ltr" {
        _paragraphStyle?.baseWritingDirection = .leftToRight
      } else if directionStr == "auto" {
        _paragraphStyle?.baseWritingDirection = .natural
      }
    }

    // register pseudo-selector contents
    if let beforeContent = styles["before:content"] as? String {
      self.beforeContent = (beforeContent as NSString).stringByDecodingCSSContentAttribute()
    }

    // font-size
    var fontSize: String?
    if let fontSizeObj = styles["font-size"] {
      if let s = fontSizeObj as? String {
        fontSize = s
      } else if let arr = fontSizeObj as? [Any], let last = arr.last as? String {
        fontSize = last
      }
    }
    if let fontSize = fontSize {
      let fd = _fontDescriptor
      switch fontSize {
      case "smaller": fd?.pointSize /= 1.2
      case "larger": fd?.pointSize *= 1.2
      case "xx-small": fd?.pointSize = 9.0 * _textScale
      case "x-small": fd?.pointSize = 10.0 * _textScale
      case "small": fd?.pointSize = 13.0 * _textScale
      case "medium": fd?.pointSize = 16.0 * _textScale
      case "large": fd?.pointSize = 18.0 * _textScale
      case "x-large": fd?.pointSize = 24.0 * _textScale
      case "xx-large": fd?.pointSize = 32.0 * _textScale
      case "-webkit-xxx-large": fd?.pointSize = 48.0 * _textScale
      case "inherit": fd?.pointSize = self.parentElement()?.fontDescriptor.pointSize ?? 12
      default:
        if (fontSize as NSString).isCSSLengthValue() {
          fd?.pointSize = (fontSize as NSString).pixelSizeOfCSSMeasure(
            relativeToCurrentTextSize: _currentTextSize, textScale: _textScale)
        }
      }
    }

    // color
    if let color = styles["color"] as? String {
      self.textColor = DTColorCreateWithHTMLName(color)
    }

    // background-color
    if let bgColor = styles["background-color"] as? String {
      self.backgroundColor = DTColorCreateWithHTMLName(bgColor)
    }

    // float
    if let floatString = styles["float"] as? String {
      switch floatString {
      case "left": _floatStyle = .left
      case "right": _floatStyle = .right
      case "none": _floatStyle = .none
      default: break
      }
    }

    // font-family
    if let fontFamilyStyle = styles["font-family"] {
      var fontFamilies: [String]?
      if let s = fontFamilyStyle as? String {
        fontFamilies = [s]
      } else if let arr = fontFamilyStyle as? [String] {
        fontFamilies = arr
      }

      if let families = fontFamilies {
        var foundFontFamily = false
        for fontFamily in families {
          _fontDescriptor?.fontFamily = fontFamily
          if let font = _fontDescriptor?.newMatchingFont() {
            let foundFamily = CTFontCopyFamilyName(font) as String
            if foundFamily == fontFamily {
              foundFontFamily = true
              break
            }
            let lc = fontFamily.lowercased().replacingOccurrences(
              of: "\\s", with: "", options: .regularExpression)
            let parts = lc.components(separatedBy: ",")

            if parts.contains("sans-serif") || parts.contains("geneva") {
              _fontDescriptor?.fontFamily = "Helvetica"
              foundFontFamily = true
            } else if parts.contains("serif") || parts.contains("times") {
              _fontDescriptor?.fontFamily = "Times New Roman"
              foundFontFamily = true
            } else if parts.contains("monospace") {
              _fontDescriptor?.monospaceTrait = true
              _fontDescriptor?.fontFamily = "Courier"
              foundFontFamily = true
            } else if parts.contains("cursive") {
              _fontDescriptor?.stylisticClass = CTFontStylisticClass.scriptsClass
              _fontDescriptor?.fontFamily = nil
              foundFontFamily = true
            } else if parts.contains("fantasy") {
              _fontDescriptor?.fontFamily = "Papyrus"
              foundFontFamily = true
            } else if lc == "inherit" {
              _fontDescriptor?.fontFamily = self.parentElement()?.fontDescriptor.fontFamily
              foundFontFamily = true
            }
          }
          if foundFontFamily { break }
        }
        if !foundFontFamily {
          _fontDescriptor?.fontFamily = families.first
        }
      }
    }

    // font-style
    if let fontStyleObj = styles["font-style"] as? String {
      let fontStyle = fontStyleObj.lowercased()
      _fontDescriptor?.fontName = nil
      switch fontStyle {
      case "normal": _fontDescriptor?.italicTrait = false
      case "italic", "oblique": _fontDescriptor?.italicTrait = true
      default: break
      }
    }

    // font-weight
    if let fontWeightObj = styles["font-weight"] as? String {
      let fontWeight = fontWeightObj.lowercased()
      _fontDescriptor?.fontName = nil
      switch fontWeight {
      case "normal", "lighter": _fontDescriptor?.boldTrait = false
      case "bold", "bolder": _fontDescriptor?.boldTrait = true
      default:
        if let value = Int(fontWeight) {
          _fontDescriptor?.boldTrait = value > 600
        }
      }
    }

    // text-decoration
    if let decoration = (styles["text-decoration"] as? String)?.lowercased() {
      switch decoration {
      case "underline": self.underlineStyle = .single
      case "line-through": self.strikeOut = true
      case "none":
        self.underlineStyle = CTUnderlineStyle(rawValue: 0)
        self.strikeOut = false
      default: break
      }
    }

    if let decorationColor = styles["text-decoration-color"] as? String {
      self.underlineColor = DTColorCreateWithHTMLName(decorationColor.lowercased())
    }

    // text-align
    if let alignment = (styles["text-align"] as? String)?.lowercased() {
      switch alignment {
      case "left": self.paragraphStyle.alignment = .left
      case "right": self.paragraphStyle.alignment = .right
      case "center": self.paragraphStyle.alignment = .center
      case "justify": self.paragraphStyle.alignment = .justified
      default: break
      }
    }

    // vertical-align
    if let verticalAlignment = (styles["vertical-align"] as? String)?.lowercased() {
      switch verticalAlignment {
      case "sub": self.superscriptStyle = -1
      case "super": self.superscriptStyle = 1
      case "baseline":
        self.superscriptStyle = 0
        _textAttachmentAlignment = .baseline
      case "text-top": _textAttachmentAlignment = .top
      case "middle": _textAttachmentAlignment = .center
      case "text-bottom": _textAttachmentAlignment = .bottom
      default: break
      }
    }

    // letter-spacing
    if let ls = (styles["letter-spacing"] as? String)?.lowercased() {
      if ls == "normal" {
        _letterSpacing = 0
      } else if ls != "inherit" {
        _letterSpacing = (ls as NSString).pixelSizeOfCSSMeasure(
          relativeToCurrentTextSize: _fontDescriptor?.pointSize ?? 12, textScale: _textScale)
      }
    }

    // if there is a text attachment we transfer the alignment we got
    _textAttachment?.verticalAlignment = _textAttachmentAlignment

    // text-shadow
    if let shadow = styles["text-shadow"] {
      self.shadows =
        (shadow as? NSString)?.arrayOfCSSShadows(
          withCurrentTextSize: _fontDescriptor?.pointSize ?? 12, currentColor: _textColor) as [Any]?
    }

    // line-height
    if let lineHeight = (styles["line-height"] as? String)?.lowercased() {
      if lineHeight == "normal" {
        self.paragraphStyle.lineHeightMultiple = 0
        self.paragraphStyle.minimumLineHeight = 0
        self.paragraphStyle.maximumLineHeight = 0
      } else if lineHeight != "inherit" {
        if lineHeight.isNumericOnly {
          self.paragraphStyle.lineHeightMultiple = CGFloat(Float(lineHeight) ?? 0)
        } else {
          let lhValue = (lineHeight as NSString).pixelSizeOfCSSMeasure(
            relativeToCurrentTextSize: _fontDescriptor?.pointSize ?? 12, textScale: _textScale)
          self.paragraphStyle.minimumLineHeight = lhValue
          self.paragraphStyle.maximumLineHeight = lhValue
        }
      }
    }

    // font-variant
    if let fontVariantStr = (styles["font-variant"] as? String)?.lowercased() {
      switch fontVariantStr {
      case "small-caps": _fontVariant = .smallCaps
      case "inherit": _fontVariant = .inherit
      default: _fontVariant = .normal
      }
    }

    // width / height
    if let widthString = styles["width"] as? String, widthString != "auto" {
      _size.width = (widthString as NSString).pixelSizeOfCSSMeasure(
        relativeToCurrentTextSize: _fontDescriptor?.pointSize ?? 12, textScale: _textScale)
    }
    if let heightString = styles["height"] as? String, heightString != "auto" {
      _size.height = (heightString as NSString).pixelSizeOfCSSMeasure(
        relativeToCurrentTextSize: _fontDescriptor?.pointSize ?? 12, textScale: _textScale)
    }

    // white-space
    if let ws = styles["white-space"] as? String, ws.hasPrefix("pre") {
      _preserveNewlines = true
    } else {
      _preserveNewlines = false
    }

    // display
    if let displayString = styles["display"] as? String {
      switch displayString {
      case "none": _displayStyle = .none
      case "block": _displayStyle = .block
      case "inline": _displayStyle = .inline
      case "list-item": _displayStyle = .listItem
      case "table": _displayStyle = .table
      default: break
      }
    }

    // border
    if let borderColor = styles["border-color"] as? String {
      self.backgroundStrokeColor = DTColorCreateWithHTMLName(borderColor)
    }
    if let bw = (styles["border-width"] as? String)?.lowercased() as NSString? {
      _backgroundStrokeWidth = CGFloat(bw.floatValue)
    }
    if let br = (styles["border-radius"] as? String)?.lowercased() as NSString? {
      _backgroundCornerRadius = CGFloat(br.floatValue)
    }

    // text-indent
    if let textIndentStr = styles["text-indent"] as? String,
      (textIndentStr as NSString).isCSSLengthValue()
    {
      _pTextIndent = (textIndentStr as NSString).pixelSizeOfCSSMeasure(
        relativeToCurrentTextSize: _currentTextSize, textScale: _textScale)
    }

    let needsTextBlock =
      (_backgroundColor != nil || _backgroundStrokeColor != nil || _backgroundCornerRadius > 0
        || _backgroundStrokeWidth > 0)

    var hasMargins = false
    let allKeys = styles.keys.joined(separator: ";")

    if allKeys.contains("-webkit-margin") {
      hasMargins =
        _parseEdgeInsets(
          from: styles, forAttributesWithPrefix: "-webkit-margin",
          writingDirection: self.paragraphStyle.baseWritingDirection, intoEdgeInsets: &_margins)
        || hasMargins
    }
    if allKeys.contains("margin") {
      hasMargins =
        _parseEdgeInsets(
          from: styles, forAttributesWithPrefix: "margin",
          writingDirection: self.paragraphStyle.baseWritingDirection, intoEdgeInsets: &_margins)
        || hasMargins
    }

    var hasPadding = false
    if allKeys.contains("-webkit-padding") {
      hasPadding =
        _parseEdgeInsets(
          from: styles, forAttributesWithPrefix: "-webkit-padding",
          writingDirection: self.paragraphStyle.baseWritingDirection, intoEdgeInsets: &_padding)
        || hasPadding
    }
    if allKeys.contains("padding") {
      hasPadding =
        _parseEdgeInsets(
          from: styles, forAttributesWithPrefix: "padding",
          writingDirection: self.paragraphStyle.baseWritingDirection, intoEdgeInsets: &_padding)
        || hasPadding
    }

    var actualNeedsTextBlock = needsTextBlock

    if hasPadding {
      if self.name == "ul" || self.name == "ol" {
        _listIndent = _padding.left
        _padding.left = 0
      }
      if _padding.left > 0 || _padding.right > 0 || _padding.top > 0 || _padding.bottom > 0 {
        actualNeedsTextBlock = true
      }
    }

    if _displayStyle == .block {
      if hasMargins {
        self.paragraphStyle.paragraphSpacing = _margins.bottom
        self.paragraphStyle.paragraphSpacingBefore = _margins.top
        self.paragraphStyle.headIndent += _margins.left
        self.paragraphStyle.firstLineHeadIndent = self.paragraphStyle.headIndent
        self.paragraphStyle.tailIndent -= _margins.right
      }

      if actualNeedsTextBlock {
        let newBlock = TextBlock()
        newBlock.padding = _padding

        newBlock.backgroundColor = _backgroundColor
        _backgroundColor = nil

        if let textBlocks = self.paragraphStyle.textBlocks {
          var mutableBlocks = textBlocks
          mutableBlocks.append(newBlock)
          self.paragraphStyle.textBlocks = mutableBlocks
        } else {
          self.paragraphStyle.textBlocks = [newBlock]
        }
      }
    } else if _displayStyle == .listItem {
      self.paragraphStyle.paragraphSpacing = _margins.bottom
    }

    // -coretext-fontname
    if let ctFontName = styles["-coretext-fontname"] as? String {
      _fontDescriptor?.fontName = ctFontName
    }
  }

  /// Creates a `DTTextList` to match the CSS styles.
  open func listStyle() -> DTTextList {
    let style = DTTextList(styles: _styles ?? [:])

    if let startingIndex = self.attributes?["start"], let value = Int(startingIndex) {
      style.startingItemNumber = value
    }

    return style
  }

  // MARK: - Working with HTML Attributes

  /// Retrieves an attribute with a given key.
  open func attributeForKey(_ key: String) -> String? {
    return self.attributes?[key]
  }

  /// HTML attributes to ignore for custom attributes.
  open class var attributesToIgnoreForCustomAttributesAttribute: Set<String> {
    return [
      "style", "dir", "align", "src", "href", "color", "face", "size", "name", "height", "width",
    ]
  }

  /// CSS class names that should not be serialized as custom HTML attributes.
  open var CSSClassNamesToIgnoreForCustomAttributes: Set<String>? {
    get { return _CSSClassNamesToIgnoreForCustomAttributes }
    set { _CSSClassNamesToIgnoreForCustomAttributes = newValue }
  }

  /// Swift-native setter for the CSS class names that should not be serialized as
  /// custom HTML attributes.
  public func setCSSClassNamesToIgnoreForCustomAttributes(_ names: Set<String>) {
    _CSSClassNamesToIgnoreForCustomAttributes = names
  }

  /// Copies and inherits relevant attributes from the given parent element.
  open func inheritAttributes(from element: HTMLElement) {
    _fontDescriptor = element.fontDescriptor.copy() as? CoreTextFontDescriptor
    _paragraphStyle = element.paragraphStyle.copy() as? CoreTextParagraphStyle

    _headerLevel = element.headerLevel
    _fontVariant = element.fontVariant
    _underlineStyle = element.underlineStyle
    _underlineColor = element.underlineColor
    _strikeOut = element.strikeOut
    _superscriptStyle = element.superscriptStyle
    _letterSpacing = element.letterSpacing

    _shadows = element.shadows?.map { $0 }
    _link = element.link
    _anchorName = element.anchorName
    _linkGUID = element._linkGUID

    _textColor = element.textColor
    _isColorInherited = true

    _preserveNewlines = element.preserveNewlines
    _currentTextSize = element.currentTextSize
    _textScale = element.textScale

    _backgroundColor = element.backgroundColor
    _backgroundStrokeColor = element.backgroundStrokeColor
    _backgroundStrokeWidth = element.backgroundStrokeWidth
    _backgroundCornerRadius = element.backgroundCornerRadius

    if element.displayStyle == .inline || element.displayStyle == .listItem {
      self.backgroundColor = element.backgroundColor
    }

    _containsAppleConvertedSpace = element.containsAppleConvertedSpace
    _textAttachment?.hyperLinkURL = element.link
  }

  /// Interprets the tag attributes for e.g. writing direction.
  open func interpretAttributes() {
    guard self.attributes != nil else { return }

    // transfer Apple Converted Space tag
    if attributeForKey("class") == "Apple-converted-space" {
      _containsAppleConvertedSpace = true
    }

    // detect writing direction if set
    if let directionStr = attributeForKey("dir") {
      switch directionStr {
      case "rtl": _paragraphStyle?.baseWritingDirection = .rightToLeft
      case "ltr": _paragraphStyle?.baseWritingDirection = .leftToRight
      case "auto": _paragraphStyle?.baseWritingDirection = .natural
      default: break
      }
    }

    // handles align="justify"
    if let align = attributeForKey("align") {
      switch align {
      case "justify": _paragraphStyle?.alignment = .justified
      case "left": _paragraphStyle?.alignment = .left
      case "center": _paragraphStyle?.alignment = .center
      case "right": _paragraphStyle?.alignment = .right
      default: break
      }
    }
  }

  // MARK: - Properties

  open var fontDescriptor: CoreTextFontDescriptor {
    get { return _fontDescriptor ?? CoreTextFontDescriptor() }
    set { _fontDescriptor = newValue }
  }

  open var paragraphStyle: CoreTextParagraphStyle {
    get { return _paragraphStyle ?? CoreTextParagraphStyle() }
    set { _paragraphStyle = newValue }
  }

  open var textAttachment: TextAttachment? {
    get { return _textAttachment }
    set {
      newValue?.verticalAlignment = _textAttachmentAlignment
      _textAttachment = newValue
      _textAttachment?.hyperLinkGUID = _linkGUID
    }
  }

  open var link: URL? {
    get { return _link }
    set {
      _linkGUID = UUID().uuidString
      _link = newValue
      _textAttachment?.hyperLinkGUID = _linkGUID
    }
  }

  open var anchorName: String? {
    get { return _anchorName }
    set { _anchorName = newValue }
  }

  open var textColor: DTColor? {
    get { return _textColor }
    set {
      _textColor = newValue
      _isColorInherited = false
    }
  }

  open var backgroundColor: DTColor? {
    get { return _backgroundColor }
    set { _backgroundColor = newValue }
  }

  open var backgroundStrokeColor: DTColor? {
    get { return _backgroundStrokeColor }
    set { _backgroundStrokeColor = newValue }
  }

  open var backgroundStrokeWidth: CGFloat {
    get { return _backgroundStrokeWidth }
    set { _backgroundStrokeWidth = newValue }
  }

  open var backgroundCornerRadius: CGFloat {
    get { return _backgroundCornerRadius }
    set { _backgroundCornerRadius = newValue }
  }

  open var pTextIndent: CGFloat {
    get { return _pTextIndent }
    set { _pTextIndent = newValue }
  }

  open var letterSpacing: CGFloat {
    get { return _letterSpacing }
    set { _letterSpacing = newValue }
  }

  open var beforeContent: String? {
    get { return _beforeContent }
    set { _beforeContent = newValue }
  }

  open var shadows: [Any]? {
    get { return _shadows }
    set { _shadows = newValue }
  }

  open var underlineStyle: CTUnderlineStyle {
    get { return _underlineStyle }
    set { _underlineStyle = newValue }
  }

  open var underlineColor: DTColor? {
    get { return _underlineColor }
    set { _underlineColor = newValue }
  }

  open var strikeOut: Bool {
    get { return _strikeOut }
    set { _strikeOut = newValue }
  }

  open var superscriptStyle: Int {
    get { return _superscriptStyle }
    set { _superscriptStyle = newValue }
  }

  open var headerLevel: Int {
    get { return _headerLevel }
    set { _headerLevel = newValue }
  }

  open var displayStyle: DTHTMLElementDisplayStyle {
    get { return _displayStyle }
    set { _displayStyle = newValue }
  }

  open var floatStyle: DTHTMLElementFloatStyle {
    return _floatStyle
  }

  open var isColorInherited: Bool {
    get { return _isColorInherited }
    set { _isColorInherited = newValue }
  }

  open var preserveNewlines: Bool {
    get { return _preserveNewlines }
    set { _preserveNewlines = newValue }
  }

  open var fontVariant: DTHTMLElementFontVariant {
    get {
      if _fontVariant == .inherit {
        return self.parentElement()?.fontVariant ?? .normal
      }
      return _fontVariant
    }
    set { _fontVariant = newValue }
  }

  open var currentTextSize: CGFloat {
    get {
      if _currentTextSize == 0, let parent = self.parentElement() {
        return parent.currentTextSize
      }
      return _currentTextSize
    }
    set { _currentTextSize = newValue }
  }

  open var textScale: CGFloat {
    get { return _textScale }
    set { _textScale = newValue }
  }

  open var size: CGSize {
    get { return _size }
    set { _size = newValue }
  }

  open var margins: UIEdgeInsets {
    get { return _margins }
    set { _margins = newValue }
  }

  open var padding: UIEdgeInsets {
    get { return _padding }
    set { _padding = newValue }
  }

  open var containsAppleConvertedSpace: Bool {
    get { return _containsAppleConvertedSpace }
    set { _containsAppleConvertedSpace = newValue }
  }

  open var shouldProcessCustomHTMLAttributes: Bool {
    get { return _shouldProcessCustomHTMLAttributes }
    set { _shouldProcessCustomHTMLAttributes = newValue }
  }

  open var didOutput: Bool {
    get {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      return _didOutput
    }
    set {
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      _didOutput = newValue
    }
  }

  override open var attributes: [String: String]? {
    didSet {
      _updateSizeFromAttributes()
    }
  }

  private func _updateSizeFromAttributes() {
    _size = CGSize(
      width: CGFloat(Float(attributeForKey("width") ?? "") ?? 0),
      height: CGFloat(Float(attributeForKey("height") ?? "") ?? 0)
    )
  }

  /// Returns the parent element.
  open func parentElement() -> HTMLElement? {
    return self.parentNode as? HTMLElement
  }
}

// UIEdgeInsets typealias for macOS is defined in NSCoder+DTCompatibility.swift
