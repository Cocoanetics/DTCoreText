import Testing
import Foundation
import CoreText
@testable import DTCoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@Suite("Layout Frame", .serialized)
struct LayoutFrameTests {
	@Test("Variable height layout")
	func variableHeight() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<b>Some bold text</b>")!

		let layouter = CoreTextLayouter(attributedString: attributedString)!

		let maxRect = CGRect(x: 10, y: 20, width: 1024, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
		let entireString = NSRange(location: 0, length: attributedString.length)
		let layoutFrame = layouter.layoutFrame(with: maxRect, range: entireString)!

		let sizeNeeded = layoutFrame.frame.size
		#expect(sizeNeeded.height == 16)
		#expect(sizeNeeded.width == 1024)
	}

	@Test("Variable height and width layout")
	func variableHeightAndWidth() {
		let attributedString = TestHelpers.attributedString(fromHTML: "<b>Some bold text</b>")!

		let layouter = CoreTextLayouter(attributedString: attributedString)!

		let maxRect = CGRect(x: 10, y: 20, width: CGFloat(CGFLOAT_WIDTH_UNKNOWN), height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
		let entireString = NSRange(location: 0, length: attributedString.length)
		let layoutFrame = layouter.layoutFrame(with: maxRect, range: entireString)!

		let sizeNeeded = layoutFrame.frame.size
		#expect(sizeNeeded.height == 16)
		#expect(sizeNeeded.width == 76)
	}

	/// Issue #1311: a plain `NSTextAttachment` (i.e. not the DTCoreText
	/// `TextAttachment` subclass) must be treated as a valid attachment by the
	/// reader-side pipeline: the CT run delegate should source ascent/descent/
	/// width from `bounds`/`image`, the glyph run's `.attachment` property
	/// should surface it, and `textAttachments()` should collect it.
	@Test("Plain NSTextAttachment is honored by layout and run delegates")
	func plainNSTextAttachmentLayout() throws {
		let imageSize = CGSize(width: 24, height: 18)

		#if canImport(UIKit)
		UIGraphicsBeginImageContextWithOptions(imageSize, true, 1.0)
		UIColor.red.setFill()
		UIRectFill(CGRect(origin: .zero, size: imageSize))
		let redImage = try #require(UIGraphicsGetImageFromCurrentImageContext())
		UIGraphicsEndImageContext()
		#else
		let redImage = NSImage(size: imageSize)
		redImage.lockFocus()
		NSColor.red.setFill()
		NSRect(origin: .zero, size: imageSize).fill()
		redImage.unlockFocus()
		#endif

		// Plain NSTextAttachment — no TextAttachment subclass, no DT metadata.
		let plainAttachment = NSTextAttachment()
		plainAttachment.image = redImage

		let runDelegate = try #require(
			createEmbeddedObjectRunDelegate(plainAttachment),
			"Run delegate creation should succeed for a plain NSTextAttachment"
		)

		// Sanity-check the helpers report the image-derived metrics.
		#expect(dtAttachmentLayoutSize(plainAttachment) == imageSize)
		#expect(dtAttachmentLayoutAscent(plainAttachment) == imageSize.height)
		#expect(dtAttachmentLayoutDescent(plainAttachment) == 0)

		let mutable = NSMutableAttributedString(string: "\u{FFFC}")
		let entireRange = NSRange(location: 0, length: mutable.length)
		mutable.addAttribute(.attachment, value: plainAttachment, range: entireRange)
		mutable.addAttribute(
			NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String),
			value: runDelegate,
			range: entireRange
		)

		let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
		mutable.addAttribute(
			NSAttributedString.Key(rawValue: kCTFontAttributeName as String),
			value: font,
			range: entireRange
		)

		// DTCoreTextLayoutFrame requires a paragraph style on every fragment.
		let paragraphStyle = NSParagraphStyle.default
		mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: entireRange)

		let layouter = try #require(CoreTextLayouter(attributedString: mutable))
		let maxRect = CGRect(x: 0, y: 0, width: 200, height: 200)
		let layoutFrame = try #require(
			layouter.layoutFrame(with: maxRect, range: entireRange),
			"Layout frame should build"
		)

		let line = try #require(
			(layoutFrame.lines as? [CoreTextLayoutLine])?.first,
			"Expected at least one layout line"
		)
		let run = try #require(
			(line.glyphRuns as? [CoreTextGlyphRun])?.first,
			"Expected at least one glyph run"
		)

		let attachment = try #require(run.attachment, "Run should carry the plain attachment")
		// Identity check also proves it's the plain attachment we built, not a
		// TextAttachment subclass.
		#expect(attachment === plainAttachment)
		#expect(type(of: attachment) == NSTextAttachment.self,
				"Sanity check: this test must exercise a plain NSTextAttachment, not the DT subclass")

		// The CT run delegate should have reported the image's width.
		#expect(abs(run.width - imageSize.width) < 0.5,
				"Plain NSTextAttachment run width should match image width via run delegate")

		// textAttachments() on the layout frame should surface it too.
		let allAttachments = layoutFrame.textAttachments()
		#expect(allAttachments.count == 1)
		#expect(allAttachments.first === plainAttachment)
	}
}
