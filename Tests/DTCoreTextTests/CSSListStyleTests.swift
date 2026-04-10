import Testing
import Foundation
@testable import DTCoreTextSwift

@Suite("CSS List Style", .serialized)
struct CSSListStyleTests {
	@Test("NSCoding round-trip preserves equality")
	func nsCodingEqual() throws {
		let styles: [String: String] = ["list-style-type": "none", "list-style-position": "inherit"]
		let listStyle = CSSListStyle(styles: styles)

		let data = try NSKeyedArchiver.archivedData(withRootObject: listStyle, requiringSecureCoding: false)
		let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
		unarchiver.requiresSecureCoding = false
		let unarchived = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! CSSListStyle

		#expect(listStyle.isEqualToListStyle(unarchived))
	}

	@Test("NSCoding round-trip preserves inequality")
	func nsCodingNotEqual() throws {
		let styles1: [String: String] = ["list-style-type": "none", "list-style-position": "inherit"]
		let listStyle1 = CSSListStyle(styles: styles1)

		let styles2: [String: String] = ["list-style-type": "circle", "list-style-position": "inherit"]
		let listStyle2 = CSSListStyle(styles: styles2)

		#expect(!listStyle1.isEqualToListStyle(listStyle2))

		let data = try NSKeyedArchiver.archivedData(withRootObject: listStyle1, requiringSecureCoding: false)
		let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
		unarchiver.requiresSecureCoding = false
		let unarchived = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! CSSListStyle

		#expect(!unarchived.isEqualToListStyle(listStyle2))
	}
}
