import Testing
import Foundation
import CoreText
@testable import DTCoreTextSwift

@Suite("CSS Stylesheet - Selector Weights", .serialized)
struct CSSStylesheetWeightTests {
	private func weight(forSelector selector: String?, in stylesheet: CSSStylesheet) -> Int {
		guard let selector, !selector.isEmpty else { return 0 }
		return stylesheet.weightForSelector(selector)
	}

	@Test("Invalid selector has no weight")
	func invalidSelectorHasNoWeight() {
		let stylesheet = CSSStylesheet(styleBlock: "")
		#expect(weight(forSelector: "", in: stylesheet) == 0)
		#expect(weight(forSelector: nil, in: stylesheet) == 0)
	}

	@Test("Classes weigh ten")
	func classesWeighTen() {
		let stylesheet = CSSStylesheet(styleBlock: "")
		#expect(weight(forSelector: ".foo", in: stylesheet) == 10)
		#expect(weight(forSelector: ".foo .bar", in: stylesheet) == 20)
	}

	@Test("IDs weigh one hundred")
	func idsWeightOneHundred() {
		let stylesheet = CSSStylesheet(styleBlock: "")
		#expect(weight(forSelector: "#foo", in: stylesheet) == 100)
		#expect(weight(forSelector: "#foo #bar", in: stylesheet) == 200)
	}

	@Test("Element names weigh one")
	func elementNamesWeightOne() {
		let stylesheet = CSSStylesheet(styleBlock: "")
		#expect(weight(forSelector: "div", in: stylesheet) == 1)
		#expect(weight(forSelector: "span div", in: stylesheet) == 2)
	}

	@Test("Weights are summed")
	func weightsAreSummed() {
		let stylesheet = CSSStylesheet(styleBlock: "")
		#expect(weight(forSelector: ".foo #div bar", in: stylesheet) == 111)
	}

	@Test("Spaces do not affect weight")
	func spacesDoNotAffectWeight() {
		let stylesheet = CSSStylesheet(styleBlock: "")
		#expect(weight(forSelector: " .foo  #div    bar  ", in: stylesheet) == 111)
	}
}

@Suite("CSS Stylesheet - Shorthand Decompression", .serialized)
struct CSSStylesheetShorthandTests {
	private func uncompress(_ styles: [String: String]) -> [String: Any] {
		let stylesheet = CSSStylesheet.defaultStyleSheet()
		let mutable = NSMutableDictionary(dictionary: styles)
		stylesheet.uncompressShorthands(mutable)
		return mutable as! [String: Any]
	}

	@Test("Font shorthand decompression")
	func uncompressFontShorthand() {
		let result = uncompress(["font": "italic bold 12px/30px Georgia caption"])
		#expect(result.count == 6)
		#expect(result["font-family"] as? String == "Georgia")
		#expect(result["font-style"] as? String == "italic")
		#expect(result["font-variant"] as? String == "normal")
		#expect(result["font-weight"] as? String == "bold")
		#expect(result["font-size"] as? String == "12px")
		#expect(result["line-height"] as? String == "30px")
	}

	@Test("Font shorthand with word size")
	func uncompressFontShorthandWordSize() {
		let result = uncompress(["font": "xx-small Georgia icon"])
		#expect(result.count == 6)
		#expect(result["font-family"] as? String == "Georgia")
		#expect(result["font-variant"] as? String == "normal")
		#expect(result["font-weight"] as? String == "normal")
		#expect(result["font-size"] as? String == "xx-small")
		#expect(result["line-height"] as? String == "normal")
	}

	@Test("Font shorthand with length first")
	func uncompressFontShorthandLengthFirst() {
		let result = uncompress(["font": "1.0em Georgia menu"])
		#expect(result.count == 6)
		#expect(result["font-family"] as? String == "Georgia")
		#expect(result["font-variant"] as? String == "normal")
		#expect(result["font-weight"] as? String == "normal")
		#expect(result["font-size"] as? String == "1.0em")
		#expect(result["line-height"] as? String == "normal")
	}

