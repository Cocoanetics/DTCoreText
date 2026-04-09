import Testing
import Foundation
@testable import DTCoreTextSwift

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("String CSS", .serialized)
struct StringCSSTests {
	private func parseShadow(_ css: String) -> [[String: Any]]? {
		let string = css as NSString
		let color = PlatformColor.black
		return string.arrayOfCSSShadows(withCurrentTextSize: 10.0, currentColor: color) as? [[String: Any]]
	}

	@Test("Shadow with color first")
	func shadowColorFirst() {
		let shadows = parseShadow("red 1px 2px 3px;")!
		#expect(shadows.count == 1)

		let oneShadow = shadows.last!
		#expect(oneShadow.count == 3)

		let blur = (oneShadow["Blur"] as! NSNumber).floatValue
		#expect(blur == 3.0)

		let offset = {
			#if canImport(UIKit)
			return (oneShadow["Offset"] as! NSValue).cgSizeValue
			#else
			return (oneShadow["Offset"] as! NSValue).sizeValue
			#endif
		}()
		#expect(offset == CGSize(width: 1, height: 2))

		let shadowColor = oneShadow["Color"] as! PlatformColor
		let redColor = PlatformColor.red
		#if canImport(UIKit)
		#expect(shadowColor == redColor)
		#else
		#expect(shadowColor.usingColorSpace(.deviceRGB)!.redComponent == redColor.redComponent)
		#expect(shadowColor.usingColorSpace(.deviceRGB)!.greenComponent == redColor.greenComponent)
		#expect(shadowColor.usingColorSpace(.deviceRGB)!.blueComponent == redColor.blueComponent)
		#endif
	}

	@Test("Shadow with color last")
	func shadowColorLast() {
		let shadows = parseShadow("1px 2px 3px red;")!
		#expect(shadows.count == 1)

		let oneShadow = shadows.last!
		#expect(oneShadow.count == 3)

		let blur = (oneShadow["Blur"] as! NSNumber).floatValue
		#expect(blur == 3.0)

		let offset = {
			#if canImport(UIKit)
			return (oneShadow["Offset"] as! NSValue).cgSizeValue
			#else
			return (oneShadow["Offset"] as! NSValue).sizeValue
			#endif
		}()
		#expect(offset == CGSize(width: 1, height: 2))

		let shadowColor = oneShadow["Color"] as! PlatformColor
		let redColor = PlatformColor.red
		#if canImport(UIKit)
		#expect(shadowColor == redColor)
		#else
		#expect(shadowColor.usingColorSpace(.deviceRGB)!.redComponent == redColor.redComponent)
		#expect(shadowColor.usingColorSpace(.deviceRGB)!.greenComponent == redColor.greenComponent)
		#expect(shadowColor.usingColorSpace(.deviceRGB)!.blueComponent == redColor.blueComponent)
		#endif
	}

	@Test("Invalid shadow returns nil")
	func shadowInvalid() {
		let shadows = parseShadow("bla")
		#expect(shadows == nil)
	}

	@Test("Shadow 'none' returns nil")
	func shadowNone() {
		let shadows = parseShadow("none")
		#expect(shadows == nil)
	}

	@Test("OneNote style parsing")
	func oneNoteStyle() {
		let style = "background-image:none;background-attachment:scroll;background-color:transparent;background-position-x:0%;background-position-y:0%;background-repeat:repeat;border-bottom-color:#000000;border-bottom-style:none;border-bottom-width:medium;border-left-color:#000000;border-left-style:none;border-left-width:medium;border-right-color:#000000;border-right-style:none;border-right-width:medium;border-top-color:#000000;border-top-style:none;border-top-width:medium;border-width:medium;clear:none;color:#000000;display:inline;font-family:Times New Roman;font-size:7pt;font-style:normal;font-variant:normal;letter-spacing:normal;line-height:normal;list-style-image:none;list-style-position:outside;list-style-type:disc;overflow:visible;padding:0px;padding-bottom:0px;padding-left:0px;padding-right:0px;padding-top:0px;position:static;float:none;text-align:left;text-decoration:none;text-indent:-0.25in;text-transform:none;visibility:inherit; FONT: 7pt &amp;quot;Times New Roman&amp;quot;" as NSString
		let styles = style.dictionaryOfCSSStyles()

		let fontFamily = styles["font-family"] as? String
		#expect(fontFamily == "Times New Roman")

		let fontAttribute = styles["font"]
		#expect(fontAttribute == nil)
	}

	@Test("Invalid font size detection")
	func invalidFontSize() {
		#expect(!("normal" as NSString).isCSSLengthValue())
		#expect(("10px" as NSString).isCSSLengthValue())
	}

