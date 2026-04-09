import Testing
import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
private func makeEdgeInsets(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> UIEdgeInsets {
	UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
}
#elseif canImport(AppKit)
import AppKit
private func makeEdgeInsets(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) -> NSEdgeInsets {
	NSEdgeInsets(top: top, left: left, bottom: bottom, right: right)
}
#endif

@Suite("Text Block", .serialized)
struct TextBlockTests {
	@Test("Equal blocks compare as equal")
	func equals() {
		let block1 = TextBlock()
		block1.padding = makeEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
		block1.backgroundColor = DTColorCreateWithHTMLName("red")

		let block2 = TextBlock()
		block2.padding = makeEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
		block2.backgroundColor = DTColorCreateWithHTMLName("red")

		#expect(block1 == block2)
		#expect(block1 == block1)

		// different color
		block2.backgroundColor = DTColorCreateWithHTMLName("blue")
		#expect(block1 != block2)

		#expect(block1 != nil)
		#expect(block1 != ("bla" as NSString))

		// exactly same color
		block2.backgroundColor = block1.backgroundColor
		#expect(block1 == block2)

		// same color different padding
		block2.padding = makeEdgeInsets(top: 10, left: 20, bottom: 30, right: 50)
		block2.backgroundColor = DTColorCreateWithHTMLName("red")
		#expect(block1 != block2)
	}

	@Test("Hash is consistent")
	func hashValue() {
		let block = TextBlock()
		block.padding = makeEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)

		#expect(block.hash == 201010757)
	}

	@Test("NSCoding round-trip preserves equality")
	func nsCodingEqual() throws {
		let block = TextBlock()
		block.padding = makeEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
		block.backgroundColor = DTColorCreateWithHTMLName("red")

		let data = try NSKeyedArchiver.archivedData(withRootObject: block, requiringSecureCoding: false)
		let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
		unarchiver.requiresSecureCoding = false
		let unarchived = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! TextBlock

		#expect(block == unarchived)
	}

	@Test("NSCoding round-trip preserves inequality")
	func nsCodingNotEqual() throws {
		let block1 = TextBlock()
		block1.padding = makeEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
		block1.backgroundColor = DTColorCreateWithHTMLName("red")

		let block2 = TextBlock()
		block2.padding = makeEdgeInsets(top: 20, left: 30, bottom: 40, right: 50)
		block2.backgroundColor = DTColorCreateWithHTMLName("blue")

		#expect(block1 != block2)

		let data = try NSKeyedArchiver.archivedData(withRootObject: block1, requiringSecureCoding: false)
		let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
		unarchiver.requiresSecureCoding = false
		let unarchived = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! TextBlock

		#expect(unarchived != block2)
	}
}
