import Testing
import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("NSAttributedString+DTCoreText", .serialized)
struct AttributedStringDTCoreTextTests {
	@Test("Range of named anchor")
	func rangeOfAnchor() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some text</p><a name=\"anchor\">anchor</a><p>more text</p>")!

		let range = attributedString.rangeOfAnchorNamed("anchor")
		#expect(range == NSRange(location: 10, length: 6))

		let notFound = attributedString.rangeOfAnchorNamed("something")
		#expect(notFound == NSRange(location: NSNotFound, length: 0))
	}

	@Test("Text block range")
	func textBlockRange() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some text</p><div style=\"background-color:red\">inside</div><p>following</p>")!

		let innerRange = (attributedString.string as NSString).range(of: "inside\n")
		let innerAttributes = attributedString.attributes(at: innerRange.location, effectiveRange: nil)
		let blocks = innerAttributes[NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] as! [TextBlock]
		#expect(blocks.count == 1)
		let effectiveBlock = blocks.first!

		let newBlock = TextBlock()
		#if canImport(UIKit)
		newBlock.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		#else
		newBlock.padding = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		#endif

		// test other block inside range
		var nonFoundRange = attributedString.rangeOfTextBlock(newBlock, at: innerRange.location)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test other block outside range
		nonFoundRange = attributedString.rangeOfTextBlock(newBlock, at: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test effective block outside range
		nonFoundRange = attributedString.rangeOfTextBlock(effectiveBlock, at: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test effective block inside range
		let foundRange = attributedString.rangeOfTextBlock(effectiveBlock, at: innerRange.location)
		#expect(foundRange == innerRange)
	}

	@Test("List range")
	func listRange() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some text</p><ul><li>inside</li></ul><p>following</p>")!

		let innerRange = (attributedString.string as NSString).range(of: "inside\n")
		// Read the list from the paragraph style (the canonical source).
		let paraStyle = attributedString.attribute(.paragraphStyle, at: innerRange.location, effectiveRange: nil) as! NSParagraphStyle
		let lists = paraStyle.textLists as! [DTTextList]
		#expect(lists.count == 1)
		let effectiveList = lists.last!

		// test effective list inside range
		let foundRange = attributedString.rangeOfTextList(effectiveList, atIndex: innerRange.location)
		let expectedRange = (attributedString.string as NSString).paragraphRange(for: innerRange)
		#expect(foundRange == expectedRange)

		// test effective list outside range — paragraph 0 ("some text") has no list
		let nonFoundRange = attributedString.rangeOfTextList(effectiveList, atIndex: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// Value-equal copies find the same range (attribute coalescing may strip instance
		// identity, so rangeOfTextList uses value equality, not `===`, to locate the list).
		let copy = effectiveList.copy() as! DTTextList
		#expect(effectiveList !== copy)
		let copyFound = attributedString.rangeOfTextList(copy, atIndex: innerRange.location)
		#expect(copyFound == expectedRange)
	}

	@Test("Text list ranges")
	func textListRanges() {
		let html = """
		<ol>
			<li>1</li>
			<li>2</li>
			<li>3</li>
		</ol>
		"""

		let attributedString = TestHelpers.attributedString(fromHTML: html)!

		let entireString = NSRange(location: 0, length: attributedString.length)
		(attributedString.string as NSString).enumerateSubstrings(in: entireString, options: .byParagraphs) { substring, substringRange, _, _ in
			guard let substring = substring else { return }

			let attributes = attributedString.attributes(at: substringRange.location, effectiveRange: nil)
			let paraStyle = attributes[.paragraphStyle] as? NSParagraphStyle
			let list = (paraStyle?.textLists as? [DTTextList])?.last

			let prefixRange = attributedString.rangeOfField(at: substringRange.location)
			let textAfterPrefix = (substring as NSString).substring(from: prefixRange.length)
			let number = Int(textAfterPrefix) ?? 0

			let index = attributedString.itemNumber(in: list!, atIndex: substringRange.location)

			#expect(number == index, "Item number should match the text for range \(NSStringFromRange(substringRange))")
		}
	}

	@Test("Link range detection")
	func linkRange() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some <a href=\"http://www.cocoanetics.com\">li<b>nk</b></a> text</p>")!

		let innerRange = (attributedString.string as NSString).range(of: "link")

		// test inside
		var foundURL: NSURL?
		var linkRange = attributedString.rangeOfLink(at: innerRange.location, url: &foundURL)
		#expect(foundURL != nil)
		#expect(foundURL?.absoluteString == "http://www.cocoanetics.com")
		#expect(linkRange == innerRange)

		// test outside before
		foundURL = nil
		linkRange = attributedString.rangeOfLink(at: innerRange.location - 1, url: &foundURL)
		#expect(foundURL == nil)
		#expect(linkRange == NSRange(location: NSNotFound, length: 0))

		// test outside after
		foundURL = nil
		linkRange = attributedString.rangeOfLink(at: NSMaxRange(innerRange), url: &foundURL)
		#expect(foundURL == nil)
		#expect(linkRange == NSRange(location: NSNotFound, length: 0))
	}
}
