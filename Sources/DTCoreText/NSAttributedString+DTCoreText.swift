//
//  NSAttributedString+DTCoreText.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import CoreText
import Foundation

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(macOS)
  import AppKit
#endif

// NS-style attributes are always used on iOS 16+ / macOS 13+.

// MARK: - NSAttributedString (DTCoreText)

extension NSAttributedString {

  // MARK: Text Attachments

  /// Retrieves the `TextAttachment` objects that match the given predicate.
  ///
  /// With this method you can for example find all images that have a certain URL.
  ///
  /// - Parameters:
  ///   - predicate: The predicate to apply for filtering or `nil` to not filter by attachment.
  ///   - theClass: The class that attachments need to have, or `nil` for all attachments regardless of class.
  /// - Returns: The filtered array of attachments, or `nil` if none found.
  @objc
  public func textAttachments(with predicate: NSPredicate?, `class` theClass: AnyClass?)
    -> [TextAttachment]?
  {
    guard self.length > 0 else {
      return nil
    }

    var foundAttachments = [TextAttachment]()

    let entireRange = NSRange(location: 0, length: self.length)
    self.enumerateAttribute(
      .attachment, in: entireRange, options: .longestEffectiveRangeNotRequired
    ) { value, _, _ in
      guard let attachment = value as? TextAttachment else {
        return
      }

      if let predicate, !predicate.evaluate(with: attachment) {
        return
      }

      if let theClass, !attachment.isKind(of: theClass) {
        return
      }

      foundAttachments.append(attachment)
    }

    return foundAttachments.isEmpty ? nil : foundAttachments
  }

  // MARK: - Paragraph-style list helpers

  /// Returns the `NSTextList` array for the paragraph that contains `location`, reading
  /// from `NSParagraphStyle.textLists` (the canonical source). Returns `nil` if the
  /// paragraph has no list metadata.
  fileprivate func _textListsForParagraph(at location: Int) -> [NSTextList]? {
    guard location >= 0, location < length else { return nil }
    guard
      let ps = self.attribute(.paragraphStyle, at: location, effectiveRange: nil)
        as? NSParagraphStyle
    else {
      return nil
    }
    return ps.textLists.isEmpty ? nil : ps.textLists
  }

  /// Finds the full range of paragraphs that share the given `list` object on their
  /// `NSParagraphStyle.textLists`. Uses `NSTextList.isEqual(_:)` for comparison — for
  /// `DTTextList` this delegates to `isEqualTo(_:)` (value equality), which is robust
  /// against attribute coalescing stripping instance identity.
  fileprivate func _rangeOfTextListByParagraph(_ list: NSTextList, at location: Int) -> NSRange {
    let nsString = self.string as NSString
    let stringLength = self.length
    guard location >= 0, location < stringLength else {
      return NSRange(location: NSNotFound, length: 0)
    }

    func containsList(_ lists: [NSTextList]) -> Bool {
      return lists.contains(where: { $0.isEqual(list) })
    }

    // Confirm the starting paragraph contains this list.
    guard let startLists = _textListsForParagraph(at: location), containsList(startLists) else {
      return NSRange(location: NSNotFound, length: 0)
    }

    // Walk backwards paragraph-by-paragraph while the list is still present.
    var totalRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
    while totalRange.location > 0 {
      let prevEnd = totalRange.location - 1
      let prevPara = nsString.paragraphRange(for: NSRange(location: prevEnd, length: 0))
      guard let prevLists = _textListsForParagraph(at: prevPara.location),
        containsList(prevLists)
      else {
        break
      }
      totalRange = NSUnionRange(prevPara, totalRange)
    }

    // Walk forwards paragraph-by-paragraph while the list is still present.
    while NSMaxRange(totalRange) < stringLength {
      let nextStart = NSMaxRange(totalRange)
      let nextPara = nsString.paragraphRange(for: NSRange(location: nextStart, length: 0))
      guard let nextLists = _textListsForParagraph(at: nextPara.location),
        containsList(nextLists)
      else {
        break
      }
      totalRange = NSUnionRange(totalRange, nextPara)
    }

    return totalRange
  }

  // MARK: Calculating Ranges

