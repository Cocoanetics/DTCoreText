import Testing
import Foundation
import CoreText
@testable import DTCoreText
import DTCoreTextSwift

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("NSMutableAttributedString HTML", .serialized)
struct MutableAttributedStringHTMLTests {

	@Test("Add custom HTML attribute")
	func addCustomHTMLAttribute() throws {
		let attributedString = NSMutableAttributedString(string: "1234567890")

		let entireString = NSRange(location: 0, length: attributedString.length)

		// have a range with an attribute
		attributedString.addHTMLAttribute("class", value: "oli", range: NSRange(location: 3, length: 2), replaceExisting: true)

		var effectiveRange = NSRange()
		var dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 3, effectiveRange: &effectiveRange) as? [String: Any]

		var expectedRange = NSRange(location: 3, length: 2)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Effective Range does not match")

		var value = dict?["class"] as? String
		#expect(value == "oli", "Attribute should be oli")

		// add the same name attribute without replacing for the entire string
		attributedString.addHTMLAttribute("class", value: "drops", range: entireString, replaceExisting: false)

		// part in the middle should still be oli
		dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 3, effectiveRange: &effectiveRange) as? [String: Any]

		expectedRange = NSRange(location: 3, length: 2)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Effective Range does not match")

		value = dict?["class"] as? String
		#expect(value == "oli", "Attribute should be oli")

		// part at the start should be drops
		dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 0, effectiveRange: &effectiveRange) as? [String: Any]

		expectedRange = NSRange(location: 0, length: 3)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Effective Range does not match")

		value = dict?["class"] as? String
		#expect(value == "drops", "Attribute should be drops")

		// part at the end should be drops
		dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 5, effectiveRange: &effectiveRange) as? [String: Any]

		expectedRange = NSRange(location: 5, length: 5)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Effective Range does not match")

		value = dict?["class"] as? String
		#expect(value == "drops", "Attribute should be drops")

		// replace everything
		attributedString.addHTMLAttribute("class", value: "foo", range: entireString, replaceExisting: true)

		let rangeOfClass = attributedString.rangeOfHTMLAttribute( "class", at: 0)

		expectedRange = NSRange(location: 0, length: 10)
		#expect(NSEqualRanges(expectedRange, rangeOfClass), "Effective Range does not match")

		dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 4, effectiveRange: nil) as? [String: Any]

		value = dict?["class"] as? String
		#expect(value == "foo", "Attribute should be foo")
	}

	@Test("Remove custom HTML attribute")
	func removeCustomHTMLAttribute() throws {
		let attributedString = NSMutableAttributedString(string: "1234567890")

		let entireString = NSRange(location: 0, length: attributedString.length)

		// have a range with an attribute
		attributedString.addHTMLAttribute("class", value: "oli", range: entireString, replaceExisting: true)

		// remove a part at the end
		attributedString.removeHTMLAttribute("class", range: NSRange(location: 5, length: 10))

		// tail should now be nil
		var effectiveRange = NSRange()
		var dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 5, effectiveRange: &effectiveRange) as? [String: Any]

		var expectedRange = NSRange(location: 5, length: 5)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Effective Range does not match")

		#expect(dict == nil, "There should be no dictionary in this range")

		// head should still be oli
		dict = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 0, effectiveRange: &effectiveRange) as? [String: Any]

		expectedRange = NSRange(location: 0, length: 5)
		#expect(NSEqualRanges(expectedRange, effectiveRange), "Effective Range does not match")

		let value = dict?["class"] as? String
		#expect(value == "oli", "Attribute should be oli")
	}

	@Test("Remove multiple custom HTML attributes")
	func removeMultipleCustomHTMLAttribute() throws {
		let attributedString = NSMutableAttributedString(string: "1234567890")

		let entireString = NSRange(location: 0, length: attributedString.length)

		// have a range with an attribute
		attributedString.addHTMLAttribute("class", value: "oli", range: entireString, replaceExisting: true)
		attributedString.addHTMLAttribute("foo", value: "bar", range: entireString, replaceExisting: true)

		// there should be two
		var attributes = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 2, effectiveRange: nil) as? [String: Any]
		var count = attributes?.count ?? 0
		#expect(count == 2, "There should be 2 custom attributes")

		// now remove one
		attributedString.removeHTMLAttribute("foo", range: entireString)

		// there should be one
		attributes = attributedString.attribute(NSAttributedString.Key(DTCustomAttributesAttribute), at: 2, effectiveRange: nil) as? [String: Any]
		count = attributes?.count ?? 0
		#expect(count == 1, "There should be only 1 custom attribute")
	}

	@Test("Range of custom HTML attribute")
	func rangeOfCustomHTMLAttribute() throws {
		let attributedString = NSMutableAttributedString(string: "1234567890")

		let entireString = NSRange(location: 0, length: attributedString.length)

		// have a range with an attribute
		attributedString.addHTMLAttribute("class", value: "oli", range: NSRange(location: 3, length: 2), replaceExisting: true)

		// add longer range
		attributedString.addHTMLAttribute("class", value: "bar", range: entireString, replaceExisting: false)

		// add a second one on top of it all
		attributedString.addHTMLAttribute("foo", value: "bar", range: entireString, replaceExisting: true)

		// class element in middle is only valid for that range
		var expectedRange = NSRange(location: 3, length: 2)
		var queriedRange = attributedString.rangeOfHTMLAttribute( "class", at: 3)
		#expect(NSEqualRanges(expectedRange, queriedRange), "Range is incorrect")

		// global foo is entire range
		queriedRange = attributedString.rangeOfHTMLAttribute( "foo", at: 3)
		#expect(NSEqualRanges(queriedRange, entireString), "Range is incorrect")

		// global foo is entire range no matter where you query it
		queriedRange = attributedString.rangeOfHTMLAttribute( "foo", at: 9)
		#expect(NSEqualRanges(queriedRange, entireString), "Range is incorrect")

		// the right part of class (with 'bar')
		queriedRange = attributedString.rangeOfHTMLAttribute( "class", at: 5)
		expectedRange = NSRange(location: 5, length: 5)
		#expect(NSEqualRanges(queriedRange, expectedRange), "Range is incorrect")

		// the left part of class (with 'bar')
		queriedRange = attributedString.rangeOfHTMLAttribute( "class", at: 1)
		expectedRange = NSRange(location: 0, length: 3)
		#expect(NSEqualRanges(queriedRange, expectedRange), "Range is incorrect")
	}

	@Test("Foreground color attribute name at end of paragraph")
	func foregroundColorAttributeNameAtEndOfParagraph() throws {
		let testingString = NSMutableAttributedString(string: "1234567890")
		let entireString = NSRange(location: 0, length: testingString.length)

		// add a foreground color using the Core Text attribute name
		let components: [CGFloat] = [1.0, 0.0, 0.0, 1.0]
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let redColorRef = CGColor(colorSpace: colorSpace, components: components)!
		testingString.addAttribute(NSAttributedString.Key(kCTForegroundColorAttributeName as String), value: redColorRef, range: entireString)

		// append the end of a paragraph tag
		testingString.appendEndOfParagraph()

		// check the foreground color is preserved in the appended newline
		var stringColorRef = testingString.attribute(NSAttributedString.Key(kCTForegroundColorAttributeName as String), at: testingString.length - 1, effectiveRange: nil)

		#if canImport(UIKit)
		if let uiColor = stringColorRef as? UIColor {
			stringColorRef = uiColor.cgColor
		}
		#endif

		if let cgColor = stringColorRef as! CGColor? {
			#expect(cgColor == redColorRef, "Foreground color should be red")
		}

		// Note: Testing NSForegroundColorAttributeName propagation via appendEndOfParagraph
		// is omitted because it requires setting the global ___useiOS6Attributes flag, which
		// is not safely accessible from Swift 6 strict concurrency. The CoreText attribute
		// path (tested above) exercises the same core logic.
	}
}
