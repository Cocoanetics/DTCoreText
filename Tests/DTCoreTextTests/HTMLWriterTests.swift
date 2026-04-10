import Testing
import Foundation
import CoreText
@testable import DTCoreTextSwift

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("HTML Writer", .serialized)
struct HTMLWriterTests {

	// MARK: - Helpers

	private func testListIndentRoundTrip(from html: String, fragmentMode: Bool) throws {
		let string1 = try #require(TestHelpers.attributedString(fromHTML: html))

		let writer1 = HTMLWriter(attributedString: string1)
		let html1: String
		if fragmentMode {
			html1 = writer1.htmlFragment()
		} else {
			html1 = writer1.htmlString()
		}

		let string2 = try #require(TestHelpers.attributedString(fromHTML: html1))

		let stringsHaveSameLength = string1.length == string2.length
		#expect(stringsHaveSameLength, "Roundtripped string should be of equal length, but string1 is \(string1.length), string2 is \(string2.length)")

		guard stringsHaveSameLength else { return }

		(string1.string as NSString).enumerateSubstrings(in: NSRange(location: 0, length: string1.length), options: .byParagraphs) { _, substringRange, _, _ in

			let attributes1 = string1.attributes(at: substringRange.location, effectiveRange: nil)
			let attributes2 = string2.attributes(at: substringRange.location, effectiveRange: nil)

			let paraStyle1 = (attributes1 as NSDictionary).dtct_paragraphStyle()
			let paraStyle2 = (attributes2 as NSDictionary).dtct_paragraphStyle()

			let equal = paraStyle1?.isEqual(paraStyle2)
			#expect(equal == true, "Paragraph Styles in range \(NSStringFromRange(substringRange)) should be equal")

			var prefixRange = NSRange()
			let prefix1 = string1.attribute(NSAttributedString.Key(DTListPrefixField), at: substringRange.location, effectiveRange: &prefixRange) as? String
			let prefix2 = attributes1[NSAttributedString.Key(DTListPrefixField)] as? String

			#expect(prefix1 == prefix2, "List prefix fields should be equal")

			let lists1 = attributes1[NSAttributedString.Key(DTTextListsAttribute)] as? [CSSListStyle]
			let lists2 = attributes2[NSAttributedString.Key(DTTextListsAttribute)] as? [CSSListStyle]

			let sameNumberOfLists = (lists1?.count ?? 0) == (lists2?.count ?? 0)
			#expect(sameNumberOfLists, "Should be same number of lists")

			if sameNumberOfLists, let lists1 = lists1, let lists2 = lists2 {
				for index in 0..<lists1.count {
					#expect(lists1[index].isEqualToListStyle(lists2[index]), "List Style at index \(index) is not equal")
				}
			}

			if NSMaxRange(prefixRange) < NSMaxRange(substringRange) {
				let attrs1After = string1.attributes(at: NSMaxRange(prefixRange), effectiveRange: nil)
				let attrs2After = string2.attributes(at: NSMaxRange(prefixRange), effectiveRange: nil)

				let paraStyle1After = (attrs1After as NSDictionary).dtct_paragraphStyle()
				let paraStyle2After = (attrs2After as NSDictionary).dtct_paragraphStyle()

				let equalAfter = paraStyle1After?.isEqual(paraStyle2After)
				#expect(equalAfter == true, "Paragraph Styles following prefix in range \(NSStringFromRange(substringRange)) should be equal")
			}
		}
	}

	// MARK: - Color

	@Test("Background color")
	func backgroundColor() throws {
		let attributedText = NSMutableAttributedString(string: "Hello World")
		let range = (attributedText.string as NSString).range(of: "World")
		if range.location != NSNotFound {
			let color = DTColorCreateWithHexString("FFFF00")!
			attributedText.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: color.cgColor, range: range)
		}

		let writer = HTMLWriter(attributedString: attributedText)
		writer.useAppleConvertedSpace = false
		let html = writer.htmlFragment()