	@Test("Multiple font families")
	func multiFontFamily() {
		let style = "font-family: 'Courier New', Courier, 'Lucida Sans Typewriter', 'Lucida Typewriter', Times New Roman, monospace" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let font = dictionary["font-family"]!

		#expect(font is NSArray)
		#expect((font as! NSArray).count == 6)
	}

	@Test("Simple quoted font family")
	func simpleQuotedFontFamily() {
		let style = "font-family: 'Courier New'" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let font = dictionary["font-family"] as? String

		#expect(font == "Courier New")
	}

	@Test("Simple unquoted font family")
	func simpleUnquotedFontFamily() {
		let style = "font-family: Courier New" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let font = dictionary["font-family"] as? String

		#expect(font == "Courier New")
	}

	@Test("Multiple font families with size")
	func multiFontFamilyWithSize() {
		let style = "font-family: 'Courier New', Courier, 'Lucida Sans Typewriter', 'Lucida Typewriter', Times New Roman, monospace; font-size: 60px;" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let font = dictionary["font-family"]!
		let size = dictionary["font-size"] as? String

		#expect(font is NSArray)
		#expect((font as! NSArray).count == 6)
		#expect(size == "60px")
	}

	@Test("Text shadow CSS parsing")
	func textShadow() {
		let style = "font-family:Helvetica;font-weight:bold;font-size:30px; color:#FFF; text-shadow: -1px -1px #555, 1px 1px #EEE" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let shadow = dictionary["text-shadow"]

		#expect(shadow as? String == "-1px -1px #555, 1px 1px #EEE")
		#expect(shadow is String)
	}

	@Test("Color CSS parsing")
	func color() {
		let style = "font-family:Helvetica;font-weight:bold;color:rgb(255, 0, 0);font-size:30px;" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let color = dictionary["color"]

		#expect(color as? String == "rgb(255, 0, 0)")
		#expect(color is String)
	}

	@Test("Background color CSS parsing")
	func backgroundColor() {
		let style = "font-family:Helvetica;font-weight:bold;background-color:rgb(255, 88, 44);font-size:30px;" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let color = dictionary["background-color"]

		#expect(color as? String == "rgb(255, 88, 44)")
		#expect(color is String)
	}

	@Test("Background RGB CSS parsing")
	func backgroundRGB() {
		let style = "font-family:Helvetica;font-weight:bold;background:rgb(255, 88, 44);font-size:30px;" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let color = dictionary["background"]

		#expect(color as? String == "rgb(255, 88, 44)")
		#expect(color is String)
	}

	// Note: DTEdgeInsetsRelativeToCurrentTextSize: returns DTEdgeInsets (a C macro for
	// UIEdgeInsets/NSEdgeInsets) which is not importable in Swift. Testing edge insets
	// parsing through HTMLElement.margins instead, which exercises the same code path.
	@Test("Edge insets via margin style dictionary")
	func edgeInsetsViaMargin() {
		func makeElement() -> HTMLElement {
			let element = HTMLElement(name: "", attributes: nil)
			element.textScale = 1
			element.paragraphStyle = CoreTextParagraphStyle.defaultParagraphStyle()
			let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
			element.fontDescriptor = CoreTextFontDescriptor(ctFont: font)
			return element
		}

		// 4 values: top right bottom left
		let e4 = makeElement()
		e4.applyStyleDictionary(["margin": "10px 20px 30px 40px"] as NSDictionary)
		#expect(e4.margins.top == 10)
		#expect(e4.margins.left == 40)
		#expect(e4.margins.bottom == 30)
		#expect(e4.margins.right == 20)

		// 3 values: top left-right bottom
		let e3 = makeElement()
		e3.applyStyleDictionary(["margin": "10px 20px 30px"] as NSDictionary)
		#expect(e3.margins.top == 10)
		#expect(e3.margins.left == 20)
		#expect(e3.margins.bottom == 30)
		#expect(e3.margins.right == 20)

		// 2 values: top-bottom left-right
		let e2 = makeElement()
		e2.applyStyleDictionary(["margin": "10px 20px"] as NSDictionary)
		#expect(e2.margins.top == 10)
		#expect(e2.margins.left == 20)
		#expect(e2.margins.bottom == 10)
		#expect(e2.margins.right == 20)

		// 1 value: all sides
		let e1 = makeElement()
		e1.applyStyleDictionary(["margin": "10px"] as NSDictionary)
		#expect(e1.margins.top == 10)
		#expect(e1.margins.left == 10)
		#expect(e1.margins.bottom == 10)
		#expect(e1.margins.right == 10)
	}

	@Test("RGB in background should not cause array return")
	func styleWithRGB() {
		let style = "background:foo bar rgb(255, 255, 255)" as NSString
		let dictionary = style.dictionaryOfCSSStyles()
		let result = dictionary["background"]

		#expect(result is String)
	}
}
