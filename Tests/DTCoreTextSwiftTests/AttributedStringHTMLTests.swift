import Testing
import Foundation
import CoreText
@testable import DTCoreTextSwift

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("NSAttributedString HTML", .serialized)
struct AttributedStringHTMLTests {

	// MARK: - Helpers

	private func attributedStringFromHTML(_ html: String) -> NSAttributedString? {
		guard let data = html.data(using: .utf8) else { return nil }
		let builder = HTMLAttributedStringBuilder(html: data, options: nil, documentAttributes: nil)
		return builder?.generatedAttributedString()
	}

	private func hexString(for data: Data) -> String {
		data.map { String(format: "%02x", $0) }.joined()
	}

	// MARK: - Tests

	@Test("Paragraphs")
	func paragraphs() throws {
		let html = "Prefix<p>One\ntwo\n<br>three</p><p>New Paragraph</p>Suffix"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "5072656669780a4f6e652074776f20e280a874687265650a4e6577205061726167726170680a537566666978"

		#expect(resultOnIOS == resultOnMac, "Output on Paragraph Test differs")
	}

	@Test("Header paragraphs")
	func headerParagraphs() throws {
		let html = "Prefix<h1>One</h1><h2>One</h2><h3>One</h3><h4>One</h4><h5>One</h5><p>New Paragraph</p>Suffix"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "5072656669780a4f6e650a4f6e650a4f6e650a4f6e650a4f6e650a4e6577205061726167726170680a537566666978"

		#expect(resultOnIOS == resultOnMac, "Output on Paragraph Test differs")
	}

	@Test("List paragraphs")
	func listParagraphs() throws {
		let html = "<p>Before</p><ul><li>One</li><li>Two</li></ul><p>After</p>"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "4265666f72650a09e280a2094f6e650a09e280a20954776f0a41667465720a"

		#expect(resultOnIOS == resultOnMac, "Output on List Test differs")
	}

	@Test("Image paragraphs")
	func imageParagraphs() throws {
		let html = "<p>Before</p><img src=\"Oliver.jpg\"><h1>Header</h2><p>after</p><p>Some inline <img width=\"20px\" height=\"20px\" src=\"Oliver.jpg\"> text.</p>"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "4265666f72650aefbfbc0a4865616465720a61667465720a536f6d6520696e6c696e6520efbfbc20746578742e0a"

		#expect(resultOnIOS == resultOnMac, "Output on Image Test differs")
	}

	@Test("Space normalization")
	func spaceNormalization() throws {
		let html = "<p>Now there is some <b>bold</b>\ntext and  spaces\n    should be normalized.</p>"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "4e6f7720746865726520697320736f6d6520626f6c64207465787420616e64207370616365732073686f756c64206265206e6f726d616c697a65642e0a"

		#expect(resultOnIOS == resultOnMac, "Output on Space Normalization Test differs")
	}

	@Test("Space and newlines")
	func spaceAndNewlines() throws {
		let html = "<a>bla</a>\nfollows\n<font color=\"blue\">NSString</font> <font color=\"purple\">*</font>str <font color=\"#000000\">=</font> @<font color=\"#E40000\">\"The Quick Brown Fox Brown\"</font>;"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "626c6120666f6c6c6f7773204e53537472696e67202a737472203d20402254686520517569636b2042726f776e20466f782042726f776e223b"

		#expect(resultOnIOS == resultOnMac, "Output on Space and Newlines Test differs")
	}

	@Test("Missing closing tag and spacing")
	func missingClosingTagAndSpacing() throws {
		let html = "<span>image \n <a href=\"http://sv.wikipedia.org/wiki/Fil:V%C3%A4dersoltavlan_cropped.JPG\"\n late</a> last</span>"
		let string = try #require(attributedStringFromHTML(html))

		let dump = string.string.data(using: .utf8)!
		let resultOnIOS = hexString(for: dump)
		let resultOnMac = "696d616765206c617374"

		#expect(resultOnIOS == resultOnMac, "Output on Invalid Tag Test differs")
	}

	@Test("Crash at empty node before div with iOS6 attributes")
	func crashAtEmptyNodeBeforeDivWithiOS6Attributes() throws {
		let html = "<div><i></i><div></div></div>;"
		let data = html.data(using: .utf8)!
		let options: [String: Any] = [DTUseiOS6Attributes: true]
		let string = NSAttributedString(htmlData: data, options: options, documentAttributes: nil)
		#expect(string != nil)
	}

	#if canImport(UIKit)
	@Test("Default font")
	func defaultFont() throws {
		let html = "<p>Hello World!</p>"
		let data = html.data(using: .utf8)!
		let options: [String: Any] = [:]
		let string = try #require(NSAttributedString(htmlData: data, options: options, documentAttributes: nil))

		let font = try #require(string.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
		let descriptor = font.fontDescriptor

		let isBold = descriptor.symbolicTraits.contains(.traitBold)
		#expect(!isBold)

		let isItalic = descriptor.symbolicTraits.contains(.traitItalic)
		#expect(!isItalic)

		#expect(font.familyName == "Times New Roman")
	}

	@Test("Default font bold")
	func defaultFontBold() throws {
		let html = "<b>Hello World!</b>"
		let data = html.data(using: .utf8)!
		let options: [String: Any] = [:]
		let string = try #require(NSAttributedString(htmlData: data, options: options, documentAttributes: nil))

		let font = try #require(string.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
		let descriptor = font.fontDescriptor

		let isBold = descriptor.symbolicTraits.contains(.traitBold)
		#expect(isBold)

		let isItalic = descriptor.symbolicTraits.contains(.traitItalic)
		#expect(!isItalic)

		#expect(font.familyName == "Times New Roman")
	}

	@Test("Default font italic")
	func defaultFontItalic() throws {
		let html = "<em>Hello World!</em>"
		let data = html.data(using: .utf8)!
		let options: [String: Any] = [:]
		let string = try #require(NSAttributedString(htmlData: data, options: options, documentAttributes: nil))

		let font = try #require(string.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
		let descriptor = font.fontDescriptor

		let isBold = descriptor.symbolicTraits.contains(.traitBold)
		#expect(!isBold)

		let isItalic = descriptor.symbolicTraits.contains(.traitItalic)
		#expect(isItalic)

		#expect(font.familyName == "Times New Roman")
	}
	#endif
}
