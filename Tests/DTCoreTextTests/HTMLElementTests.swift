import Testing
import Foundation
import CoreText
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("HTML Element", .serialized)
struct HTMLElementTests {
	@Test("HTML align attribute sets correct text alignment", arguments: [
		("<div align=\"justify\">text to align</div>", CTTextAlignment.justified),
		("<div align=\"left\">text to align</div>", CTTextAlignment.left),
		("<div align=\"right\">text to align</div>", CTTextAlignment.right),
		("<div align=\"center\">text to align</div>", CTTextAlignment.center),
	])
	func htmlAlign(html: String, expectedAlignment: CTTextAlignment) {
		let attributedString = TestHelpers.attributedString(fromHTML: html)!

		let paragraphStyle = attributedString.attribute(NSAttributedString.Key(kCTParagraphStyleAttributeName as String), at: 0, effectiveRange: nil) as! CTParagraphStyle
		var alignment = CTTextAlignment.natural
		CTParagraphStyleGetValueForSpecifier(paragraphStyle, .alignment, MemoryLayout<CTTextAlignment>.size, &alignment)

		#expect(alignment == expectedAlignment)
	}

	@Test("Combining WebKit and normal margin")
	func combiningWebKitAndNormalMargin() {
		let element = HTMLElement(name: "", attributes: nil)
		element.textScale = 1
		element.paragraphStyle = CoreTextParagraphStyle.defaultParagraphStyle()
		let font = CTFontCreateWithName("Helvetica" as CFString, 20, nil)
		element.fontDescriptor = CoreTextFontDescriptor(ctFont: font)

		let styles: [String: String] = [
			"-webkit-margin-after": "1em",
			"-webkit-margin-before": "1em",
			"-webkit-margin-end": "0",
			"-webkit-margin-start": "0",
			"display": "block",
			"margin-left": "40px",
		]

		element.applyStyles(styles)

		#expect(element.margins.left == 40)
		#expect(element.margins.right == 0)
		#expect(element.margins.top == 20)
		#expect(element.margins.bottom == 20)
	}

	@Test("Attachment with display:none should be invisible")
	func attachmentWithDisplayNone() {
		let element = HTMLElement(name: "", attributes: nil)
		element.textScale = 1
		element.paragraphStyle = CoreTextParagraphStyle.defaultParagraphStyle()
		let font = CTFontCreateWithName("Helvetica" as CFString, 20, nil)
		element.fontDescriptor = CoreTextFontDescriptor(ctFont: font)

		let object = ObjectTextAttachment().configured(with: element, options: nil)
		element.textAttachment = object

		let styles: [String: String] = ["display": "none"]
		element.applyStyles(styles)

		let attributedString = element.attributedString()
		#expect(attributedString == nil)
	}

	@Test("Attachment with percent width and height")
	func attachmentWithPercentWidthAndHeight() {
		let maxImageSize = CGSize(width: 500, height: 500)
		#if canImport(UIKit)
		let sizeValue = NSValue(cgSize: maxImageSize)
		#else
		let sizeValue = NSValue(size: maxImageSize)
		#endif
		let options: [String: Any] = [
			DTMaxImageSize: sizeValue,
			DTDefaultFontSize: NSNumber(value: 16.0),
		]

		let attachment = HTMLElement.element(name: "img", attributes: nil, options: options)
		attachment.textAttachment!.originalSize = CGSize(width: 1000, height: 800)

		attachment.applyStyles(["width": "100%", "height": "100%"])
		#expect(attachment.textAttachment!.displaySize.width == 500)
		#expect(attachment.textAttachment!.displaySize.height == 500)

		attachment.applyStyles(["width": "80%", "height": "100%"])
		#expect(attachment.textAttachment!.displaySize.width == 400)
		#expect(attachment.textAttachment!.displaySize.height == 500)

		attachment.applyStyles(["width": "110%", "height": "80%"])
		#expect(attachment.textAttachment!.displaySize.width == 500)
		#expect(attachment.textAttachment!.displaySize.height == 364)

		attachment.applyStyles(["width": "100%", "height": "110%"])
		#expect(attachment.textAttachment!.displaySize.width == 455)
		#expect(attachment.textAttachment!.displaySize.height == 500)
	}

	#if canImport(UIKit)
	@Test("Missing UIKit font traits are synthesized")
	func missingUIKitFontTraitsAreSynthesized() throws {
		_ = try #require(UIFont(name: "Zapfino", size: 20))
		let attributedString = try #require(TestHelpers.attributedString(
			fromHTML: "<span style=\"font-family:'Zapfino'\"><b><i>text</i></b></span>"))
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let resolvedFont = try #require(attributes[NSAttributedString.Key.font] as? UIFont)

		#expect(!resolvedFont.fontDescriptor.symbolicTraits.contains(.traitBold))
		#expect(!resolvedFont.fontDescriptor.symbolicTraits.contains(.traitItalic))
		#expect(attributes[NSAttributedString.Key.obliqueness] as? NSNumber == 0.2)
		#expect(attributes[NSAttributedString.Key.strokeWidth] as? NSNumber == -3.0)
	}

	@Test("Existing UIKit font traits are not synthesized")
	func existingUIKitFontTraitsAreNotSynthesized() throws {
		let requestedFonts = [
			("Helvetica-Bold", NSAttributedString.Key.strokeWidth),
			("Helvetica-Oblique", NSAttributedString.Key.obliqueness),
		]

		for (fontName, syntheticAttribute) in requestedFonts {
			let font = try #require(UIFont(name: fontName, size: 20))
			let element = HTMLElement(name: "span", attributes: nil)
			element.fontDescriptor = CoreTextFontDescriptor(
				ctFont: CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil))

			let attributes = element.attributesForAttributedStringRepresentation()
			#expect(attributes[syntheticAttribute] == nil)
		}
	}
	#endif
}