  /// Returns the index of the item at the given location within the list.
  ///
  /// - Parameters:
  ///   - list: The text list.
  ///   - location: The location of the item.
  /// - Returns: The index within the list.
  public func itemNumber(in list: NSTextList, atIndex location: Int) -> Int {
    guard let textListsAtIndex = self._textListsForParagraph(at: location), !textListsAtIndex.isEmpty
    else {
      return 0
    }

    // get outermost list
    let outermostList = textListsAtIndex[0]

    // get the range of all lists
    let totalRange = self.dtct_rangeOfTextList(outermostList, atIndex: location)

    // get naked NSString
    let string = (self.string as NSString).substring(with: totalRange)

    // entire string
    let range = NSRange(location: 0, length: (string as NSString).length)

    var countersPerList = [NSNumber: NSNumber]()

    // enumerating through the paragraphs in the plain text string
    (string as NSString).enumerateSubstrings(in: range, options: .byParagraphs) {
      _, substringRange, enclosingRange, stop in
      let textLists = self._textListsForParagraph(
        at: substringRange.location + totalRange.location)

      guard let currentEffectiveList = textLists?.last else {
        return
      }

      // list address is identifier
      let key = NSNumber(
        integerLiteral: Int(bitPattern: Unmanaged.passUnretained(currentEffectiveList).toOpaque()))
      let currentCounterNum = countersPerList[key]

      var currentCounter: Int

      if currentCounterNum == nil {
        // Unordered lists carry `startingItemNumber == 0` (Apple's convention meaning
        // "not ordered") — treat that as 1 so counting still yields a 1-based index.
        currentCounter = max(currentEffectiveList.startingItemNumber, 1)
      } else {
        currentCounter = currentCounterNum!.intValue + 1
      }

      countersPerList[key] = NSNumber(value: currentCounter)

      // calculate the actual range
      var actualRange = enclosingRange  // includes a potential \n
      actualRange.location += totalRange.location

      if NSLocationInRange(location, actualRange) {
        stop.pointee = true
      }
    }

    // list address is identifier
    let key = NSNumber(integerLiteral: Int(bitPattern: Unmanaged.passUnretained(list).toOpaque()))
    let currentCounterNum = countersPerList[key]

    return currentCounterNum?.intValue ?? 0
  }

  /// Private helper to find the range of an object in an array-valued attribute.
  private func _rangeOfObject(
    _ object: AnyObject, inArrayBehindAttribute attribute: String, at location: Int
  ) -> NSRange {
    let stringLength = self.length
    var searchIndex = location

    var totalRange = NSRange(location: NSNotFound, length: 0)

    var foundList = false

    repeat {
      var effectiveRange = NSRange(location: 0, length: 0)
      let arrayAtIndex =
        self.attribute(
          NSAttributedString.Key(rawValue: attribute), at: searchIndex,
          effectiveRange: &effectiveRange) as? [AnyObject]

      if arrayAtIndex == nil || arrayAtIndex!.firstIndex(where: { $0 === object }) == nil {
        break
      }

      searchIndex = effectiveRange.location
      foundList = true

      // enhance found range
      if totalRange.location == NSNotFound {
        totalRange = effectiveRange
      } else {
        totalRange = NSUnionRange(totalRange, effectiveRange)
      }

      if searchIndex == 0 {
        // reached beginning of string
        break
      }

      searchIndex -= 1
    } while foundList

    // if we didn't find the list at all, return
    if !foundList {
      return NSRange(location: NSNotFound, length: 0)
    }

    // now search forward
    searchIndex = NSMaxRange(totalRange)

    while searchIndex < stringLength {
      var effectiveRange = NSRange(location: 0, length: 0)
      let arrayAtIndex =
        self.attribute(
          NSAttributedString.Key(rawValue: attribute), at: searchIndex,
          effectiveRange: &effectiveRange) as? [AnyObject]

      if arrayAtIndex == nil || arrayAtIndex!.firstIndex(where: { $0 === object }) == nil {
        break
      }

      searchIndex = NSMaxRange(effectiveRange)

      // enhance found range
      totalRange = NSUnionRange(totalRange, effectiveRange)
    }

    return totalRange
  }

  /// Returns the range of the given text list that contains the given location.
  ///
  /// - Parameters:
  ///   - list: The text list.
  ///   - location: The location in the text.
  /// - Returns: The range of the given text list containing the location.
  public func dtct_rangeOfTextList(_ list: NSTextList, atIndex location: Int) -> NSRange {
    return _rangeOfTextListByParagraph(list, at: location)
  }

  /// Returns the range of the given text block that contains the given location.
  ///
  /// - Parameters:
  ///   - textBlock: The text block.
  ///   - location: The location in the text.
  /// - Returns: The range of the given text block containing the location.
  @objc
  public func rangeOfTextBlock(_ textBlock: TextBlock, at location: Int) -> NSRange {
    precondition(textBlock !== nil as AnyObject?, "textBlock must not be nil")

    return _rangeOfObject(textBlock, inArrayBehindAttribute: DTTextBlocksAttribute, at: location)
  }

