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
		previousFallbackFontFamily = DTCoreTextFontDescriptor.fallbackFontFamily()
	}

	@Test("Fallback font family is used for unknown fonts")
	func fallbackFamily() {
		DTCoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { DTCoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\">text</span>")
		#expect(attributedString != nil)

		var effectiveRange = NSRange()
		let attributes = attributedString!.attributes(at: 0, effectiveRange: &effectiveRange) as NSDictionary

		let expectedRange = NSRange(location: 0, length: attributedString!.length)
		#expect(effectiveRange.length == expectedRange.length)
		#expect(effectiveRange.location == expectedRange.location)

		let fontDescriptor = attributes.fontDescriptor()
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
		let fontDescriptorPlain = attributesPlain.fontDescriptor()!
		#expect(fontDescriptorPlain.fontFamily == font.familyName)
		#expect(!fontDescriptorPlain.boldTrait)
		#expect(!fontDescriptorPlain.italicTrait)

		let attributesBold = attributedString.attributes(at: 7, effectiveRange: nil) as NSDictionary
		let fontDescriptorBold = attributesBold.fontDescriptor()!
		#expect(fontDescriptorBold.fontFamily == font.familyName)
		#expect(fontDescriptorBold.boldTrait)
		#expect(!fontDescriptorBold.italicTrait)

		let attributesItalic = attributedString.attributes(at: 11, effectiveRange: nil) as NSDictionary
		let fontDescriptorItalic = attributesItalic.fontDescriptor()!
		#expect(fontDescriptorItalic.fontFamily == font.familyName)
		#expect(!fontDescriptorItalic.boldTrait)
		#expect(fontDescriptorItalic.italicTrait)
	}

	@Test("Fallback font family without font traits")
	func fallbackFontFamilyWithoutFontTraits() {
		DTCoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { DTCoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\"><p>text</p></span>")!

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let dtFontDescriptor = attributes.fontDescriptor()!
		#expect(!dtFontDescriptor.boldTrait)
		#expect(!dtFontDescriptor.italicTrait)
		#expect(dtFontDescriptor.fontFamily == "Arial")
	}

	@Test("Fallback font family with bold font trait")
	func fallbackFontFamilyWithBoldFontTrait() {
		DTCoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { DTCoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\"><b>text</b></span>")!

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let dtFontDescriptor = attributes.fontDescriptor()!
		#expect(dtFontDescriptor.boldTrait)
		#expect(!dtFontDescriptor.italicTrait)
		#expect(dtFontDescriptor.fontFamily == "Arial")
	}

	@Test("Fallback font family with italic font trait")
	func fallbackFontFamilyWithItalicFontTrait() {
		DTCoreTextFontDescriptor.setFallbackFontFamily("Arial")
		defer { DTCoreTextFontDescriptor.setFallbackFontFamily(previousFallbackFontFamily ?? "Times New Roman") }

		let attributedString = TestHelpers.attributedString(fromHTML: "<span style=\"font-family:FooBar\"><em>text</em></span>")!

		let attributes = attributedString.attributes(at: 0, effectiveRange: nil) as NSDictionary
		let dtFontDescriptor = attributes.fontDescriptor()!
		#expect(!dtFontDescriptor.boldTrait)
		#expect(dtFontDescriptor.italicTrait)
		#expect(dtFontDescriptor.fontFamily == "Arial")
	}
	#endif

	// Note: setFallbackFontFamily: with nil or invalid values throws NSException
	// (ObjC exception), which cannot be caught by Swift's #expect(throws:).
	// These tests are omitted to avoid crashes. The behavior is tested in the ObjC test suite.
}
