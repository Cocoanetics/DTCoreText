import Testing
import Foundation
import CoreText
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("Float Layout", .serialized)
struct FloatLayoutTests {

	// MARK: - Helpers

	private func layoutFrame(forHTML html: String, width: CGFloat = 400) throws -> (frame: CoreTextLayoutFrame, string: NSAttributedString) {
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: html))
		let layouter = try #require(CoreTextLayouter(attributedString: attributedString))

		let maxRect = CGRect(x: 0, y: 0, width: width, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
		let entireString = NSRange(location: 0, length: attributedString.length)
		let frame = try #require(layouter.layoutFrame(with: maxRect, range: entireString))

		return (frame, attributedString)
	}

	private func lines(of frame: CoreTextLayoutFrame) -> [CoreTextLayoutLine] {
		return (frame.lines as? [CoreTextLayoutLine]) ?? []
	}

	private func attachmentLines(of frame: CoreTextLayoutFrame) -> [CoreTextLayoutLine] {
		return lines(of: frame).filter { $0.attachments != nil }
	}

	private func textLines(of frame: CoreTextLayoutFrame) -> [CoreTextLayoutLine] {
		return lines(of: frame).filter { $0.attachments == nil }
	}

	/// The right edge of the line's real content, ignoring hanging trailing whitespace.
	private func contentMaxX(of line: CoreTextLayoutLine) -> CGFloat {
		return line.frame.maxX - line.trailingWhitespaceWidth
	}

	private let wrapText = String(repeating: "lorem ipsum dolor sit amet consetetur sadipscing elitr sed diam nonumy eirmod tempor ", count: 12)

	// MARK: - Attribute Emission

	@Test("Floated image carries the float style attribute")
	func floatAttributeOnImage() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<p><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:right\">text</p>"))

		let plainString = output.string as NSString
		let placeholderRange = plainString.range(of: UNICODE_OBJECT_PLACEHOLDER)
		#expect(placeholderRange.location != NSNotFound)

		let value = output.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: placeholderRange.location, effectiveRange: nil) as? NSNumber
		#expect(value?.uintValue == DTHTMLElementFloatStyle.right.rawValue)
	}

	@Test("Floated image stays inline within its paragraph")
	func floatedImageStaysInline() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<p><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:left\">text</p>"))

		// before float support, a floated image was forced to be its own block;
		// now the placeholder must be directly followed by the text
		#expect(output.string.hasPrefix("\u{FFFC}text"))
	}

	@Test("Floated block carries float style and width over its whole range")
	func floatAttributesOnBlock() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<div style=\"float:right; width:150px\">floated</div><p>main</p>"))

		let plainString = output.string as NSString
		let floatedRange = plainString.range(of: "floated")
		#expect(floatedRange.location != NSNotFound)

		var effectiveRange = NSRange()
		let style = output.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: floatedRange.location, longestEffectiveRange: &effectiveRange, in: NSRange(location: 0, length: output.length)) as? NSNumber
		#expect(style?.uintValue == DTHTMLElementFloatStyle.right.rawValue)

		// the attribute spans the entire div output including its paragraph break
		#expect(effectiveRange.location == floatedRange.location)
		#expect(NSMaxRange(effectiveRange) >= NSMaxRange(floatedRange) + 1)

		let width = output.attribute(NSAttributedString.Key(rawValue: DTFloatWidthAttribute), at: floatedRange.location, effectiveRange: nil) as? NSNumber
		#expect(width?.doubleValue == 150)

		// the main paragraph is not floated
		let mainRange = plainString.range(of: "main")
		let mainStyle = output.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: mainRange.location, effectiveRange: nil)
		#expect(mainStyle == nil)
	}

	@Test("Clear style is emitted on the paragraph")
	func clearAttributeOnParagraph() throws {
		let output = try #require(TestHelpers.attributedString(fromHTML: "<p style=\"clear:both\">text</p>"))

		let value = output.attribute(NSAttributedString.Key(rawValue: DTClearFloatsAttribute), at: 0, effectiveRange: nil) as? NSNumber
		#expect(value?.uintValue == DTHTMLElementClearStyle.both.rawValue)
	}

	// MARK: - Image Float Layout

	@Test("Image floated right sits at the right edge and text wraps around it")
	func imageFloatRightGeometry() throws {
		let html = "<p style=\"margin:0\"><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:right\">\(wrapText)</p>"
		let result = try layoutFrame(forHTML: html)

		let imageLines = attachmentLines(of: result.frame)
		#expect(imageLines.count == 1)

		let imageLine = try #require(imageLines.first)

		// at the right edge of the 400pt frame
		#expect(abs(imageLine.frame.origin.x - 300) < 0.5)
		#expect(abs(imageLine.frame.origin.y - 0) < 0.5)
		#expect(abs(imageLine.frame.height - 100) < 1)

		let flowLines = textLines(of: result.frame)
		#expect(flowLines.count > 3)

		var sawNarrowLine = false
		var sawFullWidthLine = false

		for line in flowLines {
			#expect(abs(line.frame.origin.x - 0) < 0.5)

			if line.frame.minY < 100 {
				// beside the image: must end before the float
				#expect(contentMaxX(of: line) <= 300.5)
				sawNarrowLine = true
			}

			if line.frame.minY >= 100 && contentMaxX(of: line) > 305 {
				// below the image: full width available again
				sawFullWidthLine = true
			}
		}

		#expect(sawNarrowLine)
		#expect(sawFullWidthLine)
	}

	@Test("Image floated left indents the text beside it")
	func imageFloatLeftGeometry() throws {
		let html = "<p style=\"margin:0\"><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:left\">\(wrapText)</p>"
		let result = try layoutFrame(forHTML: html)

		let imageLine = try #require(attachmentLines(of: result.frame).first)
		#expect(abs(imageLine.frame.origin.x - 0) < 0.5)
		#expect(abs(imageLine.frame.origin.y - 0) < 0.5)

		var sawIndentedLine = false
		var sawFullWidthLine = false

		for line in textLines(of: result.frame) {
			if line.frame.minY < 100 {
				#expect(abs(line.frame.origin.x - 100) < 0.5)
				sawIndentedLine = true
			} else {
				#expect(abs(line.frame.origin.x - 0) < 0.5)
				sawFullWidthLine = true
			}
		}

		#expect(sawIndentedLine)
		#expect(sawFullWidthLine)
	}

	@Test("Standalone floated image does not leave an empty line in the flow")
	func standaloneFloatedImage() throws {
		let html = "<p style=\"margin:0\">First.</p><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:right\"><p style=\"margin:0\">\(wrapText)</p>"
		let result = try layoutFrame(forHTML: html)

		let imageLine = try #require(attachmentLines(of: result.frame).first)
		let flowLines = textLines(of: result.frame)

		let firstParagraphLine = try #require(flowLines.first)
		let secondParagraphFirstLine = try #require(flowLines.dropFirst().first)

		// the image's top is where the second paragraph starts, right below the first
		#expect(abs(imageLine.frame.minY - firstParagraphLine.frame.maxY) < 3)

		// the second paragraph flows beside the image, not below it
		#expect(secondParagraphFirstLine.frame.minY < imageLine.frame.maxY)
		#expect(contentMaxX(of: secondParagraphFirstLine) <= 300.5)
	}

	@Test("Two right floats sit side by side")
	func twoRightFloatsSideBySide() throws {
		let html = "<p style=\"margin:0\"><img src=\"Oliver.jpg\" width=\"80\" height=\"80\" style=\"float:right\"><img src=\"Oliver.jpg\" width=\"60\" height=\"60\" style=\"float:right\">\(wrapText)</p>"
		let result = try layoutFrame(forHTML: html)

		let imageLines = attachmentLines(of: result.frame)
		#expect(imageLines.count == 2)

		let first = try #require(imageLines.first)
		let second = try #require(imageLines.dropFirst().first)

		// first at the right edge, second to its left
		#expect(abs(first.frame.origin.x - 320) < 0.5)
		#expect(abs(second.frame.origin.x - 260) < 0.5)
		#expect(abs(first.frame.minY - second.frame.minY) < 0.5)

		// text beside both floats ends before the leftmost one
		for line in textLines(of: result.frame) where line.frame.minY < 60 {
			#expect(contentMaxX(of: line) <= 260.5)
		}
	}

	// MARK: - Block Float Layout

	@Test("Block floated right becomes a column that text wraps around")
	func blockFloatRight() throws {
		let html = "<div style=\"float:right; width:150px; margin:0\">floated content that wraps inside the column over several lines</div><p style=\"margin:0\">\(wrapText)</p>"
		let result = try layoutFrame(forHTML: html)

		let output = result.string
		var floatRange = NSRange()
		let floatLocation = (output.string as NSString).range(of: "floated").location
		_ = output.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: floatLocation, longestEffectiveRange: &floatRange, in: NSRange(location: 0, length: output.length))

		var columnLineCount = 0

		for line in lines(of: result.frame) {
			let lineRange = line.stringRange()

			if NSLocationInRange(lineRange.location, floatRange) {
				// column lines live within the right-hand 150pt column
				columnLineCount += 1
				#expect(line.frame.origin.x >= 249.5)
				#expect(contentMaxX(of: line) <= 400.5)
			} else {
				// main text starts at the left edge
				#expect(abs(line.frame.origin.x - 0) < 0.5)
			}
		}

		// the column content wraps into multiple lines
		#expect(columnLineCount > 1)

		// main text lines beside the column are narrowed
		let columnBottom = lines(of: result.frame)
			.filter { NSLocationInRange($0.stringRange().location, floatRange) }
			.map { $0.frame.maxY }.max() ?? 0

		var sawNarrowLine = false
		for line in lines(of: result.frame) where !NSLocationInRange(line.stringRange().location, floatRange) {
			if line.frame.minY < columnBottom {
				#expect(contentMaxX(of: line) <= 250.5)
				sawNarrowLine = true
			}
		}
		#expect(sawNarrowLine)
	}

	@Test("Block float without width shrinks to fit its content")
	func blockFloatShrinkToFit() throws {
		let html = "<div style=\"float:left\">short</div><p style=\"margin:0\">\(wrapText)</p>"
		let result = try layoutFrame(forHTML: html)

		let output = result.string
		var floatRange = NSRange()
		let floatLocation = (output.string as NSString).range(of: "short").location
		_ = output.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: floatLocation, longestEffectiveRange: &floatRange, in: NSRange(location: 0, length: output.length))

		let columnLines = lines(of: result.frame).filter { NSLocationInRange($0.stringRange().location, floatRange) }
		let columnLine = try #require(columnLines.first)

		// the column hugs the word at the left edge
		#expect(abs(columnLine.frame.origin.x - 0) < 0.5)
		let columnWidth = contentMaxX(of: columnLine)
		#expect(columnWidth < 100)

		// text beside the column is indented past it
		var sawIndentedLine = false
		for line in lines(of: result.frame) where !NSLocationInRange(line.stringRange().location, floatRange) {
			if line.frame.minY < columnLine.frame.maxY {
				#expect(line.frame.origin.x >= columnWidth - 0.5)
				sawIndentedLine = true
			}
		}
		#expect(sawIndentedLine)
	}

	// MARK: - Clear

	@Test("Clear makes a paragraph start below the float")
	func clearStartsBelowFloat() throws {
		let html = "<img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:left\"><p style=\"margin:0\">beside</p><p style=\"margin:0; clear:left\">below</p>"
		let result = try layoutFrame(forHTML: html)

		let imageLine = try #require(attachmentLines(of: result.frame).first)
		let flowLines = textLines(of: result.frame)

		let besideLine = try #require(flowLines.first)
		let clearedLine = try #require(flowLines.dropFirst().first)

		// first paragraph flows beside the float, indented
		#expect(abs(besideLine.frame.origin.x - 100) < 0.5)
		#expect(besideLine.frame.minY < imageLine.frame.maxY)

		// cleared paragraph starts below the float's bottom at full width
		#expect(clearedLine.frame.minY >= imageLine.frame.maxY - 0.5)
		#expect(abs(clearedLine.frame.origin.x - 0) < 0.5)
	}

	// MARK: - Frame Metrics

	@Test("A float taller than the text extends the frame height")
	func floatExtendsFrameHeight() throws {
		let html = "<p style=\"margin:0\"><img src=\"Oliver.jpg\" width=\"100\" height=\"200\" style=\"float:right\">short</p>"
		let result = try layoutFrame(forHTML: html)

		// the frame must be at least as tall as the floated image
		#expect(result.frame.frame.height >= 200)
	}

	// MARK: - Line Limits

	@Test("numberOfLines counts flow lines, not float lines")
	func numberOfLinesWithLeadingFloat() throws {
		let html = "<p style=\"margin:0\"><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:left\">\(wrapText)</p>"
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: html))
		let layouter = try #require(CoreTextLayouter(attributedString: attributedString))

		let maxRect = CGRect(x: 0, y: 0, width: 400, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
		let entireString = NSRange(location: 0, length: attributedString.length)
		let frame = try #require(layouter.layoutFrame(with: maxRect, range: entireString))
		frame.numberOfLines = 2

		let allLines = lines(of: frame)
		let flowLines = allLines.filter { $0.attachments == nil }
		let imageLines = allLines.filter { $0.attachments != nil }

		// the float still shows, and the limit applies to the text lines beside it
		#expect(imageLines.count == 1)
		#expect(flowLines.count == 2)
	}

	// MARK: - Pagination

	@Test("A float that does not fit moves to the continuation frame")
	func floatPaginatesToNextFrame() throws {
		let html = "<p style=\"margin:0\">\(wrapText)</p><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:left\"><p style=\"margin:0\">after the image</p>"
		let attributedString = try #require(TestHelpers.attributedString(fromHTML: html))
		let layouter = try #require(CoreTextLayouter(attributedString: attributedString))
		let fullRange = NSRange(location: 0, length: attributedString.length)

		// a frame that holds part of the text but has no room for the float
		let firstFrame = try #require(
			layouter.layoutFrame(with: CGRect(x: 0, y: 0, width: 400, height: 80), range: fullRange))

		let firstVisible = firstFrame.visibleStringRange()
		#expect(firstVisible.length > 0)
		#expect(firstVisible.length < attributedString.length)
		#expect(attachmentLines(of: firstFrame).isEmpty)

		// the continuation frame starts with the float and keeps all remaining content
		let continuationStart = NSMaxRange(firstVisible)
		let secondFrame = try #require(
			layouter.layoutFrame(
				with: CGRect(x: 0, y: 0, width: 400, height: 600),
				range: NSRange(
					location: continuationStart, length: attributedString.length - continuationStart)))

		let secondVisible = secondFrame.visibleStringRange()
		#expect(NSMaxRange(secondVisible) == attributedString.length)

		let imageLine = try #require(attachmentLines(of: secondFrame).first)
		#expect(abs(imageLine.frame.origin.x - 0) < 0.5)

		// the trailing paragraph flows beside the image in the second frame
		let afterRange = (attributedString.string as NSString).range(of: "after")
		let afterLine = try #require(secondFrame.lineContaining(index: UInt(afterRange.location)))
		#expect(afterLine.frame.origin.x >= 99.5)
	}

	// MARK: - HTML Writer Round-Trip

	@Test("Floated image round-trips through HTML writing")
	func floatedImageRoundTrip() throws {
		let html = "<p><img src=\"Oliver.jpg\" width=\"100\" height=\"100\" style=\"float:right\">text beside the image</p>"
		let string1 = try #require(TestHelpers.attributedString(fromHTML: html))

		let writer = HTMLWriter(attributedString: string1)
		let writtenHTML = writer.htmlFragment()

		#expect(writtenHTML.contains("float:right"))

		let string2 = try #require(TestHelpers.attributedString(fromHTML: writtenHTML))
		let placeholderRange = (string2.string as NSString).range(of: UNICODE_OBJECT_PLACEHOLDER)
		#expect(placeholderRange.location != NSNotFound)

		let value = string2.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: placeholderRange.location, effectiveRange: nil) as? NSNumber
		#expect(value?.uintValue == DTHTMLElementFloatStyle.right.rawValue)
	}

	@Test("Floated block round-trips through HTML writing")
	func floatedBlockRoundTrip() throws {
		let html = "<div style=\"float:left; width:120px\">floated column</div><p>main text</p>"
		let string1 = try #require(TestHelpers.attributedString(fromHTML: html))

		let writer = HTMLWriter(attributedString: string1)
		let writtenHTML = writer.htmlFragment()

		#expect(writtenHTML.contains("float:left"))
		#expect(writtenHTML.contains("width:120px"))

		let string2 = try #require(TestHelpers.attributedString(fromHTML: writtenHTML))

		let floatedLocation = (string2.string as NSString).range(of: "floated").location
		#expect(floatedLocation != NSNotFound)

		let style = string2.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: floatedLocation, effectiveRange: nil) as? NSNumber
		#expect(style?.uintValue == DTHTMLElementFloatStyle.left.rawValue)

		let width = string2.attribute(NSAttributedString.Key(rawValue: DTFloatWidthAttribute), at: floatedLocation, effectiveRange: nil) as? NSNumber
		#expect(width?.doubleValue == 120)

		// the main text must not be inside the float
		let mainLocation = (string2.string as NSString).range(of: "main").location
		let mainStyle = string2.attribute(NSAttributedString.Key(rawValue: DTFloatStyleAttribute), at: mainLocation, effectiveRange: nil)
		#expect(mainStyle == nil)
	}

	@Test("Clear round-trips through HTML writing")
	func clearRoundTrip() throws {
		let html = "<p style=\"clear:both\">below the floats</p>"
		let string1 = try #require(TestHelpers.attributedString(fromHTML: html))

		let writer = HTMLWriter(attributedString: string1)
		let writtenHTML = writer.htmlFragment()

		#expect(writtenHTML.contains("clear:both"))

		let string2 = try #require(TestHelpers.attributedString(fromHTML: writtenHTML))
		let value = string2.attribute(NSAttributedString.Key(rawValue: DTClearFloatsAttribute), at: 0, effectiveRange: nil) as? NSNumber
		#expect(value?.uintValue == DTHTMLElementClearStyle.both.rawValue)
	}
}
