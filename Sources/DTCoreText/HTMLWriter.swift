//
//  HTMLWriter.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 23.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import CoreGraphics
import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// The Unicode object replacement character U+FFFC.
private let kUnicodeObjectPlaceholder = "\u{FFFC}"

/// Class to generate HTML from `NSAttributedString` instances.
@objc(DTHTMLWriter)
public class HTMLWriter: NSObject {

  // MARK: - Private Properties

  private let attributedStringStorage: NSAttributedString
  private var htmlDocumentCache: String?
  private var htmlFragmentCache: String?
  private var textScaleStorage: CGFloat = 1.0
  private var useAppleConvertedSpaceStorage: Bool = true
  private var styleLookup: [String: [String]] = [:]

  /// The HTML element tag name to use for paragraphs. Defaults to "p".
  @objc public var paragraphTagName: String = "p" {
    didSet {
      guard oldValue != paragraphTagName else { return }
      htmlDocumentCache = nil
      htmlFragmentCache = nil
    }
  }

  // MARK: - Init

  /// Creates a writer with a given `NSAttributedString` as input.
  @objc public init(attributedString: NSAttributedString) {
    // Up-migrate any legacy `DTTextListsAttribute` into `NSParagraphStyle.textLists`
    // so that the rest of the writer can read list info from a single source of truth.
    // For attributed strings produced by current DTCoreText code this is a cheap no-op.
    let mutable = attributedString.mutableCopy() as! NSMutableAttributedString
    mutable.dtct_migrateLegacyListAttribute()
    attributedStringStorage = mutable
    super.init()
  }

  // MARK: - Generating HTML

  private func _styleArray(forElement elementName: String) -> [String] {
    if let existing = styleLookup[elementName] {
      return existing
    }

    let styleArray: [String] = []
    styleLookup[elementName] = styleArray
    return styleArray
  }

  /// Checks the style against previous styles and returns the style class for this element/style pair.
  private func _styleClass(forElement elementName: String, style: String) -> String {
    // get array of styles for element
    var styleArray = styleLookup[elementName] ?? []

    var index: Int

    if let foundIndex = styleArray.firstIndex(of: style) {
      index = foundIndex + 1
    } else {
      // need to add this style
      styleArray.append(style)
      styleLookup[elementName] = styleArray
      index = styleArray.count
    }

    let prefix = String(elementName[elementName.startIndex])
    return "\(prefix)\(index)"
  }

  private func _tagRepresentation(
    forListStyle listStyle: DTTextList, closingTag: Bool, listPadding: CGFloat, inlineStyles: Bool
  ) -> String {
    let isOrdered = listStyle.isOrdered

    if closingTag {
      if isOrdered {
        return "</ol>"
      } else {
        return "</ul>"
      }
    } else {
      var typeString = listStyle.cssListStyleTypeString
      if listStyle.position == .inside {
        typeString += " inside"
      } else if listStyle.position == .outside {
        typeString += " outside"
      }

      let blockElement: String
      if isOrdered {
        blockElement = "ol"
      } else {
        blockElement = "ul"
      }

      var listStyleString = "list-style:'\(typeString)';"

      if listPadding > 0 {
        listStyleString += String(
          format: "-webkit-padding-start:%.0fpx;padding-left:%.0fpx;", listPadding, listPadding)
      }

      let className = _styleClass(forElement: blockElement, style: listStyleString)

      if inlineStyles {
        return "<\(blockElement) style=\"\(listStyleString)\">"
      } else {
        return "<\(blockElement) class=\"\(className)\">"
      }
    }
  }

  // MARK: - Table Tags

  /// CSS pixel string for a point value, without trailing fraction noise.
  private func _pixelString(_ value: CGFloat) -> String {
    if value == value.rounded() {
      return "\(Int(value))px"
    }
    return String(format: "%gpx", Double(value))
  }