	@Test("List shorthand decompression")
	func uncompressListShorthand() {
		let result = uncompress(["list-style": "inherit", "list-style-image": "url('sqpurple.gif')"])
		#expect(result["list-style-position"] as? String == "inherit")
		#expect(result["list-style-type"] as? String == "inherit")
	}

	@Test("List image shorthand decompression")
	func uncompressListImageShorthand() {
		let result = uncompress(["list-style": "image url('sqpurple.gif')"])
		#expect(result["list-style-image"] as? String == "url('sqpurple.gif')")
		#expect(result["list-style-type"] as? String == "image")
	}

	@Test("Margin shorthand - 1 value")
	func uncompressMarginShorthandOne() {
		let result = uncompress(["margin": "10px"])
		#expect(result["margin-top"] as? String == "10px")
		#expect(result["margin-bottom"] as? String == "10px")
		#expect(result["margin-left"] as? String == "10px")
		#expect(result["margin-right"] as? String == "10px")
	}

	@Test("Margin shorthand - 2 values")
	func uncompressMarginShorthandTwo() {
		let result = uncompress(["margin": "10px 20px"])
		#expect(result["margin-top"] as? String == "10px")
		#expect(result["margin-bottom"] as? String == "10px")
		#expect(result["margin-left"] as? String == "20px")
		#expect(result["margin-right"] as? String == "20px")
	}

	@Test("Margin shorthand - 3 values")
	func uncompressMarginShorthandThree() {
		let result = uncompress(["margin": "10px 20px 30px"])
		#expect(result["margin-top"] as? String == "10px")
		#expect(result["margin-bottom"] as? String == "30px")
		#expect(result["margin-left"] as? String == "20px")
		#expect(result["margin-right"] as? String == "20px")
	}

	@Test("Margin shorthand - 4 values")
	func uncompressMarginShorthandFour() {
		let result = uncompress(["margin": "10px 20px 30px 40px"])
		#expect(result["margin-top"] as? String == "10px")
		#expect(result["margin-bottom"] as? String == "30px")
		#expect(result["margin-left"] as? String == "40px")
		#expect(result["margin-right"] as? String == "20px")
	}

	@Test("Padding shorthand - 1 value")
	func uncompressPaddingShorthandOne() {
		let result = uncompress(["padding": "10px"])
		#expect(result["padding-top"] as? String == "10px")
		#expect(result["padding-bottom"] as? String == "10px")
		#expect(result["padding-left"] as? String == "10px")
		#expect(result["padding-right"] as? String == "10px")
	}

	@Test("Padding shorthand - 2 values")
	func uncompressPaddingShorthandTwo() {
		let result = uncompress(["padding": "10px 20px"])
		#expect(result["padding-top"] as? String == "10px")
		#expect(result["padding-bottom"] as? String == "10px")
		#expect(result["padding-left"] as? String == "20px")
		#expect(result["padding-right"] as? String == "20px")
	}

	@Test("Padding shorthand - 3 values")
	func uncompressPaddingShorthandThree() {
		let result = uncompress(["padding": "10px 20px 30px"])
		#expect(result["padding-top"] as? String == "10px")
		#expect(result["padding-bottom"] as? String == "30px")
		#expect(result["padding-left"] as? String == "20px")
		#expect(result["padding-right"] as? String == "20px")
	}

	@Test("Padding shorthand - 4 values")
	func uncompressPaddingShorthandFour() {
		let result = uncompress(["padding": "10px 20px 30px 40px"])
		#expect(result["padding-top"] as? String == "10px")
		#expect(result["padding-bottom"] as? String == "30px")
		#expect(result["padding-left"] as? String == "40px")
		#expect(result["padding-right"] as? String == "20px")
	}

	@Test("Background shorthand decompression")
	func uncompressBackgroundShorthand() {
		let result = uncompress(["background": "url(\"topbanner.png\") #00D repeat-y fixed"])
		#expect(result["background-color"] as? String == "#00D")
	}
}
