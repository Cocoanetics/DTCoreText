import Testing
import Foundation
@testable import DTCoreTextSwift

@Suite("String HTML Entities", .serialized)
struct StringHTMLTests {
	@Test("Emoji encoding and decoding round-trip")
	func emojiEncodingAndDecoding() {
		let string = "😄"
		let encoded = string.addingHTMLEntities()
		#expect(encoded == "&#128516;")

		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == string)
	}

	@Test("Hex entity decoding")
	func hexDecoding() {
		let decoded = "&#x1F604;".replacingHTMLEntities()
		#expect(decoded == "😄")
	}

	@Test("Known entity decoding")
	func knownEntityDecoding() {
		let decoded = "&lt;&gt;".replacingHTMLEntities()
		#expect(decoded == "<>")
	}

	@Test("Unclosed decimal entity is not decoded")
	func unclosedDecoding() {
		let encoded = "&#128516test"
		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == encoded)
	}

	@Test("Unclosed hex entity is not decoded")
	func unclosedHexDecoding() {
		let encoded = "&#x1F604test"
		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == encoded)
	}

	@Test("Unclosed known entity is not decoded")
	func unclosedKnownEntityDecoding() {
		let encoded = "&lttest"
		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == encoded)
	}

	@Test("Invalid decimal entity is not decoded")
	func invalidDecoding() {
		let encoded = "&#hello;"
		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == encoded)
	}

	@Test("Invalid hex entity is not decoded")
	func invalidHexDecoding() {
		let encoded = "&#xsup;"
		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == encoded)
	}

	@Test("Unknown entity is not decoded")
	func unknownEntityDecoding() {
		let encoded = "&unknowncode;"
		let decoded = encoded.replacingHTMLEntities()
		#expect(decoded == encoded)
	}

	@Test("Apple converted space handling")
	func appleConvertedSpace() {
		let nbsp = "\u{00a0}"

		// One space - no conversion
		let s1 = "1 1".addingAppleConvertedSpace()
		#expect(s1 == "1 1")

		// Two spaces
		let s2 = "2  2".addingAppleConvertedSpace()
		let expected2 = "2 <span class=\"Apple-converted-space\">\(nbsp)</span>2"
		#expect(s2 == expected2)

		// Three spaces
		let s3 = "3   3".addingAppleConvertedSpace()
		let expected3 = "3 <span class=\"Apple-converted-space\">\(nbsp) </span>3"
		#expect(s3 == expected3)

		// Four spaces
		let s4 = "4    4".addingAppleConvertedSpace()
		let expected4 = "4 <span class=\"Apple-converted-space\">\(nbsp) \(nbsp)</span>4"
		#expect(s4 == expected4)
	}
}
