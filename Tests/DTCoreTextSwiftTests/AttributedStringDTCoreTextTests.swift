import Testing
import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("NSAttributedString+DTCoreText")
struct AttributedStringDTCoreTextTests {
	@Test("Range of named anchor")
	func rangeOfAnchor() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some text</p><a name=\"anchor\">anchor</a><p>more text</p>")!

		let range = attributedString.range(ofAnchorNamed: "anchor")
		#expect(range == NSRange(location: 10, length: 7))

		let notFound = attributedString.range(ofAnchorNamed: "something")
		#expect(notFound == NSRange(location: NSNotFound, length: 0))
	}

	@Test("Text block range")
	func textBlockRange() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some text</p><div style=\"padding:10px\">inside</div><p>following</p>")!

		let innerRange = (attributedString.string as NSString).range(of: "inside\n")

		let innerAttributes = attributedString.attributes(at: innerRange.location, effectiveRange: nil)
		let blocks = innerAttributes[NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] as! [DTTextBlock]
		#expect(blocks.count == 1)
		let effectiveBlock = blocks.last!

		let newBlock = DTTextBlock()
		#if canImport(UIKit)
		newBlock.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		#else
		newBlock.padding = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		#endif

		// test other block inside range
		var nonFoundRange = attributedString.range(of: newBlock, at: UInt(innerRange.location))
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test other block outside range
		nonFoundRange = attributedString.range(of: newBlock, at: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test effective block outside range
		nonFoundRange = attributedString.range(of: effectiveBlock, at: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test effective block inside range
		let foundRange = attributedString.range(of: effectiveBlock, at: UInt(innerRange.location))
		#expect(foundRange == innerRange)
	}

	@Test("List range")
	func listRange() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some text</p><ul><li>inside</li></ul><p>following</p>")!

		let innerRange = (attributedString.string as NSString).range(of: "inside\n")

		let innerAttributes = attributedString.attributes(at: innerRange.location, effectiveRange: nil)
		let lists = innerAttributes[NSAttributedString.Key(rawValue: DTTextListsAttribute)] as! [DTCSSListStyle]
		#expect(lists.count == 1)
		let effectiveList = lists.last!
		let newListStyle = effectiveList.copy() as! DTCSSListStyle

		#expect(effectiveList !== newListStyle)

		// test new list inside range
		var nonFoundRange = attributedString.range(ofTextList: newListStyle, at: UInt(innerRange.location))
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test new list outside range
		nonFoundRange = attributedString.range(ofTextList: newListStyle, at: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))

		// test effective list inside range
		let foundRange = attributedString.range(ofTextList: effectiveList, at: UInt(innerRange.location))
		let expectedRange = (attributedString.string as NSString).paragraphRange(for: innerRange)
		#expect(foundRange == expectedRange)

		// test effective list outside range
		nonFoundRange = attributedString.range(ofTextList: effectiveList, at: 1)
		#expect(nonFoundRange == NSRange(location: NSNotFound, length: 0))
	}

	@Test("Link range detection")
	func linkRange() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>some <a href=\"http://www.cocoanetics.com\">li<b>nk</b></a> text</p>")!

		let innerRange = (attributedString.string as NSString).range(of: "link")

		// test inside
		var foundURL: NSURL?
		var linkRange = attributedString.rangeOfLink(at: UInt(innerRange.location), url: &foundURL)
		#expect(foundURL != nil)
		#expect(foundURL?.absoluteString == "http://www.cocoanetics.com")
		#expect(linkRange == innerRange)

		// test outside before
		foundURL = nil
		linkRange = attributedString.rangeOfLink(at: UInt(innerRange.location - 1), url: &foundURL)
		#expect(foundURL == nil)
		#expect(linkRange == NSRange(location: NSNotFound, length: 0))

		// test outside after
		foundURL = nil
		linkRange = attributedString.rangeOfLink(at: UInt(NSMaxRange(innerRange)), url: &foundURL)
		#expect(foundURL == nil)
		#expect(linkRange == NSRange(location: NSNotFound, length: 0))
	}
}
