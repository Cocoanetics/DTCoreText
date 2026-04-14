import Testing
import Foundation
import CoreText
@testable import DTCoreTextSwift

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("HTML Attributed String Builder", .serialized)
struct HTMLAttributedStringBuilderTests {

	// MARK: - Helpers

	/// Swift equivalent of _effectiveRangeOfFontAtIndex:inAttributedString:font:
	private func effectiveRangeOfFont(at startIndex: Int, in attributedString: NSAttributedString) -> (range: NSRange, font: CTFont?) {
		var index = startIndex
		var totalEffectiveRange = NSRange(location: index, length: 0)
		var searchFont: CTFont?

		while index < attributedString.length {
			var range = NSRange()
			let foundFont = attributedString.attribute(NSAttributedString.Key(kCTFontAttributeName as String), at: index, effectiveRange: &range) as! CTFont?

			if let sf = searchFont {
				if let ff = foundFont {
					if sf !== ff {
						break
					}
				} else {
					break
				}
			} else {
				searchFont = foundFont
			}

			totalEffectiveRange = NSUnionRange(totalEffectiveRange, range)
			index = NSMaxRange(range)
		}

		return (totalEffectiveRange, searchFont)
	}

	// MARK: - Whitespace

	@Test("Space between underlines")
	func spaceBetweenUnderlines() throws {
		let output = try #require(TestHelpers.attributedString(fromTestFile: "SpaceBetweenUnderlines"))

		var rangeA = NSRange()
		let underLine = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: 1, effectiveRange: &rangeA) as? Int

