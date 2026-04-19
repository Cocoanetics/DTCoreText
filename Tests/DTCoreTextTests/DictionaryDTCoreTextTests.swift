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
		#expect(attributes.dtct_isBold())
	}

	@Test("Italic detection")
	func italic() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<i>italic</i>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_isItalic())
	}

	@Test("Underline detection")
	func underline() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<u>underline</u>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_isUnderline())
	}

	@Test("NS underline detection")
	func nsUnderline() {
		let buildAttributes: [NSAttributedString.Key: Any] = [.underlineStyle: NSNumber(value: true)]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_isUnderline())
	}

	@Test("Strikethrough detection")
	func strikethrough() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<del>strikethrough</del>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_isStrikethrough())
	}

	@Test("NS strikethrough detection")
	func nsStrikethrough() {
		let buildAttributes: [NSAttributedString.Key: Any] = [.strikethroughStyle: NSNumber(value: true)]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_isStrikethrough())
	}

	@Test("Header level detection")
	func headerLevel() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<h3>header</h3>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_headerLevel() == 3)
	}

	@Test("Attachment detection")
	func hasAttachment() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<img src=\"Oliver.jpg\">")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_hasAttachment())
	}

	@Test("Paragraph style from HTML")
	func paragraphStyle() throws {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>Paragraph</p>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		_ = try #require(attributes.dtct_paragraphStyle())
	}

	@Test("Nil paragraph style")
	func paragraphStyleNil() {
		let attributedString = NSAttributedString(string: "string")
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_paragraphStyle() == nil)
	}

	@Test("NS paragraph style")
	func nsParagraphStyle() throws {
		let nsParagraphStyle = NSMutableParagraphStyle()
		let buildAttributes: [NSAttributedString.Key: Any] = [.paragraphStyle: nsParagraphStyle]
		let attributedString = NSAttributedString(string: "string", attributes: buildAttributes)
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		_ = try #require(attributes.dtct_paragraphStyle())
	}

	@Test("Font descriptor from HTML")
	func fontDescriptor() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p>Paragraph</p>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_fontDescriptor() != nil)
	}

	@Test("Direct font descriptor")
	func directFontDescriptor() {
		#if canImport(UIKit)
		let font = UIFont(name: "Courier", size: 12)!
		#else
		let font = NSFont(name: "Courier", size: 12)!
		#endif
		let attributes: NSDictionary = [NSAttributedString.Key.font: font]
		let fontDescriptor = attributes.dtct_fontDescriptor()
		#expect(fontDescriptor != nil)
		#expect(fontDescriptor?.fontFamily == "Courier")
	}

	@Test("Nil font descriptor")
	func fontDescriptorNil() {
		let attributedString = NSAttributedString(string: "string")
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_fontDescriptor() == nil)
	}

	@Test("Default colors")
	func colorDefaults() {
		let attributedString = NSAttributedString(string: "string")
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let color = attributes.dtct_foregroundColor()
		let hexColor = DTHexStringFromDTColor(color)
		#expect(hexColor == "000000")
		#expect(attributes.dtct_backgroundColor() == nil)
	}

	@Test("Valid colors from HTML")
	func validColors() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"color:red;background-color:blue;\">Paragraph</span>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let fgHex = DTHexStringFromDTColor(attributes.dtct_foregroundColor())
		#expect(fgHex == "ff0000")
		let bgHex = DTHexStringFromDTColor(attributes.dtct_backgroundColor()!)
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
		let fgHex = DTHexStringFromDTColor(attributes.dtct_foregroundColor())
		#expect(fgHex == "ff0000")
		let bgHex = DTHexStringFromDTColor(attributes.dtct_backgroundColor()!)
		#expect(bgHex == "0000ff")
	}

	@Test("NS valid colors from HTML with iOS6 attributes")
	func nsValidColorsFromHTML() {
		let options: [String: Any] = [DTUseiOS6Attributes: NSNumber(value: true)]
		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"color:red;background-color:blue;\">Paragraph</span>", options: options)!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let fgHex = DTHexStringFromDTColor(attributes.dtct_foregroundColor())
		#expect(fgHex == "ff0000")
		let bgHex = DTHexStringFromDTColor(attributes.dtct_backgroundColor()!)
		#expect(bgHex == "0000ff")
	}

	@Test("Kerning from HTML")
	func kerning() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<p style=\"letter-spacing:10px\">Paragraph</p>")!
		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		#expect(attributes.dtct_kerning() == 10.0)
	}
}
