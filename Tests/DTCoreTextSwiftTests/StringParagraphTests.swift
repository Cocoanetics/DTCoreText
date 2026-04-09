import Testing
import Foundation
@testable import DTCoreText

@Suite("String Paragraph", .serialized)
struct StringParagraphTests {
	@Test("Finds paragraph ranges correctly")
	func paragraphFinding() {
		let string = "abc\ndef\n\nghi" as NSString

		// range on NL character
		var begIndex: UInt = 0
		var endIndex: UInt = 0
		var paragraphRange = string.range(ofParagraphsContaining: NSRange(location: 3, length: 1), parBeg: &begIndex, parEnd: &endIndex)
		#expect(paragraphRange == NSRange(location: 0, length: 4))
		#expect(begIndex == 0)
		#expect(endIndex == 4)

		// empty range
		paragraphRange = string.range(ofParagraphsContaining: NSRange(location: 3, length: 0), parBeg: &begIndex, parEnd: &endIndex)
		#expect(paragraphRange == NSRange(location: 0, length: 4))
		#expect(begIndex == 0)
		#expect(endIndex == 4)

		// test empty paragraph
		paragraphRange = string.range(ofParagraphsContaining: NSRange(location: 8, length: 1), parBeg: &begIndex, parEnd: &endIndex)
		#expect(paragraphRange == NSRange(location: 8, length: 1))
		#expect(begIndex == 8)
		#expect(endIndex == 9)

		// range at end of string
		paragraphRange = string.range(ofParagraphsContaining: NSRange(location: 9, length: 2), parBeg: &begIndex, parEnd: &endIndex)
		#expect(paragraphRange == NSRange(location: 9, length: 3))
		#expect(begIndex == 9)
		#expect(endIndex == 12)
	}
}
