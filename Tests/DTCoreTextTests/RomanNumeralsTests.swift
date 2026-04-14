import Testing
import Foundation
@testable import DTCoreText

@Suite("Roman Numerals", .serialized)
struct RomanNumeralsTests {
	@Test("Converts numbers to Roman numerals", arguments: [
		(1, "I"),
		(5, "V"),
		(9, "IX"),
		(10, "X"),
		(11, "XI"),
		(49, "XLIX"),
		(880, "DCCCLXXX"),
		(3999, "MMMCMXCIX"),
	])
	func romanNumeralConversion(number: Int, expected: String) {
		let result = (number as NSNumber).romanNumeral()
		#expect(result == expected)
	}
}
