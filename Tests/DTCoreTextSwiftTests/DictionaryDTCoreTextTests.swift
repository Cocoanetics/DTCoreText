import Testing
import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("NSDictionary+DTCoreText", .serialized)
struct DictionaryDTCoreTextTests {
	@Test("Bold detection")
	func bold() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<b>bold</b>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.isBold())
	}

	@Test("Italic detection")
	func italic() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<i>italic</i>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.isItalic())
	}

	@Test("Underline detection")
	func underline() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<u>underline</u>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.isUnderline())
	}

	@Test("NS underline detection")
	func nsUnderline() {
		let buildAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSNumber(value: true)]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.isUnderline())
	}

	@Test("Strikethrough detection")
	func strikethrough() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<del>strikethrough</del>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.isStrikethrough())
	}

	@Test("NS strikethrough detection")
	func nsStrikethrough() {
		let buildAttributes: [NSAttributedString.Key: Any] = [.strikethroughStyle: NSNumber(value: true)]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.isStrikethrough())
	}

	@Test("Header level detection")
	func headerLevel() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<h3>header</h3>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.headerLevel() == 3)
	}

	@Test("Attachment detection")
	func hasAttachment() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<img src=\"Oliver.jpg\">")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.hasAttachment())
	}

	@Test("Paragraph style from HTML")
	func paragraphStyle() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>Paragraph</p>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let paragraphStyle = attributes.paragraphStyle()
		#expect(paragraphStyle != nil)
		#expect(paragraphStyle is CoreTextParagraphStyle)
	}

	@Test("Nil paragraph style")
	func paragraphStyleNil() {
		let attributedString = NSAttributedString(string: "string")
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.paragraphStyle() == nil)
	}

	@Test("NS paragraph style")
	func nsParagraphStyle() {
		let nsParagraphStyle = NSMutableParagraphStyle()
		let buildAttributes: [NSAttributedString.Key: Any] = [.paragraphStyle: nsParagraphStyle]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let paragraphStyle = attributes.paragraphStyle()
		#expect(paragraphStyle != nil)
		#expect(paragraphStyle is CoreTextParagraphStyle)
	}

	@Test("Font descriptor from HTML")
	func fontDescriptor() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>Paragraph</p>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.fontDescriptor() != nil)
	}

	@Test("Direct font descriptor")
	func directFontDescriptor() {
		#if canImport(UIKit)
		let font = UIFont(name: "Courier", size: 12)!
		#else
		let font = NSFont(name: "Courier", size: 12)!
		#endif
		let attributes: NSDictionary = [NSAttributedString.Key.font: font]
		let fontDescriptor = attributes.fontDescriptor()
		#expect(fontDescriptor != nil)
		#expect(fontDescriptor?.fontFamily == "Courier")
	}

	@Test("Nil font descriptor")
	func fontDescriptorNil() {
		let attributedString = NSAttributedString(string: "string")
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.fontDescriptor() == nil)
	}

	@Test("Default colors")
	func colorDefaults() {
		let attributedString = NSAttributedString(string: "string")
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let color = attributes.foregroundColor()
		let hexColor = DTHexStringFromDTColor(color)
		#expect(hexColor == "000000")
		#expect(attributes.backgroundColor() == nil)
	}

	@Test("Valid colors from HTML")
	func validColors() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"color:red;background-color:blue;\">Paragraph</span>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let fgHex = DTHexStringFromDTColor(attributes.foregroundColor())
		#expect(fgHex == "ff0000")
		let bgHex = DTHexStringFromDTColor(attributes.backgroundColor())
		#expect(bgHex == "0000ff")
	}

	@Test("NS valid colors from direct attributes")
	func nsValidColors() {
		let buildAttributes: [NSAttributedString.Key: Any] = [
			.foregroundColor: DTColorCreateWithHTMLName("red")!,
			.backgroundColor: DTColorCreateWithHTMLName("blue")!,
		]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let fgHex = DTHexStringFromDTColor(attributes.foregroundColor())
		#expect(fgHex == "ff0000")
		let bgHex = DTHexStringFromDTColor(attributes.backgroundColor())
		#expect(bgHex == "0000ff")
	}

	@Test("NS valid colors from HTML with iOS6 attributes")
	func nsValidColorsFromHTML() {
		let options: [String: Any] = [DTUseiOS6Attributes: NSNumber(value: true)]
		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"color:red;background-color:blue;\">Paragraph</span>", options: options)!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let fgHex = DTHexStringFromDTColor(attributes.foregroundColor())
		#expect(fgHex == "ff0000")
		let bgHex = DTHexStringFromDTColor(attributes.backgroundColor())
		#expect(bgHex == "0000ff")
	}

	@Test("Kerning from HTML")
	func kerning() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p style=\"letter-spacing:10px\">Paragraph</p>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.kerning() == 10.0)
	}
}