  /// Returns the range of the given href anchor.
  ///
  /// - Parameters:
  ///   - anchorName: The name of the anchor.
  /// - Returns: The range of the given anchor.
  @objc
  public func rangeOfAnchorNamed(_ anchorName: String) -> NSRange {
    var foundRange = NSRange(location: NSNotFound, length: 0)

    self.enumerateAttribute(
      NSAttributedString.Key(rawValue: DTAnchorAttribute),
      in: NSRange(location: 0, length: self.length), options: []
    ) { value, range, stop in
      if let value = value as? String, value == anchorName {
        stop.pointee = true
        foundRange = range
      }
    }

    return foundRange
  }

  /// Returns the range of the hyperlink at the given index.
  ///
  /// - Parameters:
  ///   - location: The location to query.
  ///   - URL: On output, the URL that is found at this location.
  /// - Returns: The range of the given hyperlink.
  @objc
  public func rangeOfLink(at location: Int, url: AutoreleasingUnsafeMutablePointer<NSURL?>?)
    -> NSRange
  {
    var rangeSoFar = NSRange(location: 0, length: 0)

    guard
      let foundURL = self.attribute(
        NSAttributedString.Key(rawValue: DTLinkAttribute), at: location, effectiveRange: &rangeSoFar
      ) as? NSURL
    else {
      return NSRange(location: NSNotFound, length: 0)
    }

    // search towards beginning
    while rangeSoFar.location > 0 {
      var extendedRange = NSRange(location: 0, length: 0)
      let extendedURL =
        self.attribute(
          NSAttributedString.Key(rawValue: DTLinkAttribute), at: rangeSoFar.location - 1,
          effectiveRange: &extendedRange) as? NSURL

      // abort search if key not found or value not identical
      if extendedURL == nil || !extendedURL!.isEqual(foundURL) {
        break
      }

      rangeSoFar = NSUnionRange(rangeSoFar, extendedRange)
    }

    let length = self.length

    // search towards end
    while NSMaxRange(rangeSoFar) < length {
      var extendedRange = NSRange(location: 0, length: 0)
      let extendedURL =
        self.attribute(
          NSAttributedString.Key(rawValue: DTLinkAttribute), at: NSMaxRange(rangeSoFar),
          effectiveRange: &extendedRange) as? NSURL

      // abort search if key not found or value not identical
      if extendedURL == nil || !extendedURL!.isEqual(foundURL) {
        break
      }

      rangeSoFar = NSUnionRange(rangeSoFar, extendedRange)
    }

    url?.pointee = foundURL

    return rangeSoFar
  }

  /// Returns the range of a field at the given index.
  ///
  /// - Parameter location: The location of the field.
  /// - Returns: The range of the field. If there is no field at this location it returns `{NSNotFound, 0}`.
  @objc
  public func rangeOfField(at location: Int) -> NSRange {
    if location < self.length {
      // get range of prefix
      var fieldRange = NSRange(location: 0, length: 0)
      let fieldAttribute =
        self.attribute(
          NSAttributedString.Key(rawValue: DTFieldAttribute), at: location,
          effectiveRange: &fieldRange) as? String

      if fieldAttribute != nil {
        return fieldRange
      }
    }

    return NSRange(location: NSNotFound, length: 0)
  }

  // MARK: HTML Encoding

  /// Converts the receiver into plain text.
  ///
  /// This is different from the `string` method of `NSAttributedString` by also erasing
  /// placeholders for text attachments.
  ///
  /// - Returns: The receiver converted to plain text.
  @objc
  public var plainTextString: String {
    return self.string.replacingOccurrences(of: UNICODE_OBJECT_PLACEHOLDER, with: "")
  }

  // MARK: Generating Special Attributed Strings

