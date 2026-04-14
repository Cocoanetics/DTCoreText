import Testing
import Foundation
@testable import DTCoreTextSwift

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("Shadow Attributes", .serialized)
struct ShadowAttributeTests {

	// MARK: - Single Shadow

	@Test("Single text-shadow produces NSShadow but no DTShadowsAttribute")
	func singleShadowNative() {
		let html = "<span style=\"text-shadow: 1px 2px 3px red;\">text</span>"
		let attributedString = TestHelpers.attributedString(fromHTML: html)!

		let shadow = attributedString.attribute(.shadow, at: 0, effectiveRange: nil) as? NSShadow
		#expect(shadow != nil)

		#if canImport(UIKit)
		#expect(shadow?.shadowOffset == CGSize(width: 1, height: 2))
		#else
		#expect(shadow?.shadowOffset == NSSize(width: 1, height: 2))
		#endif
		#expect(shadow?.shadowBlurRadius == 3.0)

		let dtShadows = attributedString.attribute(
			NSAttributedString.Key(rawValue: DTShadowsAttribute), at: 0, effectiveRange: nil)
		#expect(dtShadows == nil)
	}

	// MARK: - Multiple Shadows

	@Test("Multiple text-shadows produce DTShadowsAttribute without native .shadow")
	func multipleShadows() {
		let html = "<span style=\"text-shadow: -1px -1px #555, 1px 1px #EEE;\">text</span>"
		let attributedString = TestHelpers.attributedString(fromHTML: html)!

		// Native .shadow should NOT be set for multiple shadows (avoids
		// CTRunDraw drawing its own shadow that conflicts with multi-shadow rendering)
		let shadow = attributedString.attribute(.shadow, at: 0, effectiveRange: nil)
		#expect(shadow == nil)

		// DTShadowsAttribute should contain all shadows as NSShadow objects
		let dtShadows = attributedString.attribute(
			NSAttributedString.Key(rawValue: DTShadowsAttribute), at: 0, effectiveRange: nil)
			as? [NSShadow]
		#expect(dtShadows != nil)
		#expect(dtShadows?.count == 2)

		// First shadow
		let first = dtShadows?[0]
		#expect(first != nil)
		#if canImport(UIKit)
		#expect(first?.shadowOffset == CGSize(width: -1, height: -1))
		#else
		#expect(first?.shadowOffset == NSSize(width: -1, height: -1))
		#endif

		// Second shadow
		let second = dtShadows?[1]
		#expect(second != nil)
		#if canImport(UIKit)
		#expect(second?.shadowOffset == CGSize(width: 1, height: 1))
		#else
		#expect(second?.shadowOffset == NSSize(width: 1, height: 1))
		#endif
	}

	@Test("Three text-shadows all present in DTShadowsAttribute")
	func threeShadows() {
		let html = "<span style=\"text-shadow: 0.2em 0.5em 0.1em #600, -0.3em 0.1em 0.1em #060, 0.4em -0.3em 0.1em #006;\">text</span>"
		let attributedString = TestHelpers.attributedString(fromHTML: html)!

		let dtShadows = attributedString.attribute(
			NSAttributedString.Key(rawValue: DTShadowsAttribute), at: 0, effectiveRange: nil)
			as? [NSShadow]
		#expect(dtShadows?.count == 3)

		// Each shadow should have a non-zero blur radius
		for shadow in dtShadows ?? [] {
			#expect(shadow.shadowBlurRadius > 0)
		}
	}

	// MARK: - Native NSShadow without DTShadowsAttribute

	@Test("Native NSShadow attribute is recognized without DTShadowsAttribute")
	func nativeNSShadowOnly() {
		let shadow = NSShadow()
		shadow.shadowOffset = CGSize(width: 2, height: 3)
		shadow.shadowBlurRadius = 4.0
		shadow.shadowColor = PlatformColor.red

		let attrString = NSAttributedString(
			string: "test",
			attributes: [.shadow: shadow])

		// Verify the shadow attribute survives round-trip
		let retrieved = attrString.attribute(.shadow, at: 0, effectiveRange: nil) as? NSShadow
		#expect(retrieved != nil)
		#expect(retrieved?.shadowBlurRadius == 4.0)
		#if canImport(UIKit)
		#expect(retrieved?.shadowOffset == CGSize(width: 2, height: 3))
		#else
		#expect(retrieved?.shadowOffset == NSSize(width: 2, height: 3))
		#endif
	}

	// MARK: - No Shadow

	@Test("text-shadow: none produces no shadow attributes")
	func noShadow() {
		let html = "<span style=\"text-shadow: none;\">text</span>"
		let attributedString = TestHelpers.attributedString(fromHTML: html)!

		let shadow = attributedString.attribute(.shadow, at: 0, effectiveRange: nil)
		#expect(shadow == nil)

		let dtShadows = attributedString.attribute(
			NSAttributedString.Key(rawValue: DTShadowsAttribute), at: 0, effectiveRange: nil)
		#expect(dtShadows == nil)
	}
}