  /// The border CSS for a block: a single shorthand when uniform, per-edge otherwise.
  private func _borderStyles(for block: TextBlock) -> String {
    let edges: [(CGRectEdge, String)] = [
      (.minYEdge, "top"), (.maxXEdge, "right"), (.maxYEdge, "bottom"), (.minXEdge, "left"),
    ]

    let widths = edges.map { block.width(for: .border, edge: $0.0) }
    guard widths.contains(where: { $0 > 0 }) else { return "" }

    func styleKeyword(for edge: CGRectEdge) -> String {
      switch block.borderStyle(for: edge) {
      case .dashed: return "dashed"
      case .dotted: return "dotted"
      case .double: return "double"
      case .solid: return "solid"
      }
    }

    func borderValue(width: CGFloat, edge: CGRectEdge) -> String {
      let hex = block.borderColor(for: edge).flatMap { DTHexStringFromDTColor($0) } ?? "000000"
      return "\(_pixelString(width)) \(styleKeyword(for: edge)) #\(hex)"
    }

    let colors = edges.map { block.borderColor(for: $0.0) }
    let styles2 = edges.map { block.borderStyle(for: $0.0) }
    let isUniform =
      widths.allSatisfy { $0 == widths[0] }
      && styles2.allSatisfy { $0 == styles2[0] }
      && colors.allSatisfy { color in
        color === colors[0] || (color != nil && colors[0] != nil && color! == colors[0]!)
      }

    if isUniform {
      return "border:\(borderValue(width: widths[0], edge: .minYEdge));"
    }

    var styles = ""
    for (index, (edge, name)) in edges.enumerated() where widths[index] > 0 {
      styles += "border-\(name):\(borderValue(width: widths[index], edge: edge));"
    }
    return styles
  }

  /// The dimension CSS for a block's width-related dimensions.
  private func _widthStyles(for block: TextBlock) -> String {
    var styles = ""

    let dimensions: [(TextBlock.Dimension, String)] = [
      (.width, "width"), (.minimumWidth, "min-width"), (.maximumWidth, "max-width"),
    ]

    for (dimension, name) in dimensions {
      let value = block.value(for: dimension)
      guard value > 0 else { continue }

      switch block.valueType(for: dimension) {
      case .percentageValueType:
        styles += "\(name):\(String(format: "%g", Double(value)))%;"
      case .absoluteValueType:
        styles += "\(name):\(_pixelString(value));"
      }
    }

    return styles
  }

  /// The opening tag for a table. The cell spacing rides on the cells as margins of
  /// half the spacing, so it is read off the table's first cell.
  private func _openingTableTag(for table: TextTable, firstCell: TextTableBlock) -> String {
    var styles = _widthStyles(for: table)

    if let backgroundColor = table.backgroundColor, let hex = DTHexStringFromDTColor(backgroundColor) {
      styles += "background-color:#\(hex);"
    }

    if table.collapsesBorders {
      styles += "border-collapse:collapse;"
    } else {
      // only when it differs from the 0.5pt margin (1px spacing) importer default
      let horizontal = firstCell.width(for: .margin, edge: .minXEdge) * 2
      let vertical = firstCell.width(for: .margin, edge: .minYEdge) * 2

      if horizontal != 1 || vertical != 1 {
        if horizontal == vertical {
          styles += "border-spacing:\(_pixelString(horizontal));"
        } else {
          styles += "border-spacing:\(_pixelString(horizontal)) \(_pixelString(vertical));"
        }
      }
    }
    if table.hidesEmptyCells {
      styles += "empty-cells:hide;"
    }
    if table.layoutAlgorithm == .fixedLayoutAlgorithm {
      styles += "table-layout:fixed;"
    }

    styles += _borderStyles(for: table)

    if styles.isEmpty {
      return "<table>"
    }
    return "<table style=\"\(styles)\">"
  }

  /// The opening tag for a table cell.
  private func _openingCellTag(for cell: TextTableBlock) -> String {
    var tag = "<td"

    if cell.columnSpan > 1 {
      tag += " colspan=\"\(cell.columnSpan)\""
    }
    if cell.rowSpan > 1 {
      tag += " rowspan=\"\(cell.rowSpan)\""
    }

    var styles = _widthStyles(for: cell)

    if let backgroundColor = cell.backgroundColor, let hex = DTHexStringFromDTColor(backgroundColor) {
      styles += "background-color:#\(hex);"
    }

    switch cell.verticalAlignment {
    case .topAlignment: styles += "vertical-align:top;"
    case .bottomAlignment: styles += "vertical-align:bottom;"
    case .baselineAlignment: styles += "vertical-align:baseline;"
    case .middleAlignment: break  // parser default
    }

    // padding: only when it differs from the 1pt importer default
    let paddingEdges: [CGRectEdge] = [.minYEdge, .maxXEdge, .maxYEdge, .minXEdge]
    let paddings = paddingEdges.map { cell.width(for: .padding, edge: $0) }

    if paddings.contains(where: { $0 != 1 }) {
      if paddings.allSatisfy({ $0 == paddings[0] }) {
        styles += "padding:\(_pixelString(paddings[0]));"
      } else {
        styles +=
          "padding:\(_pixelString(paddings[0])) \(_pixelString(paddings[1])) \(_pixelString(paddings[2])) \(_pixelString(paddings[3]));"
      }
    }

    styles += _borderStyles(for: cell)

    if !styles.isEmpty {
      tag += " style=\"\(styles)\""
    }

    return tag + ">"
  }