		let colorRange = (html as NSString).range(of: "background-color:#ffff00")
		#expect(colorRange.location != NSNotFound, "html should contain background-color:#ffff00")
	}

	@Test("Document and fragment caches stay separate")
	func separateDocumentAndFragmentCaches() {
		let writer = HTMLWriter(attributedString: NSAttributedString(string: "Hello"))

		let document = writer.htmlString()
		let fragment = writer.htmlFragment()

		#expect(document.contains("<!DOCTYPE"))
		#expect(!fragment.contains("<!DOCTYPE"))
		#expect(document != fragment)
	}

	// MARK: - List Output

	@Test("Simple list round trip")
	func simpleListRoundTrip() throws {
		let html = "<ul><li>fooo</li><li>fooo</li><li>fooo</li></ul>"
		try testListIndentRoundTrip(from: html, fragmentMode: false)
		try testListIndentRoundTrip(from: html, fragmentMode: true)
	}

	@Test("Simple list round trip with text scale")
	func simpleListRoundTripWithTextScale() throws {
		let textSize: CGFloat = 32.0
		let textScale: CGFloat = 1.5

		let html = String(format: "<ul style=\"-webkit-padding-start:%fpx;padding-left:%fpx;\"><li>fooo</li><li>fooo</li><li>fooo</li></ul>", textSize * textScale, textSize * textScale)
		let string = try #require(TestHelpers.attributedString(fromHTML: html))

		let writer = HTMLWriter(attributedString: string)
		writer.textScale = textScale
		let writtenHTML = writer.htmlFragment()

		#expect((writtenHTML as NSString).range(of: "-webkit-padding-start:32px;padding-left:32px;").location != NSNotFound, "Text scale should not affect list indention amount")
	}

	@Test("Nested list round trip")
	func nestedListRoundTrip() throws {
		let html = "<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>"
		try testListIndentRoundTrip(from: html, fragmentMode: false)
		try testListIndentRoundTrip(from: html, fragmentMode: true)
	}

	@Test("Nested list round trip with preceding element")
	func nestedListRoundTripWithPrecedingElement() throws {
		let html = "<p>This breaks writing nested lists</p><ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>"
		try testListIndentRoundTrip(from: html, fragmentMode: false)
		try testListIndentRoundTrip(from: html, fragmentMode: true)
	}

	@Test("Nested list with padding round trip")
	func nestedListWithPaddingRoundTrip() throws {
		let html = "<ul style=\"padding-left:55px\"><li>fooo<ul style=\"padding-left:66px\"><li>bar</li></ul></li></ul>"
		try testListIndentRoundTrip(from: html, fragmentMode: false)
		try testListIndentRoundTrip(from: html, fragmentMode: true)
	}

	@Test("Nested list output without text node round trip")
	func nestedListOutputWithoutTextNodeRoundTrip() throws {
		let html = "<ul>\n<li>\n<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>\n</li>\n<li>BLAH</li>\n</ul>"
		try testListIndentRoundTrip(from: html, fragmentMode: false)
		try testListIndentRoundTrip(from: html, fragmentMode: true)
	}

	@Test("Nested list output")
	func nestedListOutput() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ol><li>1a<ul><li>2a</li></ul></li></ol>"))

		let writer = HTMLWriter(attributedString: attributedString)
		let html = writer.htmlFragment().replacingOccurrences(of: "\n", with: "")

		let rangeLILI = (html as NSString).range(of: "</li></ul></li></ol>")
		#expect(rangeLILI.location != NSNotFound, "List Items should be closed next to each other")

		let rangeLIUL = (html as NSString).range(of: "</li><ul")
		#expect(rangeLIUL.location == NSNotFound, "List Items should not be closed before UL")

		let rangeSpanUL = (html as NSString).range(of: "</span></ul")
		#expect(rangeSpanUL.location == NSNotFound, "Missing LI between span and UL")
	}

	@Test("Nested list output without text node")
	func nestedListOutputWithoutTextNode() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul><li><ol><li>2a</li><li>2b</li></ol></li><li>1a</li></ul>"))

		let writer = HTMLWriter(attributedString: attributedString)
		let html = writer.htmlFragment().replacingOccurrences(of: "\n", with: "")

		let twoAOutsideOL = (html as NSString).range(of: "2a</span><ol")
		#expect(twoAOutsideOL.location == NSNotFound, "List item 2a should not be outside the ordered list")
	}

	// MARK: - Kerning

	@Test("Kerning")
	func kerning() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>"))

		let writer = HTMLWriter(attributedString: attributedString)
		let html = writer.htmlFragment().replacingOccurrences(of: "\n", with: "")

		let letterSpacingRange = (html as NSString).range(of: "letter-spacing:10px;")
		#expect(letterSpacingRange.location != NSNotFound, "Letter-spacing missing")
	}

	// NSTextSizeMultiplierDocumentOption is an AppKit constant not recognized by DTCoreText on macOS
	#if canImport(UIKit)
	@Test("Kerning with text scale")
	func kerningWithTextScale() throws {
		let options: [String: Any] = [NSTextSizeMultiplierDocumentOption: NSNumber(value: 3.0)]

		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>", options: options))

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
		let kerningValue = (attributes as NSDictionary).dtct_kerning()
		#expect(kerningValue == 30, "Scaled up kerning should be 30")

		let writer = HTMLWriter(attributedString: attributedString)
		let html = writer.htmlFragment().replacingOccurrences(of: "\n", with: "")

		let letterSpacingRange = (html as NSString).range(of: "letter-spacing:10px;")
		#expect(letterSpacingRange.location == NSNotFound, "Letter-spacing missing")
	}
	#endif

	// MARK: - Link generation

	@Test("Single line anchor")
	func singleLineAnchor() {
		let attributedString = NSMutableAttributedString(string: "first second third")
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameValue", range: NSRange(location: 6, length: 6))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<span>" +
			"<span style=\"color:#000000;\">first </span>" +
			"<a name=\"nameValue\">" +
			"<span style=\"color:#000000;\">second</span>" +
			"</a>" +
			"<span style=\"color:#000000;\"> third</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Single line anchor with background color around")
	func singleLineAnchorWithBackgroundColorAround() {
		let attributedString = NSMutableAttributedString(string: "single line blue link blue link")
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameValue", range: NSRange(location: 17, length: 4))
		let color = DTColorCreateWithHexString("0000FF")!
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: color.cgColor, range: NSRange(location: 12, length: 14))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<span>" +
			"<span style=\"color:#000000;\">single line </span>" +
			"<span style=\"color:#000000;background-color:#0000ff;\">blue </span>" +
			"<a name=\"nameValue\">" +
			"<span style=\"color:#000000;background-color:#0000ff;\">link</span>" +
			"</a>" +
			"<span style=\"color:#000000;background-color:#0000ff;\"> blue</span>" +
			"<span style=\"color:#000000;\"> link</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Single line anchor with background color around 2")
	func singleLineAnchorWithBackgroundColorAround2() {
		let backgroundColor = DTColorCreateWithHexString("9b57b5")!

		let attributedString = NSMutableAttributedString(string: "111222333444")
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: backgroundColor.cgColor, range: NSRange(location: 3, length: 7))
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameAttribute", range: NSRange(location: 2, length: 7))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<span>" +
			"<span style=\"color:#000000;\">11</span>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;\">1</span>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">222333</span>" +
			"</a>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">4</span>" +
			"<span style=\"color:#000000;\">44</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Single line anchor with background color around 3")
	func singleLineAnchorWithBackgroundColorAround3() {
		let backgroundColor = DTColorCreateWithHexString("9b57b5")!

		let attributedString = NSMutableAttributedString(string: "111222333444")
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: backgroundColor.cgColor, range: NSRange(location: 2, length: 7))
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameAttribute", range: NSRange(location: 3, length: 7))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<span>" +
			"<span style=\"color:#000000;\">11</span>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">1</span>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">222333</span>" +
			"<span style=\"color:#000000;\">4</span>" +
			"</a>" +
			"<span style=\"color:#000000;\">44</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Multi line anchor")
	func multiLineAnchor() {
		let attributedString = NSMutableAttributedString(string: "first line\nsecond line\nthird line")
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameValue", range: NSRange(location: 0, length: 22))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<p>" +
			"<a name=\"nameValue\">" +
			"<span style=\"color:#000000;\">first line</span>" +
			"</a>" +
			"</p>\n" +
			"<p>" +
			"<a name=\"nameValue\">" +
			"<span style=\"color:#000000;\">second line</span>" +
			"</a>" +
			"</p>\n" +
			"<span>" +
			"<span style=\"color:#000000;\">third line</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Multi line anchor with background color around")
	func multiLineAnchorWithBackgroundColorAround() {
		let attributedString = NSMutableAttributedString(string: "single line blue newline\nlink blue link")
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameValue", range: NSRange(location: 17, length: 12))
		let color = DTColorCreateWithHexString("0000FF")!
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: color.cgColor, range: NSRange(location: 12, length: 22))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<p>" +
			"<span style=\"color:#000000;\">single line </span>" +
			"<span style=\"color:#000000;background-color:#0000ff;\">blue </span>" +
			"<a name=\"nameValue\">" +
			"<span style=\"color:#000000;background-color:#0000ff;\">newline</span>" +
			"</a>" +
			"</p>\n" +
			"<span>" +
			"<a name=\"nameValue\">" +
			"<span style=\"color:#000000;background-color:#0000ff;\">link</span>" +
			"</a>" +
			"<span style=\"color:#000000;background-color:#0000ff;\"> blue</span>" +
			"<span style=\"color:#000000;\"> link</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Multi line anchor with extended background color around")
	func multiLineAnchorWithExtendedBackgroundColorAround() {
		let backgroundColor = DTColorCreateWithHexString("9b57b5")!

		let attributedString = NSMutableAttributedString(string: "111\n222\n333\n444")
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: backgroundColor.cgColor, range: NSRange(location: 2, length: 11))
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameAttribute", range: NSRange(location: 4, length: 7))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<p>" +
			"<span style=\"color:#000000;\">11</span>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">1</span>" +
			"</p>\n" +
			"<p>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">222</span>" +
			"</a>" +
			"</p>\n" +
			"<p>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">333</span>" +
			"</a>" +
			"</p>\n" +
			"<span>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">4</span>" +
			"<span style=\"color:#000000;\">44</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Multi line anchor with extended background color around 2")
	func multiLineAnchorWithExtendedBackgroundColorAround2() {
		let backgroundColor = DTColorCreateWithHexString("9b57b5")!

		let attributedString = NSMutableAttributedString(string: "111\n222\n333\n444")
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: backgroundColor.cgColor, range: NSRange(location: 5, length: 4))
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameAttribute", range: NSRange(location: 6, length: 4))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<p>" +
			"<span style=\"color:#000000;\">111</span>" +
			"</p>\n" +
			"<p>" +
			"<span style=\"color:#000000;\">2</span>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">2</span>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">2</span>" +
			"</a>" +
			"</p>\n" +
			"<p>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">3</span>" +
			"<span style=\"color:#000000;\">3</span>" +
			"</a>" +
			"<span style=\"color:#000000;\">3</span>" +
			"</p>\n" +
			"<span>" +
			"<span style=\"color:#000000;\">444</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}

	@Test("Multi line anchor with extended background color around 3")
	func multiLineAnchorWithExtendedBackgroundColorAround3() {
		let backgroundColor = DTColorCreateWithHexString("9b57b5")!

		let attributedString = NSMutableAttributedString(string: "111\n222\n333\n444")
		attributedString.addAttribute(NSAttributedString.Key(DTBackgroundColorAttribute), value: backgroundColor.cgColor, range: NSRange(location: 6, length: 4))
		attributedString.addAttribute(NSAttributedString.Key(DTAnchorAttribute), value: "nameAttribute", range: NSRange(location: 5, length: 4))

		let writer = HTMLWriter(attributedString: attributedString)
		let generatedHTMLFragment = writer.htmlFragment()
		let expectedHTMLFragment = "<p>" +
			"<span style=\"color:#000000;\">111</span>" +
			"</p>\n" +
			"<p>" +
			"<span style=\"color:#000000;\">2</span>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;\">2</span>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">2</span>" +
			"</a>" +
			"</p>\n" +
			"<p>" +
			"<a name=\"nameAttribute\">" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">3</span>" +
			"</a>" +
			"<span style=\"color:#000000;background-color:#9b57b5;\">3</span>" +
			"<span style=\"color:#000000;\">3</span>" +
			"</p>\n" +
			"<span>" +
			"<span style=\"color:#000000;\">444</span>" +
			"</span>\n"

		#expect(generatedHTMLFragment == expectedHTMLFragment, "Strings are not equal")
	}
}
