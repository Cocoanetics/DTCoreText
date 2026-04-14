import Testing
import Foundation
import CoreText
@testable import DTCoreText

@Suite("CSS Stylesheet", .serialized)
struct CSSStylesheetTests {

	private func stylesForSelector(_ selector: String, in stylesheet: CSSStylesheet) -> [String: Any]? {
		return stylesheet.styles()[selector] as? [String: Any]
	}

	@Test("Attribute with whitespace")
	func attributeWithWhitespace() {
		let css = "span { font-family: 'Trebuchet MS'; empty: ; empty2:; font-size: 16px; line-height: 20 px; font-style: italic }"
		let stylesheet = CSSStylesheet(styleBlock: css)

		let styles = stylesForSelector("span", in: stylesheet)!

		#expect(styles["font-family"] as? String == "Trebuchet MS")
		#expect(styles["font-size"] as? String == "16px")
		#expect(styles["line-height"] as? String == "20 px")
		#expect(styles["font-style"] as? String == "italic")
		#expect(styles["empty"] as? String == "")
		#expect(styles["empty2"] as? String == "")
	}

	@Test("Empty font family")
	func emptyFontFamily() {
		let css = "span { font-family: ''; empty: ; empty2:; font-size: 16px; line-height: 20 px; font-style: italic }"
		let stylesheet = CSSStylesheet(styleBlock: css)

		let styles = stylesForSelector("span", in: stylesheet)!

		#expect(styles[""] == nil)
		#expect(styles["font-size"] as? String == "16px")
		#expect(styles["line-height"] as? String == "20 px")
		#expect(styles["font-style"] as? String == "italic")
		#expect(styles["empty"] as? String == "")
		#expect(styles["empty2"] as? String == "")
	}

	@Test("!important is stripped")
	func important() {
		let css = "p {align: center !IMPORTANT;color:blue;}"
		let stylesheet = CSSStylesheet(styleBlock: css)

		let styles = stylesForSelector("p", in: stylesheet)!

		#expect(styles.count == 2)
		#expect(styles["align"] as? String == "center")
		#expect(styles["color"] as? String == "blue")
	}

	@Test("Merging stylesheets")
	func merging() {
		let stylesheet = CSSStylesheet.defaultStyleSheet().copy() as! CSSStylesheet
		let otherStyleSheet = CSSStylesheet(styleBlock: "p {margin-bottom:30px;font-size:40px;}")
		stylesheet.mergeStylesheet(otherStyleSheet)

		let element = HTMLElement.element(name: "p", attributes: nil, options: nil)
		element.fontDescriptor = CoreTextFontDescriptor()
		element.textScale = 1.0

		let (styles, _) = stylesheet.mergedStyles(for: element, ignoreInlineStyle: false)
		element.applyStyles(styles!)

		#expect(element.displayStyle == .block)
		#expect(Float(element.fontDescriptor.pointSize) == 40.0)
	}

	@Test("Merging with decompression")
	func mergingWithDecompression() {
		let stylesheet = CSSStylesheet(styleBlock: "p {font: italic small-caps bold 14.0px/100px \"Times New Roman\", serif;}")
		let otherStyleSheet = CSSStylesheet(styleBlock: "p {margin-bottom:30px;font-size:40px;}")
		stylesheet.mergeStylesheet(otherStyleSheet)

		let styles = stylesForSelector("p", in: stylesheet)!

		#expect(styles["font-size"] as? String == "40px")
		#expect(styles["font-family"] as? String == "\"Times New Roman\", serif")
		#expect(styles["font-style"] as? String == "italic")
		#expect(styles["font-variant"] as? String == "small-caps")
		#expect(styles["line-height"] as? String == "100px")
		#expect(styles["margin-bottom"] as? String == "30px")
	}

	@Test("Multiple font families do not crash")
	func multipleFontFamiliesCrash() {
		let stylesheet = CSSStylesheet(styleBlock: "p {font-family:Helvetica,sans-serif;}")
		let styles = stylesForSelector("p", in: stylesheet)
		let expected: [String] = ["Helvetica", "sans-serif"]
		#expect(styles?["font-family"] as? [String] == expected)
	}

	@Test("Multiple font families parsed correctly")
	func multipleFontFamilies() {
		let stylesheet = CSSStylesheet(styleBlock: "p {font-family:Helvetica,sans-serif !important;}")
		let styles = stylesForSelector("p", in: stylesheet)!
		let expected: [String] = ["Helvetica", "sans-serif"]
		#expect(styles["font-family"] as? [String] == expected)
	}

	@Test("Merge by ID selector")
	func mergeByID() {
		let stylesheet = CSSStylesheet(styleBlock: "#foo {color:red;} #bar {color:blue;} .foo {color:yellow;}")

		let attributes: [String: String] = ["id": "foo"]
		let element = HTMLElement.element(name: "dummy", attributes: attributes, options: nil)

		let (styles, matchedSelectors) = stylesheet.mergedStyles(for: element, ignoreInlineStyle: false)
		let unwrappedStyles = styles!

		#expect(unwrappedStyles.count == 1)
		#expect(matchedSelectors.count == 1)
		#expect(matchedSelectors.first == "#foo")

		#expect(unwrappedStyles["color"] as? String == "red")
	}

	@Test("Compressed background with rgb color")
	func compressedBackground() {
		let stylesheet = CSSStylesheet(styleBlock: "p {background: none 0px 0px repeat scroll rgb(250, 250, 250);}")
		let styles = stylesForSelector("p", in: stylesheet)!
		#expect(styles["background-color"] as? String == "rgb(250, 250, 250)")
	}

	@Test("Parse style block with unpaired brackets")
	func parseStyleBlock() {
		let testCases = [
			"s1{p1:1em}s2{p2:2em}",
			"s1{p1:1em}}s2{p2:2em}",
			"s1{p1:1em}}}}}s2{p2:2em}}}",
		]

		for cssStr in testCases {
			let stylesheet = CSSStylesheet.defaultStyleSheet()
			stylesheet.parseStyleBlock(cssStr)
			let s1Styles = stylesForSelector("s1", in: stylesheet)
			let s2Styles = stylesForSelector("s2", in: stylesheet)
			#expect(s1Styles?["p1"] as? String == "1em", "missing css style s1 when parsing: \(cssStr)")
			#expect(s2Styles?["p2"] as? String == "2em", "missing css style s2 when parsing: \(cssStr)")
		}
	}
}