  private func _buildOutput() {
    _buildOutput(asHTMLFragment: false)
  }

  private func _buildOutput(asHTMLFragment fragment: Bool) {
    // reusable styles
    styleLookup = [:]

    let plainString = attributedStringStorage.string
    let nsPlainString = plainString as NSString

    // divide the string into its blocks (we assume that these are the P)
    let paragraphs = plainString.components(separatedBy: "\n")

    var retString = ""

    var location = 0

    var previousListStyles: [DTTextList]? = nil

    // stack of table cells the output is currently inside (outermost first), and the
    // number of <table> elements currently open in the output
    var openTableBlocks = [TextTableBlock]()
    var openEmittedTables = 0

    for i in 0..<paragraphs.count {
      let oneParagraph = paragraphs[i]
      let paragraphRange = NSRange(location: location, length: (oneParagraph as NSString).length)

      // skip empty paragraph at the end
      if i == paragraphs.count - 1 {
        if paragraphRange.length == 0 {
          continue
        }
      }

      var needsToRemovePrefix = false

      var fontIsBlockLevel = false

      // check if font is same in the entire paragraph
      var fontEffectiveRange = NSRange(location: 0, length: 0)

      let paragraphFont: CTFont?
      if paragraphRange.length > 0 {
        let fontKey = NSAttributedString.Key(rawValue: kCTFontAttributeName as String)
        paragraphFont =
          attributedStringStorage.attribute(
            fontKey, at: paragraphRange.location, longestEffectiveRange: &fontEffectiveRange,
            in: paragraphRange) as! CTFont?
      } else {
        paragraphFont = nil
      }

      if NSEqualRanges(paragraphRange, fontEffectiveRange) {
        fontIsBlockLevel = true
      }

      // next paragraph start
      location = location + paragraphRange.length + 1

      let paraAttributes = attributedStringStorage.attributes(
        at: paragraphRange.location, effectiveRange: nil)
      let paraAttributesDict = paraAttributes as NSDictionary

      // retrieve the paragraph style — it is now the canonical source for the list array
      let paragraphStyle = paraAttributesDict.dtct_paragraphStyle()

      // list styles live on the paragraph style's textLists array
      let currentListStyles = paragraphStyle?.textLists as? [DTTextList]

      // table cells ride on the DTTextBlocks attribute (outermost first)
      let currentTableBlocks =
        (paraAttributesDict.object(forKey: DTTextBlocksAttribute) as? [TextBlock])?
        .compactMap { $0 as? TextTableBlock } ?? []

      // common prefix of cells the paragraph stays inside, by instance identity
      var commonTableDepth = 0
      while commonTableDepth < min(openTableBlocks.count, currentTableBlocks.count),
        openTableBlocks[commonTableDepth] === currentTableBlocks[commonTableDepth]
      {
        commonTableDepth += 1
      }

      if openTableBlocks.count > commonTableDepth || currentTableBlocks.count > commonTableDepth {
        // lists never straddle a cell boundary — close any open lists first
        if let prevStyles = previousListStyles, !prevStyles.isEmpty {
          for closingStyle in prevStyles.reversed() {
            retString += _tagRepresentation(
              forListStyle: closingStyle, closingTag: true, listPadding: 0, inlineStyles: fragment)
            retString += "\n"
          }
          previousListStyles = nil
        }
      }

      // close cells that ended, innermost first
      while openTableBlocks.count > commonTableDepth {
        let closingCell = openTableBlocks.removeLast()
        retString += "</td>"

        let depth = openTableBlocks.count
        if currentTableBlocks.count > depth,
          currentTableBlocks[depth].table === closingCell.table
        {
          // the same table continues with another cell; its <table> stays open
          if currentTableBlocks[depth].startingRow != closingCell.startingRow {
            retString += "</tr>\n<tr>"
          }
        } else {
          retString += "</tr>\n</table>\n"
          openEmittedTables -= 1
        }
      }

      // open new tables and cells down to the current paragraph's cell
      while openTableBlocks.count < currentTableBlocks.count {
        let depth = openTableBlocks.count
        let openingCell = currentTableBlocks[depth]

        if openEmittedTables <= depth {
          // entering a new table
          retString += _openingTableTag(for: openingCell.table, firstCell: openingCell)
          retString += "\n<tr>"
          openEmittedTables = depth + 1
        }

        retString += _openingCellTag(for: openingCell)
        retString += "\n"
        openTableBlocks.append(openingCell)
      }

      let effectiveListStyle = currentListStyles?.last
      var paraStyleString: String? = nil

      if let paragraphStyle = paragraphStyle, effectiveListStyle == nil {
        if textScaleStorage != 1.0 {
          paragraphStyle.minimumLineHeight = round(paragraphStyle.minimumLineHeight / textScaleStorage)
          paragraphStyle.maximumLineHeight = round(paragraphStyle.maximumLineHeight / textScaleStorage)

          paragraphStyle.paragraphSpacing = round(paragraphStyle.paragraphSpacing / textScaleStorage)
          paragraphStyle.paragraphSpacingBefore = round(
            paragraphStyle.paragraphSpacingBefore / textScaleStorage)

          paragraphStyle.firstLineHeadIndent = round(
            paragraphStyle.firstLineHeadIndent / textScaleStorage)
          paragraphStyle.headIndent = round(paragraphStyle.headIndent / textScaleStorage)
          paragraphStyle.tailIndent = round(paragraphStyle.tailIndent / textScaleStorage)
        }

        paraStyleString = paragraphStyle.cssStyleRepresentation()
      }

      if paraStyleString == nil {
        paraStyleString = ""
      }

      if fontIsBlockLevel {
        if let paragraphFont = paragraphFont {
          let desc = CoreTextFontDescriptor(ctFont: paragraphFont)

          if textScaleStorage != 1.0 {
            desc.pointSize /= textScaleStorage
          }

          let paraFontStyle = desc.cssStyleRepresentation()

          if let paraFontStyle = paraFontStyle {
            paraStyleString = (paraStyleString ?? "") + paraFontStyle
          }
        }
      }

      var blockElement: String

      // Compute common prefix between previous and current list stacks using value equality.
      // This is robust regardless of whether list style objects share identity across paragraphs
      // (NSAttributedString may coalesce equal attribute values, breaking identity comparison).
      let prevStack = previousListStyles ?? []
      let currStack = currentListStyles ?? []
      var commonPrefixLen = 0
      let minStackLen = min(prevStack.count, currStack.count)
      while commonPrefixLen < minStackLen
        && prevStack[commonPrefixLen].isEqualTo(currStack[commonPrefixLen])
      {
        commonPrefixLen += 1
      }

      // Close lists from previous that are not in the common prefix (in reverse order).
      if prevStack.count > commonPrefixLen {
        for idx in stride(from: prevStack.count - 1, through: commonPrefixLen, by: -1) {
          let closingStyle = prevStack[idx]
          retString += _tagRepresentation(
            forListStyle: closingStyle, closingTag: true, listPadding: 0, inlineStyles: fragment)
          retString += "\n"
        }
      }

      if let effectiveListStyle = effectiveListStyle {
        // next text needs to have list prefix removed
        needsToRemovePrefix = true

        // Open lists from current that are not in the common prefix.
        if currStack.count > commonPrefixLen {
          let listPadding =
            ((paragraphStyle?.headIndent ?? 0) - (paragraphStyle?.firstLineHeadIndent ?? 0))
            / self.textScale

          for idx in commonPrefixLen..<currStack.count {
            let oneList = currStack[idx]

            // beginning of a list block
            retString += _tagRepresentation(
              forListStyle: oneList, closingTag: false, listPadding: listPadding,
              inlineStyles: fragment)
            retString += "\n"

            // all but the effective (innermost) list need an extra LI
            if !oneList.isEqualTo(effectiveListStyle) {
              retString += "<li>"
            }
          }
        }

        blockElement = "li"
      } else {
        blockElement = paragraphTagName
      }

      let headerLevel = paraAttributesDict.object(forKey: DTHeaderLevelAttribute) as? NSNumber

      if let headerLevel = headerLevel {
        blockElement = "h\(headerLevel.intValue)"
      }

      if i == paragraphs.count - 1 {
        // last paragraph in string
        if !plainString.hasSuffix("\n") {
          // not a whole paragraph, so we don't put it in P
          blockElement = "span"
        }
      }

      // find which custom attributes are for the entire paragraph
      let htmlAttributes = attributedStringStorage.htmlAttributes(at: paragraphRange.location)
      let paragraphLevelHTMLAttributes = NSMutableDictionary()

      if let htmlAttributes = htmlAttributes {
        for (key, value) in htmlAttributes {
          // check if range is longer than current paragraph
          let attributeEffectiveRange = attributedStringStorage.rangeOfHTMLAttribute(
            key, at: paragraphRange.location)

          if NSIntersectionRange(attributeEffectiveRange, paragraphRange).length
            == paragraphRange.length
          {
            paragraphLevelHTMLAttributes[key] = value
          }
        }
      }

      // Add dir="auto" if the writing direction is unknown
      if let paragraphStyle = paragraphStyle {
        switch paragraphStyle.baseWritingDirection {
        case .natural:
          paragraphLevelHTMLAttributes["dir"] = "auto"

        case .rightToLeft:
          paragraphLevelHTMLAttributes["dir"] = "rtl"

        case .leftToRight:
          // this is default, so we omit it
          break

        @unknown default:
          break
        }
      }

      // start paragraph start tag
      retString += "<\(blockElement)"

      // do we have style info?
      if let paraStyleString = paraStyleString, paraStyleString.count > 0 {
        if fragment {
          // stays style for fragment mode
          paragraphLevelHTMLAttributes["style"] = paraStyleString
        } else {
          // compress style for document mode
          var className = _styleClass(forElement: blockElement, style: paraStyleString)

          if let existingClasses = paragraphLevelHTMLAttributes["class"] as? String {
            var individualClasses = existingClasses.components(separatedBy: .whitespacesAndNewlines)

            // insert compressed class at index 0
            individualClasses.insert(className, at: 0)

            // rejoin
            className = individualClasses.joined(separator: " ")
          }

          paragraphLevelHTMLAttributes["class"] = className
        }
      }

      // add paragraph level attributes
      for (key, value) in paragraphLevelHTMLAttributes {
        retString += " \(key)=\"\(value)\""
      }

      // end paragraph start tag
      retString += ">"

      // add the attributed string ranges in this paragraph to the paragraph container

      var currentLinkRange = NSRange(location: NSNotFound, length: 0)

      var linkLevelHTMLAttributes: NSMutableDictionary? = nil

      // ----- SPAN enumeration

      attributedStringStorage.enumerateAttributes(in: paragraphRange, options: []) {
        [self] (attributes, spanRange, stopEnumerateAttributes) in

        let attributesDict = attributes as NSDictionary

        let spanURL = attributesDict.object(forKey: DTLinkAttribute) as? NSURL
        let spanAnchorName = attributesDict.object(forKey: DTAnchorAttribute) as? String

        var isFirstPartOfHyperlink = false
        var isLastPartOfHyperlink = false

        if (spanURL != nil || spanAnchorName != nil) && currentLinkRange.location == NSNotFound {
          if spanURL != nil {
            currentLinkRange = self.attributedString.rangeOfLink(at: spanRange.location, url: nil)
          } else if spanAnchorName != nil {
            currentLinkRange = self.attributedString.rangeOfAnchorNamed(spanAnchorName!)
          }

          isFirstPartOfHyperlink = true

          // build the attributes for the A tag
          linkLevelHTMLAttributes = NSMutableDictionary()

          if let spanURL = spanURL {
            linkLevelHTMLAttributes!["href"] = spanURL.relativeString
          }

          // add anchor name if present
          if let spanAnchorName = spanAnchorName {
            linkLevelHTMLAttributes!["name"] = spanAnchorName
          }

          // find which custom attributes are for the link
          if let localHTMLAttributes = self.attributedString.htmlAttributes(
            at: currentLinkRange.location)
          {
            for (key, value) in localHTMLAttributes {
              // check if range is longer than current paragraph
              let attributeEffectiveRange = self.attributedString.rangeOfHTMLAttribute(
                key, at: currentLinkRange.location)

              if NSEqualRanges(attributeEffectiveRange, currentLinkRange) {
                linkLevelHTMLAttributes![key] = value
              }
            }
          }
        }

        // check if the current link tag needs to be closed
        if currentLinkRange.location != NSNotFound
          && (NSMaxRange(spanRange) >= min(NSMaxRange(currentLinkRange), NSMaxRange(paragraphRange)))
        {
          isLastPartOfHyperlink = true
        }

        var plainSubString = nsPlainString.substring(with: spanRange)

        if effectiveListStyle != nil && needsToRemovePrefix {
          let prefixRange = self.attributedString.rangeOfField(at: spanRange.location)

          if prefixRange.location != NSNotFound {
            if NSMaxRange(prefixRange) < (plainSubString as NSString).length {
              plainSubString = (plainSubString as NSString).substring(
                from: NSMaxRange(prefixRange) - spanRange.location)
            } else {
              // avoid output of empty span tag, issue #601
              return
            }
          }

          needsToRemovePrefix = false
        }

        var subString: String? = plainSubString.addingHTMLEntities()

        if subString == nil {
          if isLastPartOfHyperlink {
            currentLinkRange = NSRange(location: NSNotFound, length: 0)
          }

          return
        }

        var attachment =
          attributesDict.object(forKey: NSAttributedString.Key.attachment.rawValue)
          as? NSTextAttachment

        if plainSubString == kUnicodeObjectPlaceholder {

          // if there was no old-style attachment let's try new NS-style.
          if attachment == nil {
            attachment = attributesDict.object(forKey: "NSAttachment") as? NSTextAttachment
          }

          // we don't want to output the placeholder character in any case
          subString = ""
        }

        if let attachment = attachment {
          if let persistableAttachment = attachment as? TextAttachmentHTMLPersistence {
            retString += persistableAttachment.stringByEncodingAsHTML()
          } else if let image = attachment.image,
                    let pngData = image.dataForPNGRepresentation() {
            // Plain `NSTextAttachment` with an image — emit a data-URL <img>.
            let encoded = pngData.base64EncodedString()
            let size = image.size
            retString +=
              "<img style=\"width:\(Int(size.width))px;height:\(Int(size.height))px;\" "
              + "src=\"data:image/png;base64,\(encoded)\" />"
          }

          if isLastPartOfHyperlink {
            currentLinkRange = NSRange(location: NSNotFound, length: 0)
          }

          return
        }

        var fontStyle: String? = nil
        if !fontIsBlockLevel {
          let fontDescriptor = attributesDict.dtct_fontDescriptor()

          if let fontDescriptor = fontDescriptor {
            if self.textScale != 1.0 {
              fontDescriptor.pointSize /= self.textScale
            }

            fontStyle = fontDescriptor.cssStyleRepresentation()
          }
        }

        if fontStyle == nil {
          fontStyle = ""
        }

        let kerning = attributesDict.dtct_kerning() / self.textScale

        if kerning != 0 {
          fontStyle = fontStyle! + String(format: "letter-spacing:%.0fpx;", kerning)
        }

        let textColor = attributesDict.dtct_foregroundColor()
        let hex = DTHexStringFromDTColor(textColor) ?? ""
        fontStyle = fontStyle! + "color:#\(hex);"

        let backgroundColor = attributesDict.dtct_backgroundColor()

        if let backgroundColor = backgroundColor {
          let hex = DTHexStringFromDTColor(backgroundColor) ?? ""
          fontStyle = fontStyle! + "background-color:#\(hex);"
        }

        let underlineKey = NSAttributedString.Key(
          rawValue: kCTUnderlineStyleAttributeName as String)
        let underline = attributes[underlineKey] as? NSNumber
        if underline != nil {
          fontStyle = fontStyle! + "text-decoration:underline;"
        } else {
          // there can be no underline and strike-through at the same time
          let strikeout =
            attributesDict.object(forKey: NSAttributedString.Key.strikethroughStyle) as? NSNumber
          if strikeout?.boolValue == true {
            fontStyle = fontStyle! + "text-decoration:line-through;"
          }
        }

        let superscriptKey = NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)
        let superscript = attributes[superscriptKey] as? NSNumber
        if let superscript = superscript {
          let style = superscript.intValue

          switch style {
          case 1:
            fontStyle = fontStyle! + "vertical-align:super;"

          case -1:
            fontStyle = fontStyle! + "vertical-align:sub;"

          default:
            // all other are baseline because we don't support anything else for text
            fontStyle = fontStyle! + "vertical-align:baseline;"
          }
        }

        let spanTagName = "span"

        var needsSpanTag = false

        // find which custom attributes are only for this span
        let localHTMLAttributes =
          attributesDict.object(forKey: DTCustomAttributesAttribute) as? NSDictionary
        let spanLevelHTMLAttributes = NSMutableDictionary()

        if let localHTMLAttributes = localHTMLAttributes {
          for (key, value) in localHTMLAttributes {
            guard let key = key as? String else { continue }

            // check if there is already an identical paragraph attribute
            let valueForParagraph = paragraphLevelHTMLAttributes[key]

            if let valueForParagraph = valueForParagraph {
              if fragment {
                if (valueForParagraph as AnyObject).isEqual(value) {
                  continue
                }
              } else {
                // need to check components
                if let paragraphValue = valueForParagraph as? String {
                  let paragraphClassComponents = paragraphValue.components(
                    separatedBy: .whitespacesAndNewlines)

                  if let valueStr = value as? String, paragraphClassComponents.contains(valueStr) {
                    continue
                  }
                }
              }
            }

            let attributeEffectiveRange = self.attributedString.rangeOfHTMLAttribute(
              key, at: spanRange.location)

            if currentLinkRange.location == NSNotFound
              || !NSEqualRanges(attributeEffectiveRange, currentLinkRange)
            {
              spanLevelHTMLAttributes[key] = value
              needsSpanTag = true
            }
          }
        }

        if let fontStyle = fontStyle, fontStyle.count > 0 {
          needsSpanTag = true

          if fragment {
            // stays style for fragment mode
            spanLevelHTMLAttributes["style"] = fontStyle
          } else {
            // compress style for document mode
            var className = self._styleClass(forElement: spanTagName, style: fontStyle)

            if let existingClasses = spanLevelHTMLAttributes["class"] as? String {
              var individualClasses = existingClasses.components(
                separatedBy: .whitespacesAndNewlines)

              // insert compressed class at index 0
              individualClasses.insert(className, at: 0)

              // rejoin
              className = individualClasses.joined(separator: " ")
            }

            spanLevelHTMLAttributes["class"] = className
          }
        }

        if isFirstPartOfHyperlink {
          // start link start tag
          retString += "<a"

          // add span level attributes
          if let linkLevelHTMLAttributes = linkLevelHTMLAttributes {
            for (key, value) in linkLevelHTMLAttributes {
              retString += " \(key)=\"\(value)\""
            }
          }

          // end span start tag
          retString += ">"
        }

        if needsSpanTag {
          // start span start tag
          retString += "<\(spanTagName)"

          // add span level attributes
          for (key, value) in spanLevelHTMLAttributes {
            retString += " \(key)=\"\(value)\""
          }

          // end span start tag
          retString += ">"
        }

        // add string in span
        retString += subString!

        if needsSpanTag {
          // span end tag
          retString += "</\(spanTagName)>"
        }

        if isLastPartOfHyperlink {
          retString += "</a>"
          currentLinkRange = NSRange(location: NSNotFound, length: 0)
        }
      }  // end of SPAN loop

      if blockElement == "li" {
        var shouldCloseLI = true

        let nextParagraphStart = NSMaxRange(nsPlainString.paragraphRange(for: paragraphRange))

        if nextParagraphStart < nsPlainString.length {
          let nextParaStyle =
            attributedStringStorage.attribute(
              .paragraphStyle, at: nextParagraphStart, effectiveRange: nil) as? NSParagraphStyle
          let nextListStyles = nextParaStyle?.textLists as? [DTTextList]

          // LI are only closed if there is not a deeper list level following
          if let nextListStyles = nextListStyles,
            let effective = effectiveListStyle,
            nextListStyles.contains(where: { $0.isEqualTo(effective) }),
            nextListStyles.count > (currentListStyles?.count ?? 0)
          {
            // deeper list following
            shouldCloseLI = false
          }
        }

        if shouldCloseLI {
          retString += "</li>"
        }
      } else {
        // other blocks are always closed
        retString += "</\(blockElement)>\n"
      }

      previousListStyles = currentListStyles
    }  // end of P loop