		#expect((underLine ?? 0) == 0, "Space between a and b should not be underlined")
	}

	@Test("Whitespace after paragraph promoted image")
	func whitespaceAfterParagraphPromotedImage() throws {
		let output = try #require(TestHelpers.attributedString(fromTestFile: "WhitespaceFollowingImagePromotedToParagraph"))

		#expect(output.length == 6, "Generated String should be 6 characters")

		let expectedOutput = "1\n\u{fffc}\n2\n"
		#expect(output.string == expectedOutput, "Expected output not matching")
	}

	@Test("Keep me together with non-breaking spaces")
	func keepMeTogether() throws {
		let output = try #require(TestHelpers.attributedString(fromTestFile: "KeepMeTogether"))

		let expectedOutput = "Keep\u{00a0}me\u{00a0}together"
		#expect(output.string == expectedOutput, "Expected output not matching")
	}

	@Test("Tab decoding and preservation")
	func tabDecodingAndPreservation() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "Some text and then 2 encoded<span style=\"white-space:pre\">&#9;&#9</span>tabs and 2 non-encoded\t\ttabs"))

		let plainString = output.string
		let range = (plainString as NSString).range(of: "encoded")
		#expect(range.location != NSNotFound, "Should find 'encoded' in the string")

		let tabs = (plainString as NSString).substring(with: NSRange(location: range.location + range.length, length: 2))
		#expect(tabs == "\t\t", "There should be two tabs")

		let range2 = (plainString as NSString).range(of: "non-encoded")
		let compressedTabs = (plainString as NSString).substring(with: NSRange(location: range2.location + range2.length, length: 2))
		#expect(compressedTabs == " t", "The second two tabs should be compressed to a single whitespace")
	}

	@Test("Paragraph inside list item")
	func paragraphInsideListItem() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<ul><li><p>First Item</p></li></ul>"))
		let plainText = output.string

		let firstRange = (plainText as NSString).range(of: "First")
		#expect(firstRange.location > 0, "Location should be greater than 0")

		let charBefore = (plainText as NSString).substring(with: NSRange(location: firstRange.location - 1, length: 1))
		#expect(charBefore == "\t", "Character before First should be tab")
		#expect(charBefore != "\n", "Character before First should not be newline")
	}

	@Test("Superfluous paragraph break after BR")
	func superfluousParagraphBreakAfterBR() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<h1 style=\"font-variant: small-caps;\">one<br>\n\ttwo</h1>"))
		let plainText = output.string

		let twoRange = (plainText as NSString).range(of: "TWO")
		let charBeforeTwo = (plainText as NSString).substring(with: NSRange(location: twoRange.location - 1, length: 1))

		#expect(charBeforeTwo != "\n", "Superfluous NL following BR")
	}

	@Test("Custom attribute processing with Apple converted spaces")
	func customAttributeProcessingWithAppleConvertedSpaces() throws {
		let options: [String: Any] = [DTProcessCustomHTMLAttributes: true]
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p class='text' dir='auto'><span>2 <span class='Apple-converted-space'> </span>2</span></p>", options: options))

		var appleConvertedSpaceFound = false
		attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: .reverse) { attrs, _, _ in
			if let customAttrs = attrs[NSAttributedString.Key(DTCustomAttributesAttribute)] as? [String: Any],
			   let classValue = customAttrs["class"] as? String,
			   classValue == "Apple-converted-space" {
				appleConvertedSpaceFound = true
			}
		}

		#expect(!appleConvertedSpaceFound, "There should be no custom class 'Apple-converted-space'")
	}

	// MARK: - General Tests

	@Test("Writing direction")
	func writingDirection() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<p dir=\"rtl\">rtl</p><p dir=\"ltr\">ltr</p><p>normal</p>"))

		let paragraphStyleRTL = output.attribute(NSAttributedString.Key(kCTParagraphStyleAttributeName as String), at: 0, effectiveRange: nil) as! CTParagraphStyle
		let styleRTL = CoreTextParagraphStyle(ctParagraphStyle: paragraphStyleRTL)
		#expect(styleRTL.baseWritingDirection == .rightToLeft, "Writing direction is not RTL")

		let paragraphStyleLTR = output.attribute(NSAttributedString.Key(kCTParagraphStyleAttributeName as String), at: 4, effectiveRange: nil) as! CTParagraphStyle
		let styleLTR = CoreTextParagraphStyle(ctParagraphStyle: paragraphStyleLTR)
		#expect(styleLTR.baseWritingDirection == .leftToRight, "Writing direction is not LTR")

		let paragraphStyleNatural = output.attribute(NSAttributedString.Key(kCTParagraphStyleAttributeName as String), at: 8, effectiveRange: nil) as! CTParagraphStyle
		let styleNatural = CoreTextParagraphStyle(ctParagraphStyle: paragraphStyleNatural)
		#expect(styleNatural.baseWritingDirection == .natural, "Writing direction is not Natural")
	}

	@Test("Attachment display size")
	func attachmentDisplaySize() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<img src=\"Oliver.jpg\" style=\"foo:bar\">"))

		#expect(output.length == 1, "Output length should be 1")

		let attachment = try #require(output.attribute(.attachment, at: 0, effectiveRange: nil) as? TextAttachment)

		let expectedSize = CGSize(width: 150, height: 150)
		#expect(attachment.originalSize == expectedSize, "Non-expected originalSize")
		#expect(attachment.displaySize == expectedSize, "Non-expected displaySize")
	}

	@Test("Attachment auto size")
	func attachmentAutoSize() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<img src=\"Oliver.jpg\" style=\"width:260px; height:auto;\">"))

		#expect(output.length == 1, "Output length should be 1")

		let attachment = try #require(output.attribute(.attachment, at: 0, effectiveRange: nil) as? TextAttachment)

		let expectedOriginalSize = CGSize(width: 150, height: 150)
		let expectedDisplaySize = CGSize(width: 260, height: 260)

		#expect(attachment.originalSize == expectedOriginalSize, "Non-expected originalSize")
		#expect(attachment.displaySize == expectedDisplaySize, "Non-expected displaySize")
	}

	@Test("Missing closing bracket")
	func missingClosingBracket() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<img src=\"Oliver.jpg\""))

		#expect(output.length == 1, "Output length should be 1")

		let attachment = output.attribute(.attachment, at: 0, effectiveRange: nil) as? TextAttachment
		#expect(attachment != nil, "No attachment found in output")
	}

	@Test("RTL parsing")
	func rtlParsing() throws {
		let output = try #require(TestHelpers.attributedString(fromTestFile: "RTL"))

		var paraEndIndex: UInt = 0
		let firstParagraphRange = output.string.rangeOfParagraphsContaining(NSRange(location: 0, length: 0), parBegIndex: nil, parEndIndex: &paraEndIndex)
		#expect(NSEqualRanges(NSRange(location: 0, length: 22), firstParagraphRange), "First Paragraph Range should be {0,22}")

		let secondParagraphRange = output.string.rangeOfParagraphsContaining(NSRange(location: Int(paraEndIndex), length: 0), parBegIndex: nil, parEndIndex: nil)
		#expect(NSEqualRanges(NSRange(location: 22, length: 24), secondParagraphRange), "Second Paragraph Range should be {22,24}")

		let firstPS = output.attribute(NSAttributedString.Key(kCTParagraphStyleAttributeName as String), at: firstParagraphRange.location, effectiveRange: nil) as! CTParagraphStyle
		let firstParaStyle = CoreTextParagraphStyle(ctParagraphStyle: firstPS)
		#expect(firstParaStyle.baseWritingDirection == .rightToLeft, "First Paragraph Style is not RTL")

		let secondPS = output.attribute(NSAttributedString.Key(kCTParagraphStyleAttributeName as String), at: secondParagraphRange.location, effectiveRange: nil) as! CTParagraphStyle
		let secondParaStyle = CoreTextParagraphStyle(ctParagraphStyle: secondPS)
		#expect(secondParaStyle.baseWritingDirection == .rightToLeft, "Second Paragraph Style is not RTL")
	}

	@Test("Empty paragraph and font attribute")
	func emptyParagraphAndFontAttribute() throws {
		let output = try #require(TestHelpers.attributedString(fromTestFile: "EmptyLinesAndFontAttribute"))

		var paraEndIndex: UInt = 0
		let firstParagraphRange = output.string.rangeOfParagraphsContaining(NSRange(location: 0, length: 0), parBegIndex: nil, parEndIndex: &paraEndIndex)
		#expect(NSEqualRanges(NSRange(location: 0, length: 2), firstParagraphRange))

		let secondParagraphRange = output.string.rangeOfParagraphsContaining(NSRange(location: Int(paraEndIndex), length: 0), parBegIndex: nil, parEndIndex: &paraEndIndex)
		#expect(NSEqualRanges(NSRange(location: 2, length: 1), secondParagraphRange))

		let thirdParagraphRange = output.string.rangeOfParagraphsContaining(NSRange(location: Int(paraEndIndex), length: 0), parBegIndex: nil, parEndIndex: nil)
		#expect(NSEqualRanges(NSRange(location: 3, length: 1), thirdParagraphRange))

		let (firstFontRange, firstFont) = effectiveRangeOfFont(at: firstParagraphRange.location, in: output)
		#expect(firstFont != nil, "First paragraph font is missing")
		if firstFont != nil {
			#expect(NSEqualRanges(firstParagraphRange, firstFontRange), "Range Font in first paragraph is not full paragraph")
		}

		let (secondFontRange, secondFont) = effectiveRangeOfFont(at: secondParagraphRange.location, in: output)
		#expect(secondFont != nil, "Second paragraph font is missing")
		if secondFont != nil {
			#expect(NSEqualRanges(secondFontRange, secondParagraphRange), "Range Font in second paragraph is not full paragraph")
		}

		let (thirdFontRange, thirdFont) = effectiveRangeOfFont(at: thirdParagraphRange.location, in: output)
		#expect(thirdFont != nil, "Third paragraph font is missing")
		if thirdFont != nil {
			#expect(NSEqualRanges(thirdFontRange, thirdParagraphRange), "Range Font in third paragraph is not full paragraph")
		}
	}

	@Test("Transfer of hyperlink URL to attachment")
	func transferOfHyperlinkURLToAttachment() throws {
		let string = try #require(TestHelpers.attributedString(fromHTML: "<a href=\"https://www.cocoanetics.com\"><img class=\"Bla\" style=\"width:150px; height:150px\" src=\"Oliver.jpg\"></a>"))

		#expect(string.length == 1, "Output length should be 1")

		let attachment = try #require(string.attribute(.attachment, at: 0, effectiveRange: nil) as? TextAttachment)
		let url = string.attribute(NSAttributedString.Key(DTLinkAttribute), at: 0, effectiveRange: nil) as? NSURL

		#expect(url != nil, "Element URL is nil")
		#expect(url == attachment.hyperLinkURL as NSURL?, "Attachment URL and element URL should match!")
	}

	@Test("URL with CJK characters")
	func urlWithCJKCharacters() throws {
		let string = try #require(TestHelpers.attributedString(fromHTML: "<a href=\"http://www.example.com/\u{4F60}\u{597D}\">hello</a>"))

		var effectiveRange = NSRange()
		let link = string.attribute(.link, at: 0, effectiveRange: &effectiveRange) as? NSURL

		let linkStr = link?.absoluteString ?? ""
		let expected = "http://www.example.com/%E4%BD%A0%E5%A5%BD"

		#expect(effectiveRange.length == 5, "There should be 5 characters with the URL")
		#expect(linkStr == expected, "Output incorrect for CJK URL")
	}

	@Test("Ordered list starting number")
	func orderedListStartingNumber() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ol start=\"5\">\n<li>Item #5</li>\n<li>Item #6</li>\n<li>etc.</li>\n</ol>"))
		let string = attributedString.string

		let lines = string.components(separatedBy: "\n")

		#expect(lines.count == 4, "There should be 4 lines")

		#expect(lines[0].hasPrefix("\t5."), "String should have prefix 5. on first item")
		#expect(lines[1].hasPrefix("\t6."), "String should have prefix 6. on second item")
		#expect(lines[2].hasPrefix("\t7."), "String should have prefix 7. on third item")
	}

	@Test("Header level transfer")
	func headerLevelTransfer() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<h3>Header</h3>"))

		let headerLevelNum = attributedString.attribute(NSAttributedString.Key(DTHeaderLevelAttribute), at: 0, effectiveRange: nil) as? NSNumber
		#expect(headerLevelNum != nil, "No Header Level Attribute")

		let level = headerLevelNum?.intValue ?? 0
		#expect(level == 3, "Level should be 3")
	}

	@Test("Bleeding out attributes - strikethrough")
	func bleedingOutAttributes() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p><del>abc</del></p>"))

		#expect(attributedString.length == 4, "Attributed String should be 4 characters long")

		var effectiveRange = NSRange()
		var strikethroughStyle = attributedString.attribute(NSAttributedString.Key(DTStrikeOutAttribute), at: 0, effectiveRange: &effectiveRange) as? NSNumber
		if strikethroughStyle == nil {
			strikethroughStyle = attributedString.attribute(.strikethroughStyle, at: 0, effectiveRange: &effectiveRange) as? NSNumber
		}

		#expect(strikethroughStyle != nil, "There should be a strikethrough style")

		let expectedRange = NSRange(location: 0, length: 3)
		#expect(NSEqualRanges(effectiveRange, expectedRange), "Strikethrough style should only contain abc, not the NL")
	}

	@Test("Image display size with max")
	func imageDisplaySize() throws {
		#if canImport(UIKit)
		let options: [String: Any] = [DTMaxImageSize: NSValue(cgSize: CGSize(width: 200, height: 200))]
		#elseif canImport(AppKit)
		let options: [String: Any] = [DTMaxImageSize: NSValue(size: CGSize(width: 200, height: 200))]
		#endif

		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<img width=\"300\" height=\"300\" src=\"Oliver.jpg\">", options: options))

		#expect(attributedString.length == 1, "Output length should be 1")

		let imageAttachment = try #require(attributedString.attribute(.attachment, at: 0, effectiveRange: nil) as? ImageTextAttachment)

		let expectedSize = CGSize(width: 200, height: 200)
		#expect(imageAttachment.displaySize == expectedSize, "Expected size should be equal to display size")
	}

	// MARK: - Horizontal Rules

	@Test("Horizontal rules inside blockquote")
	func horizontalRulesInsideBlockquote() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<HR><BLOCKQUOTE><hr>one<hr><br>two<hr></BLOCKQUOTE><hr>"))

		var range = NSRange()
		var expectedRange = NSRange(location: 0, length: 1)
		var isHR = (attributedString.attributes(at: expectedRange.location, effectiveRange: &range)[NSAttributedString.Key(DTHorizontalRuleStyleAttribute)] as? Bool) ?? false
		#expect(isHR, "HR should be in range \(NSStringFromRange(expectedRange))")

		expectedRange = NSRange(location: 1, length: 1)
		isHR = (attributedString.attributes(at: expectedRange.location, effectiveRange: &range)[NSAttributedString.Key(DTHorizontalRuleStyleAttribute)] as? Bool) ?? false
		#expect(isHR, "HR should be in range \(NSStringFromRange(expectedRange))")

		expectedRange = NSRange(location: 6, length: 1)
		isHR = (attributedString.attributes(at: expectedRange.location, effectiveRange: &range)[NSAttributedString.Key(DTHorizontalRuleStyleAttribute)] as? Bool) ?? false
		#expect(isHR, "HR should be in range \(NSStringFromRange(expectedRange))")

		if attributedString.length > 12 {
			expectedRange = NSRange(location: 12, length: 1)
			isHR = (attributedString.attributes(at: expectedRange.location, effectiveRange: &range)[NSAttributedString.Key(DTHorizontalRuleStyleAttribute)] as? Bool) ?? false
			#expect(isHR, "HR should be in range \(NSStringFromRange(expectedRange))")

			expectedRange = NSRange(location: 13, length: 1)
			isHR = (attributedString.attributes(at: expectedRange.location, effectiveRange: &range)[NSAttributedString.Key(DTHorizontalRuleStyleAttribute)] as? Bool) ?? false
			#expect(isHR, "HR should be in range \(NSStringFromRange(expectedRange))")
		}
	}

	// MARK: - Non-Wellformed Content

	@Test("Characters after end of HTML")
	func charactersAfterEndOfHTML() {
		let result = TestHelpers.attributedString(fromHTML: "<html><body><p>text</p></body></html>bla bla bla")
		#expect(result != nil, "Should be able to parse without crash")
	}

	@Test("Tag after end of HTML")
	func tagAfterEndOfHTML() {
		let result = TestHelpers.attributedString(fromHTML: "<html><body><p>text</p></body></html><img>")
		#expect(result != nil, "Should be able to parse without crash")
	}

	@Test("Direct body text is not duplicated when keeping node tree")
	func directBodyTextNotDuplicatedWhenKeepingNodeTree() {
		let data = Data("<html><body>Hello</body></html>".utf8)
		let builder = HTMLAttributedStringBuilder(html: data, options: nil)
		builder?.shouldKeepDocumentNodeTree = true

		let result = builder?.generatedAttributedString()
		#expect(result?.string == "Hello")
	}

	// MARK: - Fonts

	@Test("Default font name")
	func defaultFontName() throws {
		let options: [String: Any] = [DTDefaultFontName: "Helvetica-Bold"]
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<html><body><p>Bla<p></body></html>", options: options))

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
		let fontDescriptor = (attributes as NSDictionary).dtct_fontDescriptor()!

		#expect(fontDescriptor.fontFamily == "Helvetica", "Incorrect font family")
		#expect(fontDescriptor.boldTrait, "Should be bold")
	}

	@Test("Font family small caps crash")
	func fontFamilySmallCapsCrash() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"font-variant:small-caps; font-family:inherit;\">Test</p>"))
		#expect(attributedString.length == 5, "Should be 5 characters")
	}

	@Test("Fallback font family")
	func fallbackFontFamily() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"font-family:Calibri\">Text</p>"))

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
		let fontDescriptor = (attributes as NSDictionary).dtct_fontDescriptor()!

		#expect(fontDescriptor.fontFamily == "Times New Roman", "Incorrect fallback font family")
	}

	@Test("Invalid font size")
	func invalidFontSize() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<span style=\"font-size:30px\"><p style=\"font-size:normal\">Bla</p></span>"))

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
		let fontDescriptor = (attributes as NSDictionary).dtct_fontDescriptor()!

		#expect(fontDescriptor.pointSize == 30, "Should ignore invalid CSS length")
	}

	@Test("Font tag with style")
	func fontTagWithStyle() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<font style=\"font-size: 17pt;\"> <u>BOLUS DOSE&nbsp;&nbsp; = xx.x mg&nbsp;</u> </font>"))

		let font = output.attribute(NSAttributedString.Key(kCTFontAttributeName as String), at: 0, effectiveRange: nil) as! CTFont
		let pointSize = CTFontGetSize(font)

		#expect(pointSize == 23.0, "Font Size should be 23 px (= 17 pt)")
	}

	// testFontSizeInterpretation is skipped because FontSizes.html is not in test resources

	@Test("Helvetica variants")
	func helveticaVariants() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"font-family:Helvetica\">Regular</p><p style=\"font-family:Helvetica;font-weight:bold;\">Bold</p><p style=\"font-family:Helvetica;font-style:italic;}\">Italic</p><p style=\"font-family:Helvetica;font-style:italic;font-weight:bold;}\">Bold+Italic</p>"))

		let string = attributedString.string
		let entireStringRange = NSRange(location: 0, length: (string as NSString).length)

		var lineNumber = 0

		(string as NSString).enumerateSubstrings(in: entireStringRange, options: .byParagraphs) { _, substringRange, enclosingRange, _ in
			let (fontRange, font) = self.effectiveRangeOfFont(at: substringRange.location, in: attributedString)

			#expect(NSEqualRanges(enclosingRange, fontRange), "Font should be on entire string")

			guard let font = font else { return }
			let descriptor = CoreTextFontDescriptor(ctFont: font)

			switch lineNumber {
			case 0:
				#expect(descriptor.fontFamily == "Helvetica", "Font family should be Helvetica")
				#expect(descriptor.fontName == "Helvetica", "Font face should be Helvetica")
			case 1:
				#expect(descriptor.fontFamily == "Helvetica", "Font family should be Helvetica")
				#expect(descriptor.fontName == "Helvetica-Bold", "Font face should be Helvetica-Bold")
			case 2:
				#expect(descriptor.fontFamily == "Helvetica", "Font family should be Helvetica")
				#expect(descriptor.fontName == "Helvetica-Oblique", "Font face should be Helvetica-Oblique")
			case 3:
				#expect(descriptor.fontFamily == "Helvetica", "Font family should be Helvetica")
				#expect(descriptor.fontName == "Helvetica-BoldOblique", "Font face should be Helvetica-BoldOblique")
			default:
				break
			}

			lineNumber += 1
		}
	}

	@Test("Multiple font families crash")
	func multipleFontFamiliesCrash() {
		let result = TestHelpers.attributedString(fromHTML: "<p style=\"font-family:Helvetica,sans-serif\">Text</p>")
		#expect(result != nil, "Should be able to parse without crash")
	}

	@Test("Multiple font families selection")
	func multipleFontFamiliesSelection() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"font-family:'American Typewriter',sans-serif\">Text</p>"))

		let (fontRange, font) = effectiveRangeOfFont(at: 0, in: attributedString)

		let expectedRange = NSRange(location: 0, length: attributedString.length)
		#expect(NSEqualRanges(fontRange, expectedRange), "Font should be entire length")

		let descriptor = CoreTextFontDescriptor(ctFont: font!)
		#expect(descriptor.fontFamily == "American Typewriter", "Font Family should be 'American Typewriter'")
	}

	@Test("Multiple font families selection later position")
	func multipleFontFamiliesSelectionLaterPosition() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"font-family:foo,'American Typewriter'\">Text</p>"))

		let (fontRange, font) = effectiveRangeOfFont(at: 0, in: attributedString)

		let expectedRange = NSRange(location: 0, length: attributedString.length)
		#expect(NSEqualRanges(fontRange, expectedRange), "Font should be entire length")

		let descriptor = CoreTextFontDescriptor(ctFont: font!)
		#expect(descriptor.fontFamily == "American Typewriter", "Font Family should be 'American Typewriter'")
	}

	@Test("Helvetica Neue Light")
	func helveticaNeueLight() throws {
		let helveticaNeueFontFaceName = "HelveticaNeue-Light"

		let lightFont = CTFontCreateWithName(helveticaNeueFontFaceName as CFString, 12, nil)
		let checkName = CTFontCopyPostScriptName(lightFont) as String

		guard checkName == helveticaNeueFontFaceName else {
			// Font not available on this platform, skip
			return
		}

		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p><font face=\"HelveticaNeue-Light\">HelveticaNeue-Light <b>bold</b> <em>italic</em></font></p>"))

		// test normal font
		var (fontRange, font) = effectiveRangeOfFont(at: 0, in: attributedString)
		var expectedRange = NSRange(location: 0, length: 20)
		#expect(NSEqualRanges(fontRange, expectedRange), "Font should be 20 characters long")
		var descriptor = CoreTextFontDescriptor(ctFont: font!)
		#expect(descriptor.fontName == "HelveticaNeue-Light", "Font face should be 'HelveticaNeue-Light'")

		// test inherited font with bold
		expectedRange = NSRange(location: 20, length: 4)
		(fontRange, font) = effectiveRangeOfFont(at: expectedRange.location, in: attributedString)
		#expect(NSEqualRanges(fontRange, expectedRange), "Bold Font should be 4 characters long")
		descriptor = CoreTextFontDescriptor(ctFont: font!)
		#expect(descriptor.fontName == "HelveticaNeue-Bold", "Font face should be 'HelveticaNeue-Bold'")

		// test inherited font with italic
		expectedRange = NSRange(location: 25, length: 7)
		(fontRange, font) = effectiveRangeOfFont(at: expectedRange.location, in: attributedString)
		#expect(NSEqualRanges(fontRange, expectedRange), "Italic Font should be 7 characters long")
		descriptor = CoreTextFontDescriptor(ctFont: font!)
		#expect(descriptor.fontName == "HelveticaNeue-Italic", "Font face should be 'HelveticaNeue-Italic'")
	}

	@Test("Override font name")
	func overrideFontName() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"-coretext-fontname:Arial-BoldMT\">Bold</p>"))

		let (fontRange, font) = effectiveRangeOfFont(at: 0, in: attributedString)

		let expectedRange = NSRange(location: 0, length: attributedString.length)
		#expect(NSEqualRanges(fontRange, expectedRange), "Font should be entire length")

		let descriptor = CoreTextFontDescriptor(ctFont: font!)
		#expect(descriptor.fontName == "Arial-BoldMT", "Font should be 'Arial-BoldMT'")
	}

	// MARK: - Nested Lists

	@Test("Nested list with style none")
	func nestedListWithStyleNone() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul><li>Bullet</li><li style=\"list-style: none\"><ul><li>Bullet 2</li></ul></li></ul>"))

		let string = attributedString.string
		let entireStringRange = NSRange(location: 0, length: (string as NSString).length)

		var lineNumber = 0

		(string as NSString).enumerateSubstrings(in: entireStringRange, options: .byParagraphs) { _, substringRange, enclosingRange, _ in
			let attributedSubstring = attributedString.attributedSubstring(from: enclosingRange)

			switch lineNumber {
			case 1:
				let paraStyle = attributedSubstring.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
				let numLists = paraStyle?.textLists.count ?? 0
				#expect(numLists == 2, "There should be two lists active on line 2")

				let subString = attributedSubstring.string.trimmingCharacters(in: .whitespacesAndNewlines)
				#expect(subString.hasSuffix("Bullet 2"), "The second line should have the 'Bullet 2' text")
			default:
				break
			}

			lineNumber += 1
		}
	}

	@Test("Prefix with newlines")
	func prefixWithNewlines() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul><li>Bullet</li><li><ul><li>Bullet 2</li></ul></li></ul>"))

		let string = attributedString.string
		let entireStringRange = NSRange(location: 0, length: (string as NSString).length)

		var lineNumber: UInt = 0

		(string as NSString).enumerateSubstrings(in: entireStringRange, options: .byParagraphs) { _, _, enclosingRange, _ in
			let attributedSubstring = attributedString.attributedSubstring(from: enclosingRange)

			let prefixRange = attributedSubstring.rangeOfField(at: 0)
			let prefix = (attributedSubstring.string as NSString).substring(with: prefixRange)

			let newlineRange = (prefix as NSString).range(of: "\n")
			let foundNL = (newlineRange.location != NSNotFound)

			#expect(!foundNL, "Newline in prefix of line \(lineNumber)")

			lineNumber += 1
		}
	}

	@Test("Correct list bullets")
	func correctListBullets() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul><li>1</li><ul><li>2</li><ul><li>3</li></ul></ul></ul>"))

		let string = attributedString.string
		let entireStringRange = NSRange(location: 0, length: (string as NSString).length)

		var lineNumber = 0

		(string as NSString).enumerateSubstrings(in: entireStringRange, options: .byParagraphs) { _, _, enclosingRange, _ in
			let attributedSubstring = attributedString.attributedSubstring(from: enclosingRange)

			var prefixRange = attributedSubstring.rangeOfField(at: 0)
			prefixRange.location += 1
			prefixRange.length = 1
			let bulletChar = (attributedSubstring.string as NSString).substring(with: prefixRange)

			var expectedChar: String?

			switch lineNumber {
			case 0:
				expectedChar = "\u{2022}" // disc
			case 1:
				expectedChar = "\u{25e6}" // circle
			case 2:
				expectedChar = "\u{25aa}" // square
			default:
				break
			}

			if let expectedChar = expectedChar {
				#expect(bulletChar == expectedChar, "Bullet Character on UL level \(lineNumber + 1) should be '\(expectedChar)' but is '\(bulletChar)'")
			}

			lineNumber += 1
		}
	}

	@Test("Mixed list prefix")
	func mixedListPrefix() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ol><li>1a<ul><li>2a<ol><li>3a</li></ol></li></ul></li></ol>"))

		let string = attributedString.string
		let entireStringRange = NSRange(location: 0, length: (string as NSString).length)

		var lineNumber = 0

		(string as NSString).enumerateSubstrings(in: entireStringRange, options: .byParagraphs) { _, _, enclosingRange, _ in
			let attributedSubstring = attributedString.attributedSubstring(from: enclosingRange)

			let prefixRange = attributedSubstring.rangeOfField(at: 0)
			let prefix = (attributedSubstring.string as NSString).substring(with: prefixRange)

			var expectedPrefix: String?

			switch lineNumber {
			case 0:
				expectedPrefix = "\t1.\t"
			case 1:
				expectedPrefix = "\t\u{25e6}\t"
			case 2:
				expectedPrefix = "\t1.\t"
			default:
				break
			}

			if let expectedPrefix = expectedPrefix {
				#expect(prefix == expectedPrefix, "Prefix level \(lineNumber + 1) should be '\(expectedPrefix)' but is '\(prefix)'")
			}

			lineNumber += 1
		}
	}

	@Test("Background color transfer from list item to text")
	func backgroundColorTransferFromListItemToText() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul><li style=\"background-color:red\">12345"))

		var effectiveRange = NSRange()
		let attributes = attributedString.attributes(at: 4, effectiveRange: &effectiveRange)

		let backgroundColor = (attributes as NSDictionary).dtct_backgroundColor()
		#expect(backgroundColor != nil, "Missing Background Color")

		let expectedRange = NSRange(location: 3, length: 5)
		#expect(NSEqualRanges(effectiveRange, expectedRange), "Range is not correct")

		if let backgroundColor = backgroundColor {
			let colorHex = DTHexStringFromDTColor(backgroundColor)
			#expect(colorHex == "ff0000", "Color should be red")
		}
	}

	@Test("Text list ranges")
	func textListRanges() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ol><li>1a<ul><li>2a</li></ul></li><li>more</li><li>more</li></ol>"))

		let outerPS = attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
		let lists = outerPS?.textLists as? [DTTextList]
		#expect(lists?.count == 1, "There should be 1 outer list")

		let outerList = lists!.last!
		let list1Range = attributedString.rangeOfTextList(outerList, atIndex: 0)

		#expect(list1Range.location == 0, "lists should start at index 0")
		#expect(list1Range.length > 0, "lists should range for entire string")

		let innerRange = (attributedString.string as NSString).range(of: "2a")
		let innerPS = attributedString.attribute(.paragraphStyle, at: innerRange.location, effectiveRange: nil) as? NSParagraphStyle
		let innerLists = innerPS?.textLists as? [DTTextList]
		#expect(innerLists?.count == 2, "There should be 2 inner lists")

		if let innerLists = innerLists, !innerLists.isEmpty {
			#expect(innerLists[0].isEqual(outerList), "list at index 0 in inner lists should be equal to outer list")
		}

		let list2Range = attributedString.rangeOfTextList(innerLists!.last!, atIndex: innerRange.location)
		let innerParagraph = (attributedString.string as NSString).paragraphRange(for: innerRange)

		#expect(NSEqualRanges(innerParagraph, list2Range), "Inner list range should be equal to inner paragraph")
	}

	@Test("Empty list item with sub list")
	func emptyListItemWithSubList() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul>\n<li>\n<ol>\n<li>Foo</li>\n<li>Bar</li>\n</ol>\n</li>\n<li>BLAH</li>\n</ul>"))

		let firstParagraphRange = (attributedString.string as NSString).paragraphRange(for: NSRange(location: 0, length: 1))
		let firstPS = attributedString.attribute(.paragraphStyle, at: firstParagraphRange.location, effectiveRange: nil) as? NSParagraphStyle
		let firstParagraphLists = firstPS?.textLists as? [DTTextList]
		let firstListsCount = firstParagraphLists?.count ?? 0

		#expect(firstListsCount == 1, "There should be one list on the first paragraph")

		if let firstParagraphLists = firstParagraphLists {
			for (idx, oneList) in firstParagraphLists.enumerated() {
				let listRange = attributedString.rangeOfTextList(oneList, atIndex: firstParagraphRange.location)
				let commonRange = NSIntersectionRange(listRange, firstParagraphRange)
				#expect(NSEqualRanges(commonRange, firstParagraphRange), "List \(idx + 1) does not cover entire paragraph")
			}
		}

		// second paragraph should have two lists
		let secondParagraphRange = (attributedString.string as NSString).paragraphRange(for: NSRange(location: NSMaxRange(firstParagraphRange), length: 1))
		let secondPS = attributedString.attribute(.paragraphStyle, at: secondParagraphRange.location, effectiveRange: nil) as? NSParagraphStyle
		let secondParagraphLists = secondPS?.textLists as? [DTTextList]
		let secondListsCount = secondParagraphLists?.count ?? 0

		#expect(secondListsCount == 2, "There should be two lists on the second paragraph")

		if let secondParagraphLists = secondParagraphLists {
			for (idx, oneList) in secondParagraphLists.enumerated() {
				let listRange = attributedString.rangeOfTextList(oneList, atIndex: secondParagraphRange.location)
				let commonRange = NSIntersectionRange(listRange, secondParagraphRange)
				#expect(NSEqualRanges(commonRange, secondParagraphRange), "List \(idx + 1) does not cover entire paragraph")
			}
		}
	}

	// MARK: - CSS Tests

	@Test("Cascading CSS")
	func cascading() throws {
		let output = try #require(TestHelpers.attributedString(fromTestFile: "CSSCascading"))

		let index1 = 0
		let index2 = 3
		let index3 = 10
		let index4 = 16
		let index5 = 18
		let index6 = 47
		let index7 = 98

		// check first "me"
		let attributes1 = output.attributes(at: index1, effectiveRange: nil)
		let underLine1 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index1, effectiveRange: nil) as? Int
		#expect((underLine1 ?? 0) == 1, "First item should be underlined")
		let foreground1 = (attributes1 as NSDictionary).dtct_foregroundColor()
		let foreground1HTML = DTHexStringFromDTColor(foreground1)
		#expect(foreground1HTML == "008000", "First item should be green")
		#expect((attributes1 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "First item should be bold")
		#expect(!(attributes1 as NSDictionary).dtct_fontDescriptor()!.italicTrait, "First item should not be italic")

		// check first "buzz"
		let attributes2 = output.attributes(at: index2, effectiveRange: nil)
		let underLine2 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index2, effectiveRange: nil) as? Int
		#expect((underLine2 ?? 0) == 1, "Second item should be underlined")
		let foreground2 = (attributes2 as NSDictionary).dtct_foregroundColor()
		let foreground2HTML = DTHexStringFromDTColor(foreground2)
		#expect(foreground2HTML == "800080", "Second item should be purple")
		#expect((attributes2 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "Second item should be bold")

		// check "owzers"
		let attributes3 = output.attributes(at: index3, effectiveRange: nil)
		let underLine3 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index3, effectiveRange: nil) as? Int
		#expect((underLine3 ?? 0) == 1, "Third item should be underlined")
		var strikeThrough3 = output.attribute(NSAttributedString.Key(DTStrikeOutAttribute), at: index3, effectiveRange: nil) as? Int
		if strikeThrough3 == nil {
			strikeThrough3 = output.attribute(.strikethroughStyle, at: index3, effectiveRange: nil) as? Int
		}
		#expect((strikeThrough3 ?? 0) == 1, "Third item should have strike through")
		let foreground3 = (attributes3 as NSDictionary).dtct_foregroundColor()
		let foreground3HTML = DTHexStringFromDTColor(foreground3)
		#expect(foreground3HTML == "ffa500", "Third item should be orange")
		#expect(!(attributes3 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "Third item should not be bold")
		#expect((attributes3 as NSDictionary).dtct_fontDescriptor()!.italicTrait, "Third item should be italic")

		// check second "Me"
		let attributes4 = output.attributes(at: index4, effectiveRange: nil)
		let underLine4 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index4, effectiveRange: nil) as? Int
		#expect((underLine4 ?? 0) != 1, "Fourth item should not be underlined")
		let foreground4 = (attributes4 as NSDictionary).dtct_foregroundColor()
		let foreground4HTML = DTHexStringFromDTColor(foreground4)
		#expect(foreground4HTML == "ff0000", "Fourth item should be red")
		#expect(!(attributes4 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "Fourth item should not be bold")
		#expect(!(attributes4 as NSDictionary).dtct_fontDescriptor()!.italicTrait, "Fourth item should not be italic")

		// check "ow"
		let attributes5 = output.attributes(at: index5, effectiveRange: nil)
		let underLine5 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index5, effectiveRange: nil) as? Int
		#expect((underLine5 ?? 0) == 1, "Fifth item should be underlined")
		let foreground5 = (attributes5 as NSDictionary).dtct_foregroundColor()
		let foreground5HTML = DTHexStringFromDTColor(foreground5)
		#expect(foreground5HTML == "008000", "Fifth item should be green")
		#expect((attributes5 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "Fifth item should be bold")
		#expect(!(attributes5 as NSDictionary).dtct_fontDescriptor()!.italicTrait, "Fifth item should not be italic")

		// check "this is a test of by tag name..."
		let attributes6 = output.attributes(at: index6, effectiveRange: nil)
		let underLine6 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index6, effectiveRange: nil) as? Int
		#expect((underLine6 ?? 0) == 1, "Sixth item should be underlined")
		let foreground6 = (attributes6 as NSDictionary).dtct_foregroundColor()
		let foreground6HTML = DTHexStringFromDTColor(foreground6)
		#expect(foreground6HTML == "ffa500", "Sixth item should be orange")
		#expect(!(attributes6 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "Sixth item should not be bold")
		#expect((attributes6 as NSDictionary).dtct_fontDescriptor()!.italicTrait, "Sixth item should be italic")

		// check "i'm gray text"
		let attributes7 = output.attributes(at: index7, effectiveRange: nil)
		let underLine7 = output.attribute(NSAttributedString.Key(kCTUnderlineStyleAttributeName as String), at: index7, effectiveRange: nil) as? Int
		#expect((underLine7 ?? 0) != 1, "Seventh item should not be underlined")
		let foreground7 = (attributes7 as NSDictionary).dtct_foregroundColor()
		let foreground7HTML = DTHexStringFromDTColor(foreground7)
		#expect(foreground7HTML == "777777", "Seventh item should be gray")
		#expect(!(attributes7 as NSDictionary).dtct_fontDescriptor()!.boldTrait, "Seventh item should not be bold")
		#expect(!(attributes7 as NSDictionary).dtct_fontDescriptor()!.italicTrait, "Seventh item should not be italic")
	}

	@Test("Cascading out of memory")
	func cascadingOutOfMemory() throws {
		let startTime = Date()
		let attributedString = TestHelpers.attributedString(fromTestFile: "CSSOOMCrash")
		#expect(attributedString != nil, "Should be able to parse without running out of memory")
		#expect(Date().timeIntervalSince(startTime) < 0.5, "Test should run in less than 0.5 seconds")
	}

	@Test("Incorrect font size inheritance")
	func incorrectFontSizeInheritance() throws {
		let html = "<html><head><style>.sample { font-size: 2em; }</style></head><body><div class=\"sample\">Text1<p> Text2</p></div></div></html>"
		let output = try #require(TestHelpers.attributedString(fromHTML: html))

		let attributes1 = output.attributes(at: 1, effectiveRange: nil)
		let text1FontDescriptor = (attributes1 as NSDictionary).dtct_fontDescriptor()!

		let attributes2 = output.attributes(at: 7, effectiveRange: nil)
		let text2FontDescriptor = (attributes2 as NSDictionary).dtct_fontDescriptor()!

		#expect(text1FontDescriptor.pointSize == text2FontDescriptor.pointSize, "Point size should be the same when font-size is cascaded and inherited")
	}

	@Test("Incorrect simple selector cascade")
	func incorrectSimpleSelectorCascade() throws {
		let html = "<html><head><style>.sample { color: green; }</style></head><body><div class=\"sample\">Text1<p> Text2</p></div></div></html>"
		let output = try #require(TestHelpers.attributedString(fromHTML: html))

		let foreground1 = (output.attributes(at: 1, effectiveRange: nil) as NSDictionary).dtct_foregroundColor()
		let foreground1HTML = DTHexStringFromDTColor(foreground1)

		let foreground2 = (output.attributes(at: 7, effectiveRange: nil) as NSDictionary).dtct_foregroundColor()
		let foreground2HTML = DTHexStringFromDTColor(foreground2)

		#expect(foreground1HTML == foreground2HTML, "Color should be inherited via cascaded selector")
	}

	@Test("Substring cascaded selectors being properly applied")
	func substringCascadedSelectorsBeingProperlyApplied() throws {
		let html = "<html><head><style> body .sample { color: red;} body .samples { color: green;}</style></head><body><div class=\"samples\">Text</div></html>"
		let output = try #require(TestHelpers.attributedString(fromHTML: html))

		let foreground = (output.attributes(at: 1, effectiveRange: nil) as NSDictionary).dtct_foregroundColor()
		let foregroundHTML = DTHexStringFromDTColor(foreground)
		#expect(foregroundHTML == "008000", "Color should be green and not red")
	}

	@Test("Cascaded selector specificity")
	func cascadedSelectorSpecificity() throws {
		let html = "<html><head><style> #foo .bar { font-size: 225px; color: green; } body #foo .bar { font-size: 24px; } #foo .bar { font-size: 100px; color: red; }</style> </head><body><div id=\"foo\"><div class=\"bar\">Text</div></div></body></html>"
		let output = try #require(TestHelpers.attributedString(fromHTML: html))

		let attributes = output.attributes(at: 1, effectiveRange: nil)
		let foreground = (attributes as NSDictionary).dtct_foregroundColor()
		let foregroundHTML = DTHexStringFromDTColor(foreground)
		#expect(foregroundHTML == "ff0000", "Color should be red and not green")

		let textFontDescriptor = (attributes as NSDictionary).dtct_fontDescriptor()!
		#expect(textFontDescriptor.pointSize == 24.0, "Point size should be 24 and not 225 or 100")
	}

	@Test("Cascaded selectors with equal specificity last declaration wins")
	func cascadedSelectorsWithEqualSpecificityLastDeclarationWins() throws {
		let html = "<html><head><style>#foo .bar { color: red; } #foo .bar { color: green; }</style> </head><body><div id=\"foo\"><div class=\"bar\">Text</div></div></body></html>"
		let output = try #require(TestHelpers.attributedString(fromHTML: html))

		let foreground = (output.attributes(at: 1, effectiveRange: nil) as NSDictionary).dtct_foregroundColor()
		let foregroundHTML = DTHexStringFromDTColor(foreground)
		#expect(foregroundHTML == "008000", "Color should be green and not red")

		let html2 = "<html><head><style>.bar { color: red; } .foo { color: green; } </style> </head><body><div class=\"foo\"><div class=\"bar\"><div>Text</div></div></div></body></html>"
		let output2 = try #require(TestHelpers.attributedString(fromHTML: html2))
		let foreground2 = (output2.attributes(at: 1, effectiveRange: nil) as NSDictionary).dtct_foregroundColor()
		let foregroundHTML2 = DTHexStringFromDTColor(foreground2)
		#expect(foregroundHTML2 == "ff0000", "Color should be red and not green")
	}

	@Test("Div div span")
	func divDivSpan() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<html><head><style>div div {color:green;}</style></head><body><div><div><span>FOO</span></div></div></body></html>"))

		let foreground1 = (attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary).dtct_foregroundColor()
		let foreground1HTML = DTHexStringFromDTColor(foreground1)
		#expect(foreground1HTML == "008000", "First item should be green")
	}

	@Test("Letter spacing")
	func letterSpacing() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<h1 style=\"font-variant: small-caps; letter-spacing:10px\">one</h1>"))

		let attributes1 = attributedString.attributes(at: 0, effectiveRange: nil)
		let kerning = (attributes1 as NSDictionary).dtct_kerning()
		#expect(kerning == 10, "Kerning should be 10px")
	}

	@Test("Display style inheritance")
	func displayStyleInheritance() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<html><head><style>\t.container { display: block; }\tspan.test { font-style:italic; }</style></head><body><div class='container'>\n    before  <span class='test'>test</span> after\n</div></body></html>"))

		let lines = attributedString.string.trimmingCharacters(in: .newlines).components(separatedBy: "\n")
		#expect(lines.count == 1, "There should only be one line, display style block should not be inherited")
	}

	// MARK: - Attachments

	@Test("Attachment with display none")
	func attachmentWithDisplayNone() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<img style=\"display:none;\" src=\"Oliver.jpg\">"))
		#expect(attributedString.length == 0, "Text attachment should be invisible")
	}

	@Test("Double output of attachment with display none")
	func doubleOutputOfAttachmentWithDisplayNone() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<oliver style=\"width:40; height:40;display:none;\"><p><strong>BOX1</strong></p></oliver><oliver style=\"width:40; height:40;display:block;\"><p><strong>BOX2</strong></p></oliver><p>END</p>"))

		var effectiveRange = NSRange()
		let attachment = attributedString.attribute(.attachment, at: 0, effectiveRange: &effectiveRange)

		#expect(attachment != nil, "There should be an attachment")
		#expect(NSEqualRanges(effectiveRange, NSRange(location: 0, length: 1)), "Attachment should only be on first character")

		for i in 1..<attributedString.length {
			let otherAttachment = attributedString.attribute(.attachment, at: i, effectiveRange: &effectiveRange)
			#expect(otherAttachment == nil, "There is an unexpected attachment at \(NSStringFromRange(effectiveRange))")
		}
	}

	@Test("Retina data URL")
	func retinaDataURL() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromTestFile: "RetinaDataURL"))

		#expect(attributedString.length == 2, "RetinaDataURL should be parsed as 2 characters")

		var effectiveRange = NSRange()
		let attachment = try #require(attributedString.attribute(.attachment, at: 0, effectiveRange: &effectiveRange) as? ImageTextAttachment)

		#expect(NSEqualRanges(effectiveRange, NSRange(location: 0, length: 1)), "Attachment should only be on first character")

		let targetSize = CGSize(width: 176, height: 68)

		#expect(attachment.image!.size == targetSize, "Attachment has incorrect image size")
		#expect(attachment.originalSize == targetSize, "Attachment has incorrect original size")

		#if canImport(UIKit)
		#expect(attachment.image!.scale == 2, "Attachment image should have scale 2")
		#elseif canImport(AppKit)
		// On AppKit, NSImage doesn't have a scale property. Instead, the pixel
		// dimensions of the backing representation should be 2x the point size.
		let rep = try #require(attachment.image!.representations.first)
		let pixelScale = Double(rep.pixelsWide) / attachment.image!.size.width
		#expect(pixelScale == 2.0, "Backing representation should be 2x the point size")
		#endif
	}

	// MARK: - Parsing Options

	@Test("Ignore inline style")
	func ignoreInlineStyle() throws {
		let options: [String: Any] = [DTIgnoreInlineStylesOption: true]
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<html><head><style>.container { color: red }</style></head><body><span class='container' style=\"color: blue\">Text</span></body></html>", options: options))

		var effectiveRange = NSRange()
		let attributes = attributedString.attributes(at: 0, effectiveRange: &effectiveRange)

		let expectedRange = NSRange(location: 0, length: attributedString.length)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Attributes should cover all text")

		let color = (attributes as NSDictionary).dtct_foregroundColor()
		let hexColor = DTHexStringFromDTColor(color)

		#expect(hexColor == "ff0000", "Color should be red because inline style should be ignored through option")
	}

	@Test("Process inline style")
	func processInlineStyle() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<html><head><style>.container { color: red }</style></head><body><span class='container' style=\"color: blue\">Text</span></body></html>"))

		var effectiveRange = NSRange()
		let attributes = attributedString.attributes(at: 0, effectiveRange: &effectiveRange)

		let expectedRange = NSRange(location: 0, length: attributedString.length)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Attributes should cover all text")

		let color = (attributes as NSDictionary).dtct_foregroundColor()
		let hexColor = DTHexStringFromDTColor(color)

		#expect(hexColor == "0000ff", "Color should be blue because inline style should be processed")
	}

	@Test("Base64 image in li element")
	func base64imageInLiElement() throws {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: "<ul style=\"list-style: none;\">\n<li style=\"color: #333; list-style-image: url(\'data:image/png;base64,ABCDEF\');\">Li item</li></ul>"))

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
		let color = (attributes as NSDictionary).dtct_foregroundColor()
		let hexColor = DTHexStringFromDTColor(color)

		#expect(hexColor == "333333", "Color attribute lost")
		#expect(attributedString.string == "Li item\n")
	}
}
