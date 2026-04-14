import Testing
import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("Font Descriptor", .serialized)
struct FontDescriptorTests {
	private var previousFallbackFontFamily: String?

	init() {
		previousFallbackFontFamily = CoreTextFontDescriptor.fallbackFontFamily()
	}

	@Test("Fallback font family is used for unknown fonts")
	func fallbackFamily() throws {
		try CoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { try? CoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\">text</span>")
		#expect(attributedString != nil)

		var effectiveRange = NSRange()
		let attributes = attributedString!.attributes(at: 0, effectiveRange: &effectiveRange) as NSDictionary

		let expectedRange = NSRange(location: 0, length: attributedString!.length)
		#expect(effectiveRange.length == expectedRange.length)
		#expect(effectiveRange.location == expectedRange.location)

		let fontDescriptor = attributes.dtct_fontDescriptor()
		#expect(fontDescriptor?.fontFamily == "Arial")
	}

	#if canImport(UIKit)
	@Test("UIFontDescriptor option sets correct font family")
	func fontDescriptor() {
		// Use a concrete font family instead of the system font, which has
		// a private family name (.AppleSystemUIFont) that DTCoreText doesn't handle.
		let descriptor = UIFontDescriptor(name: "Georgia", size: 17)
		let font = UIFont(descriptor: descriptor, size: descriptor.pointSize)

		let options: [String: Any] = [DTDefaultFontDescriptor: descriptor]

		let attributedString = TestHelpers.attributedString(fromHTML: "<html><body><p>Regular<b>Bold</b><i>Italic</i><p></body></html>", options: options)!

		let attributesPlain = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let fontDescriptorPlain = attributesPlain.dtct_fontDescriptor()!
		#expect(fontDescriptorPlain.fontFamily == font.familyName)
		#expect(!fontDescriptorPlain.boldTrait)
		#expect(!fontDescriptorPlain.italicTrait)

		let attributesBold = attributedString.attributes(at: 7, effectiveRange: nil) as NSDictionary
		let fontDescriptorBold = attributesBold.dtct_fontDescriptor()!
		#expect(fontDescriptorBold.fontFamily == font.familyName)
		#expect(fontDescriptorBold.boldTrait)
		#expect(!fontDescriptorBold.italicTrait)

		let attributesItalic = attributedString.attributes(at: 11, effectiveRange: nil) as NSDictionary
		let fontDescriptorItalic = attributesItalic.dtct_fontDescriptor()!
		#expect(fontDescriptorItalic.fontFamily == font.familyName)
		#expect(!fontDescriptorItalic.boldTrait)
		#expect(fontDescriptorItalic.italicTrait)
	}

	@Test("Fallback font family without font traits")
	func fallbackFontFamilyWithoutFontTraits() throws {
		try CoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { try? CoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\"><p>text</p></span>")!

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let dtFontDescriptor = attributes.dtct_fontDescriptor()!
		#expect(!dtFontDescriptor.boldTrait)
		#expect(!dtFontDescriptor.italicTrait)
		#expect(dtFontDescriptor.fontFamily == "Arial")
	}

	@Test("Fallback font family with bold font trait")
	func fallbackFontFamilyWithBoldFontTrait() throws {
		try CoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { try? CoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\"><b>text</b></span>")!

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let dtFontDescriptor = attributes.dtct_fontDescriptor()!
		#expect(dtFontDescriptor.boldTrait)
		#expect(!dtFontDescriptor.italicTrait)
		#expect(dtFontDescriptor.fontFamily == "Arial")
	}

	@Test("Fallback font family with italic font trait")
	func fallbackFontFamilyWithItalicFontTrait() throws {
		try CoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { try? CoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\"><em>text</em></span>")!

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let dtFontDescriptor = attributes.dtct_fontDescriptor()!
		#expect(!dtFontDescriptor.boldTrait)
		#expect(dtFontDescriptor.italicTrait)
		#expect(dtFontDescriptor.fontFamily == "Arial")
	}
	#endif

	@Test("Empty fallback font family throws emptyFontFamily")
	func emptyFallbackFamily() {
		#expect(throws: CoreTextFontDescriptor.FontError.emptyFontFamily) {
			try CoreTextFontDescriptor.setFallbackFontFamily("")
		}
	}

	@Test("Unknown fallback font family throws unknownFontFamily")
	func unknownFallbackFamily() {
		#expect(throws: CoreTextFontDescriptor.FontError.unknownFontFamily("ZZZNonExistentFont")) {
			try CoreTextFontDescriptor.setFallbackFontFamily("ZZZNonExistentFont")
		}
	}
}
