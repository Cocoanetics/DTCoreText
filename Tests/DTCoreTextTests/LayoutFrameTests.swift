import Testing
import Foundation
@testable import DTCoreTextSwift

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
}
