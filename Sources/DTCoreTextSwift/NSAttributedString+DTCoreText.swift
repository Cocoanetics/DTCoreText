//
//  NSAttributedString+DTCoreText.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 2/1/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import Foundation
import CoreText

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
	public func textAttachments(with predicate: NSPredicate?, `class` theClass: AnyClass?) -> [TextAttachment]? {
		guard self.length > 0 else {
			return nil
		}

		var foundAttachments = [TextAttachment]()

		let entireRange = NSRange(location: 0, length: self.length)
		self.enumerateAttribute(.attachment, in: entireRange, options: .longestEffectiveRangeNotRequired) { value, _, _ in
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

	// MARK: Calculating Ranges

	/// Returns the index of the item at the given location within the list.
	///
	/// - Parameters:
	///   - list: The text list.
	///   - location: The location of the item.
	/// - Returns: The index within the list.
	@objc
	public func itemNumber(in list: CSSListStyle, at location: Int) -> Int {
		var effectiveRange = NSRange(location: 0, length: 0)
		guard let textListsAtIndex = self.attribute(NSAttributedString.Key(rawValue: DTTextListsAttribute), at: location, effectiveRange: &effectiveRange) as? [CSSListStyle] else {
			return 0
		}

		// get outermost list
		let outermostList = textListsAtIndex[0]

		// get the range of all lists
		let totalRange = self.rangeOfTextList(outermostList, at: location)

		// get naked NSString
		let string = (self.string as NSString).substring(with: totalRange)

		// entire string
		let range = NSRange(location: 0, length: (string as NSString).length)

		var countersPerList = [NSNumber: NSNumber]()

		// enumerating through the paragraphs in the plain text string
		(string as NSString).enumerateSubstrings(in: range, options: .byParagraphs) { _, substringRange, enclosingRange, stop in
			var paragraphListRange = NSRange(location: 0, length: 0)
			let textLists = self.attribute(NSAttributedString.Key(rawValue: DTTextListsAttribute), at: substringRange.location + totalRange.location, effectiveRange: &paragraphListRange) as? [CSSListStyle]

			guard let currentEffectiveList = textLists?.last else {
				return
			}

			// list address is identifier
			let key = NSNumber(integerLiteral: Int(bitPattern: Unmanaged.passUnretained(currentEffectiveList).toOpaque()))
			let currentCounterNum = countersPerList[key]

			var currentCounter: Int

			if currentCounterNum == nil {
				currentCounter = currentEffectiveList.startingItemNumber()
			} else {
				currentCounter = currentCounterNum!.intValue + 1
			}

			countersPerList[key] = NSNumber(value: currentCounter)

			// calculate the actual range
			var actualRange = enclosingRange // includes a potential \n
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
	private func _rangeOfObject(_ object: AnyObject, inArrayBehindAttribute attribute: String, at location: Int) -> NSRange {
		let lock = NSLock()
		lock.lock()
		defer { lock.unlock() }

		let stringLength = self.length
		var searchIndex = location

		var totalRange = NSRange(location: NSNotFound, length: 0)

		var foundList = false

		repeat {
			var effectiveRange = NSRange(location: 0, length: 0)
			let arrayAtIndex = self.attribute(NSAttributedString.Key(rawValue: attribute), at: searchIndex, effectiveRange: &effectiveRange) as? [AnyObject]

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
			let arrayAtIndex = self.attribute(NSAttributedString.Key(rawValue: attribute), at: searchIndex, effectiveRange: &effectiveRange) as? [AnyObject]

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
	@objc
	public func rangeOfTextList(_ list: CSSListStyle, at location: Int) -> NSRange {
		precondition(list !== nil as AnyObject?, "list must not be nil")

		var listRange = _rangeOfObject(list, inArrayBehindAttribute: DTTextListsAttribute, at: location)

		if listRange.location == NSNotFound {
			// list was not found
			return listRange
		}

		// extend list range to full paragraphs to be safe
		listRange = (self.string as NSString).range(ofParagraphsContaining: listRange, parBeg: nil, parEnd: nil)

		return listRange
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

		self.enumerateAttribute(NSAttributedString.Key(rawValue: DTAnchorAttribute), in: NSRange(location: 0, length: self.length), options: []) { value, range, stop in
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
	public func rangeOfLink(at location: Int, url: AutoreleasingUnsafeMutablePointer<NSURL?>?) -> NSRange {
		var rangeSoFar = NSRange(location: 0, length: 0)

		guard let foundURL = self.attribute(NSAttributedString.Key(rawValue: DTLinkAttribute), at: location, effectiveRange: &rangeSoFar) as? NSURL else {
			return NSRange(location: NSNotFound, length: 0)
		}

		// search towards beginning
		while rangeSoFar.location > 0 {
			var extendedRange = NSRange(location: 0, length: 0)
			let extendedURL = self.attribute(NSAttributedString.Key(rawValue: DTLinkAttribute), at: rangeSoFar.location - 1, effectiveRange: &extendedRange) as? NSURL

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
			let extendedURL = self.attribute(NSAttributedString.Key(rawValue: DTLinkAttribute), at: NSMaxRange(rangeSoFar), effectiveRange: &extendedRange) as? NSURL

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
			let fieldAttribute = self.attribute(NSAttributedString.Key(rawValue: DTFieldAttribute), at: location, effectiveRange: &fieldRange) as? String

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
	@objc
	public static func prefixForListItem(withCounter listCounter: UInt, listStyle: CSSListStyle, listIndent: CGFloat, attributes: [String: Any]) -> NSAttributedString? {
		// get existing values from attributes
		let ctParagraphStyleKey = NSAttributedString.Key(rawValue: kCTParagraphStyleAttributeName as String)
		let ctFontKey = NSAttributedString.Key(rawValue: kCTFontAttributeName as String)

		let paraStyle = attributes[kCTParagraphStyleAttributeName as String] as CFTypeRef?
		let fontRef = attributes[kCTFontAttributeName as String] as CFTypeRef?

		var fontDescriptor: CoreTextFontDescriptor?
		var paragraphStyle: CoreTextParagraphStyle?

		if let paraStyle {
			let ctParaStyle = unsafeBitCast(paraStyle, to: CTParagraphStyle.self)
			paragraphStyle = CoreTextParagraphStyle(ctParagraphStyle: ctParaStyle)

			paragraphStyle!.tabStops = nil
			paragraphStyle!.headIndent = listIndent

			if listStyle.type != .none {
				// first tab is to right-align bullet, numbering against
				let tabOffset = paragraphStyle!.headIndent - 5.0
				paragraphStyle!.addTabStop(atPosition: tabOffset, alignment: CTTextAlignment.right)
			}

			// second tab is for the beginning of first line after bullet
			paragraphStyle!.addTabStop(atPosition: paragraphStyle!.headIndent, alignment: CTTextAlignment.left)
		}

		if let fontRef {
			let ctFont = unsafeBitCast(fontRef, to: CTFont.self)
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
					let uiFont = UIFont.font(withCTFont: newFont)
					newAttributes[.font] = uiFont
					#endif
				} else {
					newAttributes[ctFontKey] = newFont
				}
			}
		}

		let ctForegroundColorKey = NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String)
		let textColor = attributes[kCTForegroundColorAttributeName as String] as CFTypeRef?

		if let textColor {
			newAttributes[ctForegroundColorKey] = textColor
		} else if true {
			let attributesDict = attributes as NSDictionary
			let uiColor = attributesDict.foregroundColor()

			if let uiColor {
				newAttributes[.foregroundColor] = uiColor
			}
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

		// transfer all lists
		if let lists = attributes[DTTextListsAttribute] {
			newAttributes[NSAttributedString.Key(rawValue: DTTextListsAttribute)] = lists
		}

		// add a marker so that we know that this is a field/prefix
		newAttributes[NSAttributedString.Key(rawValue: DTFieldAttribute)] = DTListPrefixField

		let prefix = listStyle.prefix(withCounter: Int(listCounter))

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
				newAttributes[NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String)] = embeddedObjectRunDelegate
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
