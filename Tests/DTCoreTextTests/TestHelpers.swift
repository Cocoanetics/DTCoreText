import Foundation
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

/// Shared helper to build attributed strings from HTML, equivalent to DTCoreTextTestCase
enum TestHelpers {
	static func attributedString(fromHTML html: String, options: [String: Any]? = nil) -> NSAttributedString? {
		guard let data = html.data(using: .utf8) else { return nil }

		var mutableOptions = options ?? [:]
		let baseURL = Bundle.module.resourceURL ?? Bundle.module.bundleURL
		mutableOptions[NSBaseURLDocumentOption] = baseURL

		TextAttachment.registerClass(ObjectTextAttachment.self, forTagName: "oliver")

		let builder = HTMLAttributedStringBuilder(html: data, options: mutableOptions)
		return builder?.generatedAttributedString()
	}

	static func attributedString(fromTestFile name: String) -> NSAttributedString? {
		guard let path = Bundle.module.path(forResource: name, ofType: "html") else { return nil }
		guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }

		let builder = HTMLAttributedStringBuilder(html: data, options: nil)
		return builder?.generatedAttributedString()
	}
}