    // close list if still open
    if let prevStyles = previousListStyles, prevStyles.count > 0 {
      var closingStyles = prevStyles

      repeat {
        guard let closingStyle = closingStyles.last else { break }

        // end of a list block
        retString += _tagRepresentation(
          forListStyle: closingStyle, closingTag: true, listPadding: 0, inlineStyles: fragment)
        retString += "\n"

        if closingStyles.count > 1 {
          retString += "</li>"
        }

        closingStyles.removeLast()
      } while closingStyles.count > 0
    }

    // close tables that are still open at the end of the string, innermost first
    while !openTableBlocks.isEmpty {
      openTableBlocks.removeLast()
      retString += "</td></tr>\n</table>\n"
      openEmittedTables -= 1
    }

    var output = ""

    let hasTab = retString.contains("\t")

    if !fragment {
      // append style block before text
      var styleBlock = ""

      let keys = styleLookup.keys.sorted()

      for oneKey in keys {
        if let styleArray = styleLookup[oneKey] {
          for (idx, style) in styleArray.enumerated() {
            let className = "\(String(oneKey[oneKey.startIndex]))\(idx + 1)"
            styleBlock += "\(oneKey).\(className) {\(style)}\n"
          }
        }
      }

      if hasTab {
        styleBlock += "span.Apple-tab-span {white-space:pre;}"
      }

      output +=
        "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html40/strict.dtd\">\n<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n<meta http-equiv=\"Content-Style-Type\" content=\"text/css\" />\n<meta name=\"Generator\" content=\"DTCoreText HTML Writer\" />\n<style type=\"text/css\">\n\(styleBlock)</style>\n</head>\n<body>\n"
    }

