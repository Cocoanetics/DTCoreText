import CoreGraphics
import CoreText
import Foundation
import HTMLParser
import os.log

#if canImport(UIKit)
  import UIKit
  internal typealias PlatformColor = UIColor
#elseif canImport(AppKit)
  import AppKit
  internal typealias PlatformColor = NSColor
#endif

private let logger = Logger(
  subsystem: "com.cocoanetics.DTCoreText", category: "BuilderState")

// MARK: - Builder State Actor

/// Owns all mutable parse/build state. Events are processed sequentially.
internal actor BuilderState {
  // Parsing tree
  var rootNode: HTMLElement?
  var bodyElement: HTMLElement?
  var currentTag: HTMLElement?
  var ignoreParseEvents = false

  // Output
  var tmpString = NSMutableAttributedString()

  // Config (set once before parsing)
  var textScale: CGFloat = 1.0
  var defaultLinkColor: PlatformColor?
  var globalStyleSheet: CSSStylesheet!
  var baseURL: URL?
  var defaultFontDescriptor: CoreTextFontDescriptor!
  var defaultParagraphStyle: CoreTextParagraphStyle!
  var defaultTag: HTMLElement!
  var shouldProcessCustomHTMLAttributes = false
  var ignoreInlineStyles = false
  var preserveDocumentTrailingSpaces = false
  var shouldKeepDocumentNodeTree = false
  var options: [String: Any] = [:]

  // MARK: - Configuration

  func configure(
    options: [String: Any],
    shouldKeepDocumentNodeTree: Bool
  ) {

    rootNode = nil
    bodyElement = nil
    currentTag = nil
    ignoreParseEvents = false
    tmpString = NSMutableAttributedString()

    self.options = options
    self.shouldKeepDocumentNodeTree = shouldKeepDocumentNodeTree

    // Text scale
    if let scaleValue = options[NSTextSizeMultiplierDocumentOption] as? Double {
      textScale = CGFloat(scaleValue)
    }
    if textScale == 0 { textScale = 1.0 }

    // Base URL
    baseURL = options[NSBaseURLDocumentOption] as? URL

    // Global stylesheet
    globalStyleSheet = CSSStylesheet.defaultStyleSheet().copy() as? CSSStylesheet

    if let customSheet = options[DTDefaultStyleSheet] as? CSSStylesheet {
      globalStyleSheet.mergeStylesheet(customSheet)
    }

    // Default font
    var defaultFontSize: CGFloat = 12.0

    if let ctDescriptorValue = options[DTDefaultFontDescriptor],
      CFGetTypeID(ctDescriptorValue as CFTypeRef) == CTFontDescriptorGetTypeID()
    {
      defaultFontDescriptor = CoreTextFontDescriptor(
        ctFontDescriptor: ctDescriptorValue as! CTFontDescriptor)
    } else {
      defaultFontDescriptor = CoreTextFontDescriptor()

      if let sizeNum = options[DTDefaultFontSize] as? Double {
        defaultFontSize = CGFloat(sizeNum)
      }
      defaultFontDescriptor.pointSize = defaultFontSize * textScale
      defaultFontDescriptor.fontFamily =
        (options[DTDefaultFontFamily] as? String) ?? "Times New Roman"

      if let name = options[DTDefaultFontName] as? String {
        defaultFontDescriptor.fontName = name
      }
    }

    // Link color
    if let linkColor = options[DTDefaultLinkColor] {
      if let colorString = linkColor as? String {
        defaultLinkColor = DTColorCreateWithHTMLName(colorString)
      } else if let color = linkColor as? PlatformColor {
        defaultLinkColor = color
      }
      if let color = defaultLinkColor, let hex = DTHexStringFromDTColor(color) {
        globalStyleSheet.parseStyleBlock("a {color:#\(hex);}")
      }
    }

    // Link decoration
    if let dec = options[DTDefaultLinkDecoration] as? Bool, !dec {
      globalStyleSheet.parseStyleBlock("a {text-decoration:none;}")
    }

    // Link highlight color
    if let highlight = options[DTDefaultLinkHighlightColor] {
      var color: PlatformColor?
      if let s = highlight as? String {
        color = DTColorCreateWithHTMLName(s)
      } else if let c = highlight as? PlatformColor {
        color = c
      }
      if let color, let hex = DTHexStringFromDTColor(color) {
        globalStyleSheet.parseStyleBlock("a:active {color:#\(hex);}")
      }
    }

    // Default paragraph style
    defaultParagraphStyle = CoreTextParagraphStyle.defaultParagraphStyle()

    if let lh = options[DTDefaultLineHeightMultiplier] as? Double {
      defaultParagraphStyle.lineHeightMultiple = CGFloat(lh)
    }
    if let align = options[DTDefaultTextAlignment] as? Int {
      defaultParagraphStyle.alignment = CTTextAlignment(rawValue: UInt8(align)) ?? .natural
    }
    if let fi = options[DTDefaultFirstLineHeadIndent] as? Int {
      defaultParagraphStyle.firstLineHeadIndent = CGFloat(fi)
    }
    if let hi = options[DTDefaultHeadIndent] as? Int {
      defaultParagraphStyle.headIndent = CGFloat(hi)
    }

    // Default tag element
    defaultTag = HTMLElement(name: "default", attributes: nil)
    defaultTag.fontDescriptor = defaultFontDescriptor
    defaultTag.paragraphStyle = defaultParagraphStyle
    defaultTag.textScale = textScale
    defaultTag.currentTextSize = defaultFontDescriptor.pointSize
    defaultTag.underlineColor = PlatformColor.black

    if let defaultColor = options[DTDefaultTextColor] {
      if let color = defaultColor as? PlatformColor {
        defaultTag.textColor = color
      } else if let s = defaultColor as? String {
        defaultTag.textColor = DTColorCreateWithHTMLName(s)
      }
    }

    shouldProcessCustomHTMLAttributes = (options[DTProcessCustomHTMLAttributes] as? Bool) ?? false
    ignoreInlineStyles = (options[DTIgnoreInlineStylesOption] as? Bool) ?? false
    preserveDocumentTrailingSpaces = (options[DTDocumentPreserveTrailingSpaces] as? Bool) ?? false
  }

  // MARK: - Event Handling

  func handle(_ event: HTMLParserEvent) {
    switch event {
    case .startDocument:
      break
    case .endDocument:
      handleEndDocument()
    case .startElement(let name, let attributes):
      handleStartElement(name, attributes: attributes)
    case .endElement(let name):
      handleEndElement(name)
    case .characters(let string):
      handleFoundCharacters(string)
    case .cdata(let data):
      handleFoundCDATA(data)
    case .comment, .processingInstruction:
      break
    case .parseError:
      break
    }
  }

  func result() -> sending NSAttributedString {
    nonisolated(unsafe) let copy = NSAttributedString(attributedString: tmpString)
    return copy
  }

  // MARK: - Start Element

  private func handleStartElement(_ elementName: String, attributes attributeDict: [String: String])
  {
    guard !ignoreParseEvents else { return }

    let newNode = HTMLElement.element(name: elementName, attributes: attributeDict, options: options)
    var previousLastChild: HTMLElement?

    if let current = currentTag {
      newNode.inheritAttributes(from: current)
      newNode.interpretAttributes()

      previousLastChild = current.lastChild as? HTMLElement
      current.addChildNode(newNode)

      if bodyElement == nil && newNode.name == "body" {
        bodyElement = newNode
      }
      if shouldProcessCustomHTMLAttributes {
        newNode.shouldProcessCustomHTMLAttributes = true
      }
    } else {
      assert(rootNode == nil, "Something went wrong, second root node found")
      if rootNode == nil {
        rootNode = newNode
        newNode.inheritAttributes(from: defaultTag)
        newNode.interpretAttributes()
      }
    }

    // Apply styles from merged stylesheet
    let (mergedStyles, matchedSelectors) = globalStyleSheet.mergedStyles(
      for: newNode, ignoreInlineStyle: ignoreInlineStyles)

    if let mergedStyles {
      newNode.applyStyles(mergedStyles)

      var classNamesToIgnore = Set<String>()
      for selector in matchedSelectors {
        if let periodRange = selector.range(of: ".") {
          classNamesToIgnore.insert(
            String(selector[selector.index(after: periodRange.lowerBound)...]))
        }
      }
      if !classNamesToIgnore.isEmpty {
        newNode.setCSSClassNamesToIgnoreForCustomAttributes(classNamesToIgnore)
      }
    }

    // Block element eliminates previous trailing whitespace
    if let previousLastChild, newNode.displayStyle != DTHTMLElementDisplayStyle.inline,
      let textElement = previousLastChild as? TextHTMLElement,
      textElement.text().isIgnorableWhitespace
    {
      currentTag?.removeChildNode(textElement)
    }

    currentTag = newNode

    // Tag-specific start handling
    applyTagStartHandler(elementName, tag: newNode)
  }

  // MARK: - Tag Start Handlers (inline)

  private func applyTagStartHandler(_ name: String, tag: HTMLElement) {
    switch name {
    case "blockquote":
      tag.paragraphStyle.headIndent += 25.0 * textScale
      tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent
      tag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize

    case "a":
      handleAnchorStart(tag)

    case "ul", "ol":
      tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent
      let newListStyle = tag.listStyle()
      var textLists = tag.paragraphStyle.textLists ?? []
      textLists.append(newListStyle)
      tag.paragraphStyle.textLists = textLists

    case "h1": tag.headerLevel = 1
    case "h2": tag.headerLevel = 2
    case "h3": tag.headerLevel = 3
    case "h4": tag.headerLevel = 4
    case "h5": tag.headerLevel = 5
    case "h6": tag.headerLevel = 6

    case "font":
      handleFontStart(tag)

    case "p":
      if defaultParagraphStyle.firstLineHeadIndent > 0 {
        tag.paragraphStyle.firstLineHeadIndent =
          tag.paragraphStyle.headIndent + defaultParagraphStyle.firstLineHeadIndent
      } else {
        tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent + tag.pTextIndent
      }

    default:
      break
    }
  }

  private func handleAnchorStart(_ tag: HTMLElement) {
    if tag.isColorInherited || tag.textColor == nil {
      tag.textColor = defaultLinkColor
      tag.isColorInherited = false
    }

    tag.anchorName = tag.attributeForKey("name")

    guard var cleanString = tag.attributeForKey("href")?.replacingOccurrences(of: "\n", with: ""),
      !cleanString.trimmingCharacters(in: .whitespaces).isEmpty
    else {
      return
    }
    cleanString = cleanString.trimmingCharacters(in: .whitespaces)

    var link = URL(string: cleanString)
    if link == nil {
      link = URL(string: cleanString.encodingNonASCIICharacters())
    }
    if link?.scheme == nil {
      if !cleanString.isEmpty {
        link = URL(string: cleanString, relativeTo: baseURL)
        if link == nil {
          link = URL(string: cleanString.addingHTMLEntities(), relativeTo: baseURL)
        }
      } else {
        link = baseURL
      }
    }
    tag.link = link
  }

  private func handleFontStart(_ tag: HTMLElement) {
    var pointSize: CGFloat
    if let sizeAttribute = tag.attributeForKey("size") {
      switch Int(sizeAttribute) ?? 0 {
      case 1: pointSize = textScale * 10.0
      case 2: pointSize = textScale * 13.0
      case 3: pointSize = textScale * 16.0
      case 4: pointSize = textScale * 18.0
      case 5: pointSize = textScale * 24.0
      case 6: pointSize = textScale * 32.0
      case 7: pointSize = textScale * 48.0
      default: pointSize = defaultFontDescriptor.pointSize
      }
    } else {
      pointSize = tag.fontDescriptor.pointSize
    }
    if let face = tag.attributeForKey("face") {
      let font = CTFontCreateWithName(face as CFString, pointSize, nil)
      tag.fontDescriptor = CoreTextFontDescriptor(ctFont: font)
    } else {
      tag.fontDescriptor.pointSize = pointSize
    }
    if let color = tag.attributeForKey("color") {
      tag.textColor = DTColorCreateWithHTMLName(color)
    }
  }

  // MARK: - End Element

  private func handleEndElement(_ elementName: String) {
    guard !ignoreParseEvents else { return }

    // Tag-specific end handling
    if let tag = currentTag {
      applyTagEndHandler(elementName, tag: tag)
    }

    // Flush if direct child of body or body itself
    if let tag = currentTag, tag.displayStyle != DTHTMLElementDisplayStyle.none {
      if tag === bodyElement || tag.parentElement() === bodyElement {
        flush(tag)
      }
    }

    // Walk up to find matching element
    while currentTag?.name != elementName {
      currentTag = currentTag?.parentElement()
    }

    // Closing root node — ignore everything afterwards
    if currentTag === rootNode {
      ignoreParseEvents = true
    }

    currentTag = currentTag?.parentElement()
  }

  // MARK: - Tag End Handlers (inline)

  private func applyTagEndHandler(_ name: String, tag: HTMLElement) {
    switch name {
    case "object":
      if let attachmentElement = tag as? TextAttachmentHTMLElement,
        let objectAttachment = attachmentElement.textAttachment as? ObjectTextAttachment
      {
        let snapshot = tag.elementChildren
        objectAttachment.childNodes = snapshot.isEmpty ? nil : snapshot
      }

    case "video":
      if let attachmentElement = tag as? TextAttachmentHTMLElement,
        let videoAttachment = attachmentElement.textAttachment as? VideoTextAttachment,
        videoAttachment.contentURL == nil
      {
        for htmlChild in attachmentElement.elementChildren where htmlChild.name == "source" {
          if let src = htmlChild.attributeForKey("src") {
            videoAttachment.contentURL = URL(string: src, relativeTo: baseURL)
            break
          }
        }
      }

    case "style":
      if let stylesheetElement = tag as? StylesheetHTMLElement {
        globalStyleSheet.mergeStylesheet(stylesheetElement.stylesheet())
      }

    case "link":
      guard let href = tag.attributeForKey("href"),
        let type = tag.attributeForKey("type")?.lowercased(),
        type == "text/css"
      else { break }
      guard let stylesheetURL = URL(string: href, relativeTo: baseURL),
        stylesheetURL.isFileURL
      else {
        logger.warning("CSS link referencing a non-local target, ignored")
        break
      }
      if let content = try? String(contentsOf: stylesheetURL, encoding: .utf8) {
        globalStyleSheet.mergeStylesheet(CSSStylesheet(styleBlock: content))
      }

    default:
      break
    }
  }

  // MARK: - Found Characters

  private func handleFoundCharacters(_ string: String) {
    guard !ignoreParseEvents else { return }
    guard let current = currentTag else {
      assertionFailure("Cannot add text node without a current node")
      return
    }

    if !current.preserveNewlines && string.isIgnorableWhitespace {
      if current.displayStyle != .inline && current.children.isEmpty {
        return
      }
      if let previousTag = current.lastChild as? HTMLElement,
        previousTag.displayStyle != .inline
      {
        return
      }
      if current.lastChild is BreakHTMLElement {
        return
      }
    }

    let textNode = TextHTMLElement(name: "#TEXT#", attributes: nil)
    textNode.setText(string)
    textNode.inheritAttributes(from: current)
    textNode.interpretAttributes()
    current.addChildNode(textNode)

    // Text directly in body needs immediate output
    if current === bodyElement {
      if let attrStr = textNode.attributedString() { tmpString.append(attrStr) }
      current.didOutput = true

      if !shouldKeepDocumentNodeTree {
        current.removeChildNode(textNode)
      }
    }
  }

  // MARK: - Found CDATA

  private func handleFoundCDATA(_ data: Data) {
    guard !ignoreParseEvents, currentTag != nil else { return }
    guard let styleBlock = String(data: data, encoding: .utf8) else { return }
    let textNode = HTMLParserTextNode(characters: styleBlock)
    currentTag?.addChildNode(textNode)
  }

  // MARK: - End Document

  private func handleEndDocument() {
    if !preserveDocumentTrailingSpaces {
      while tmpString.dt_hasSuffixCharacter(from: .whitespaces) {
        tmpString.deleteCharacters(in: NSRange(location: tmpString.length - 1, length: 1))
      }
    }
  }

  // MARK: - Flushing

  private func flush(_ tag: HTMLElement) {
    guard tag.needsOutput() else { return }
    guard let nodeString = tag.attributedString() else { return }

    if tag.displayStyle != .inline {
      if tmpString.length > 0 {
        // Check last character without bridging the full backing store
        // into a Swift String — this is hot during large-document parses.
        let lastChar = tmpString.mutableString.character(at: tmpString.length - 1)
        if lastChar != 0x0A /* \n */ {
          while tmpString.dt_hasSuffixCharacter(
            from: NSCharacterSet.dt_ignorableWhitespaceCharacterSet)
          {
            tmpString.deleteCharacters(in: NSRange(location: tmpString.length - 1, length: 1))
          }
          tmpString.append(NSAttributedString(string: "\n"))
        }
      }
    }

    tmpString.append(nodeString)
    tag.didOutput = true

    if !shouldKeepDocumentNodeTree {
      tag.removeAllChildNodes()
    }
  }
}