  /// Create a prefix for a paragraph in a list.
  ///
  /// - Parameters:
  ///   - listCounter: The value for the list item.
  ///   - listStyle: The list style.
  ///   - listIndent: The amount in px to indent the list.
  ///   - attributes: The attribute dictionary for the text to be prefixed.
  /// - Returns: An attributed string with the list prefix.
  public static func prefixForListItem(
    withCounter listCounter: UInt, listStyle: DTTextList, listIndent: CGFloat,
    attributes: [String: Any]
  ) -> NSAttributedString? {
    // get existing values from attributes
    let ctParagraphStyleKey = NSAttributedString.Key(
      rawValue: kCTParagraphStyleAttributeName as String)
    let ctFontKey = NSAttributedString.Key(rawValue: kCTFontAttributeName as String)

    let paraStyle = attributes[kCTParagraphStyleAttributeName as String] as CFTypeRef?
    let fontRef = attributes[kCTFontAttributeName as String] as CFTypeRef?

    var fontDescriptor: CoreTextFontDescriptor?
    var paragraphStyle: CoreTextParagraphStyle?

    if let paraStyle {
      let ctParaStyle = unsafeDowncast(paraStyle, to: CTParagraphStyle.self)
      paragraphStyle = CoreTextParagraphStyle(ctParagraphStyle: ctParaStyle)

      paragraphStyle!.tabStops = nil
      paragraphStyle!.headIndent = listIndent

      if listStyle.hasMarker {
        // first tab is to right-align bullet, numbering against
        let tabOffset = paragraphStyle!.headIndent - 5.0
        paragraphStyle!.addTabStop(at: tabOffset, alignment: CTTextAlignment.right)
      }

      // second tab is for the beginning of first line after bullet
      paragraphStyle!.addTabStop(at: paragraphStyle!.headIndent, alignment: CTTextAlignment.left)

      // Preserve list metadata from the caller's original paragraph style. CT paragraph
      // styles don't carry NSTextList info, so reach into the NSParagraphStyle (or the
      // legacy DTTextListsAttribute) on the attributes dict directly.
      if let nsPS = attributes[NSAttributedString.Key.paragraphStyle.rawValue]
        as? NSParagraphStyle, !nsPS.textLists.isEmpty
      {
        paragraphStyle!.textLists = nsPS.textLists
      } else if let legacyLists = attributes[DTTextListsAttribute] as? [NSTextList] {
        paragraphStyle!.textLists = legacyLists
      } else {
        // Last resort: the only list we definitely know about is the one passed in.
        paragraphStyle!.textLists = [listStyle]
      }
    }

    if let fontRef {
      let ctFont = unsafeDowncast(fontRef, to: CTFont.self)
      fontDescriptor = CoreTextFontDescriptor(ctFont: ctFont)
    }

    var newAttributes = [NSAttributedString.Key: Any]()

    if let fontDescriptor {
      // make a font without italic or bold
      let fontDesc = fontDescriptor.copy() as! CoreTextFontDescriptor

      fontDesc.boldTrait = false
      fontDesc.italicTrait = false

      let newFont = fontDesc.newMatchingFont()

      if let newFont {
        if true {
          #if os(iOS) || os(tvOS)
            let uiFont = UIFont.font(with: newFont)
            newAttributes[.font] = uiFont
          #endif
        } else {
          newAttributes[ctFontKey] = newFont
        }
      }
    }

    let ctForegroundColorKey = NSAttributedString.Key(
      rawValue: kCTForegroundColorAttributeName as String)
    let textColor = attributes[kCTForegroundColorAttributeName as String] as CFTypeRef?

    if let textColor {
      newAttributes[ctForegroundColorKey] = textColor
    } else if true {
      let attributesDict = attributes as NSDictionary
      let uiColor = attributesDict.dtct_foregroundColor()
      newAttributes[.foregroundColor] = uiColor
    }

    // add paragraph style (this has the tabs)
    if let paragraphStyle {
      if true {
        let style = paragraphStyle.nsParagraphStyle()
        newAttributes[.paragraphStyle] = style
      } else {
        let newParagraphStyle = paragraphStyle.createCTParagraphStyle()
        newAttributes[ctParagraphStyleKey] = newParagraphStyle
      }
    }

    // add textBlock if there's one (this has padding and background color)
    if let textBlocks = attributes[DTTextBlocksAttribute] {
      newAttributes[NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] = textBlocks
    }

    // list metadata now rides on the paragraph style (added above), so no separate
    // DTTextListsAttribute transfer is needed.

    // add a marker so that we know that this is a field/prefix
    newAttributes[NSAttributedString.Key(rawValue: DTFieldAttribute)] = DTListPrefixField

    let prefix = listStyle.formattedMarker(forItemNumber: Int(listCounter))

    guard let prefix else {
      return nil
    }

    let tmpStr = NSMutableAttributedString(string: prefix, attributes: newAttributes)

    #if os(iOS) || os(tvOS)
      var image: DTImage?

      if let imageName = listStyle.imageName {
        image = DTImage(named: imageName)

        if image == nil {
          // image invalid
          listStyle.imageName = nil
          // prefix was already obtained above; re-obtain is not needed since
          // the prefix string doesn't change from image name removal in this path
        }
      }

      if let image {
        // make an attachment for the image
        let attachment = ImageTextAttachment()
        attachment.image = image
        attachment.displaySize = image.size

        // need run delegate for sizing
        if let embeddedObjectRunDelegate = createEmbeddedObjectRunDelegate(attachment) {
          newAttributes[NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)] =
            embeddedObjectRunDelegate
        }

        // add attachment
        newAttributes[.attachment] = attachment

        if listStyle.position == .inside {
          tmpStr.setAttributes(newAttributes, range: NSRange(location: 2, length: 1))
        } else {
          tmpStr.setAttributes(newAttributes, range: NSRange(location: 1, length: 1))
        }
      }
    #endif

    return tmpStr
  }
}
