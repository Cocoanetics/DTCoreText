import Testing
import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private func assertColorsEqual(_ color1: PlatformColor?, _ color2: PlatformColor?, sourceLocation: SourceLocation = #_sourceLocation) {
	guard let color1, let color2 else {
		Issue.record("One or both colors are nil", sourceLocation: sourceLocation)
		return
	}
	var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
	var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

	#if canImport(UIKit)
	color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
	color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
	#elseif canImport(AppKit)
	let c1 = color1.usingColorSpace(.deviceRGB)!
	let c2 = color2.usingColorSpace(.deviceRGB)!
	c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
	c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
	#endif

	#expect(abs(r1 - r2) < 0.01, "Red components differ", sourceLocation: sourceLocation)
	#expect(abs(g1 - g2) < 0.01, "Green components differ", sourceLocation: sourceLocation)
	#expect(abs(b1 - b2) < 0.01, "Blue components differ", sourceLocation: sourceLocation)
	#expect(abs(a1 - a2) < 0.01, "Alpha components differ", sourceLocation: sourceLocation)
}

@Suite("Color HTML")
struct ColorHTMLTests {
	@Test("Creates valid colors from hex strings", arguments: [
		("000000", 0.0, 0.0, 0.0),
		("FFFFFF", 1.0, 1.0, 1.0),
		("FF0000", 1.0, 0.0, 0.0),
		("00FF00", 0.0, 1.0, 0.0),
		("0000FF", 0.0, 0.0, 1.0),
	])
	func validColorWithHexString(hex: String, r: CGFloat, g: CGFloat, b: CGFloat) {
		let expected = PlatformColor(red: r, green: g, blue: b, alpha: 1.0)
		let htmlColor = DTColorCreateWithHexString(hex)
		#expect(htmlColor != nil)
		assertColorsEqual(htmlColor, expected)
	}

	@Test("Short hex string creates correct color")
	func shortHexString() {
		let expected = PlatformColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)
		let htmlColor = DTColorCreateWithHexString("F0F")
		#expect(htmlColor != nil)
		assertColorsEqual(htmlColor, expected)
	}

	@Test("Converts colors to hex strings")
	func colorHTMLHexString() {
		#expect(DTHexStringFromDTColor(PlatformColor.red) == "ff0000")
		#expect(DTHexStringFromDTColor(PlatformColor.green) == "00ff00")
		#expect(DTHexStringFromDTColor(PlatformColor.blue) == "0000ff")
		#expect(DTHexStringFromDTColor(PlatformColor.white) == "ffffff")
	}
}