    if hasTab {
      if fragment {
        retString = retString.replacingOccurrences(
          of: "\t", with: "<span style=\"white-space:pre;\">\t</span>")
      } else {
        retString = retString.replacingOccurrences(
          of: "\t", with: "<span class=\"Apple-tab-span\">\t</span>")
      }
    }

    if useAppleConvertedSpaceStorage {
      output += retString.addingAppleConvertedSpace()
    } else {
      output += retString
    }

    if !fragment {
      output += "</body>\n</html>\n"
    }

    if fragment {
      htmlFragmentCache = output
    } else {
      htmlDocumentCache = output
    }
  }

  // MARK: - Public

  /// Generates a HTML representation of the attributed string.
  @objc(HTMLString)
  public func htmlString() -> String {
    if htmlDocumentCache == nil {
      _buildOutput()
    }

    return htmlDocumentCache!
  }

  /// Generates a HTML fragment representation of the attributed string including inlined styles and no html or head elements.
  @objc(HTMLFragment)
  public func htmlFragment() -> String {
    if htmlFragmentCache == nil {
      _buildOutput(asHTMLFragment: true)
    }

    return htmlFragmentCache!
  }

  // MARK: - Properties

  /// The attributed string that the writer is processing.
  @objc public var attributedString: NSAttributedString {
    return attributedStringStorage
  }

  /// If specified then all absolute font sizes (px) will be divided by this value.
  @objc public var textScale: CGFloat {
    get { return textScaleStorage }
    set {
      guard textScaleStorage != newValue else { return }
      textScaleStorage = newValue
      htmlDocumentCache = nil
      htmlFragmentCache = nil
    }
  }

  /// If YES, preserve whitespaces in HTML by using "Apple-converted-space". Default YES.
  @objc public var useAppleConvertedSpace: Bool {
    get { return useAppleConvertedSpaceStorage }
    set {
      guard useAppleConvertedSpaceStorage != newValue else { return }
      useAppleConvertedSpaceStorage = newValue
      htmlDocumentCache = nil
      htmlFragmentCache = nil
    }
  }
}
