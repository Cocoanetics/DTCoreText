import Testing
import Foundation
@testable import DTCoreText

@Suite("CSS List Style", .serialized)
struct CSSListStyleTests {
	@Test("NSCoding round-trip preserves equality")
	func nsCodingEqual() throws {
		let styles: [String: String] = ["list-style-type": "none", "list-style-position": "inherit"]
		let listStyle = DTCSSListStyle(styles: styles)!

		let data = try NSKeyedArchiver.archivedData(withRootObject: listStyle, requiringSecureCoding: false)
		let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
		unarchiver.requiresSecureCoding = false
		let unarchived = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! DTCSSListStyle

		#expect(listStyle.isEqual(to: unarchived))
	}

	@Test("NSCoding round-trip preserves inequality")
	func nsCodingNotEqual() throws {
		let styles1: [String: String] = ["list-style-type": "none", "list-style-position": "inherit"]
		let listStyle1 = DTCSSListStyle(styles: styles1)!

		let styles2: [String: String] = ["list-style-type": "circle", "list-style-position": "inherit"]
		let listStyle2 = DTCSSListStyle(styles: styles2)!

		#expect(!listStyle1.isEqual(to: listStyle2))

		let data = try NSKeyedArchiver.archivedData(withRootObject: listStyle1, requiringSecureCoding: false)
		let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
		unarchiver.requiresSecureCoding = false
		let unarchived = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! DTCSSListStyle

		#expect(!unarchived.isEqual(to: listStyle2))
	}
}
