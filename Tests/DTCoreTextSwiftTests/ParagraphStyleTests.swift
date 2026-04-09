import Testing
import Foundation
import CoreText
@testable import DTCoreText

@Suite("Paragraph Style")
struct ParagraphStyleTests {
	@Test("Loss of tab stops after round-trip through CTParagraphStyle")
	func lossOfTabStops() {
		let paragraphStyle = DTCoreTextParagraphStyle()
		paragraphStyle.addTabStop(atPosition: 10, alignment: CTTextAlignment.left)

		let ctParagraphStyle = paragraphStyle.createCTParagraphStyle().takeRetainedValue()

		let newParagraphStyle = DTCoreTextParagraphStyle(ctParagraphStyle: ctParagraphStyle)!

		#expect(newParagraphStyle.tabStops != nil, "There are no tab stops in newly created paragraph style")
	}

	@Test("Tab stops round-trip through NSParagraphStyle")
	func tabsOnNSParagraphStyle() {
		let paragraphStyle = DTCoreTextParagraphStyle()
		paragraphStyle.addTabStop(atPosition: 10, alignment: CTTextAlignment.left)
		paragraphStyle.addTabStop(atPosition: 15, alignment: CTTextAlignment.right)
		paragraphStyle.addTabStop(atPosition: 20, alignment: CTTextAlignment.center)
		paragraphStyle.addTabStop(atPosition: 25, alignment: CTTextAlignment.justified)
		paragraphStyle.addTabStop(atPosition: 30, alignment: CTTextAlignment.natural)

		let nsParagraphStyle = paragraphStyle.nsParagraphStyle()!

		let tabStops = nsParagraphStyle.value(forKey: "tabStops") as! [Any]
		#expect(tabStops.count == 5, "There should be 5 tab stops")

		let newParagraphStyle = DTCoreTextParagraphStyle(nsParagraphStyle: nsParagraphStyle)!

		let tabCount = newParagraphStyle.tabStops!.count
		#expect(tabCount == 5, "There should be 5 tab stops")

		if tabCount == 5 {
			let tab1 = newParagraphStyle.tabStops![0] as! CTTextTab
			#expect(CTTextTabGetAlignment(tab1) == .left)
			#expect(CTTextTabGetLocation(tab1) == 10)

			let tab2 = newParagraphStyle.tabStops![1] as! CTTextTab
			#expect(CTTextTabGetAlignment(tab2) == .right)
			#expect(CTTextTabGetLocation(tab2) == 15)

			let tab3 = newParagraphStyle.tabStops![2] as! CTTextTab
			#expect(CTTextTabGetAlignment(tab3) == .center)
			#expect(CTTextTabGetLocation(tab3) == 20)

			let tab4 = newParagraphStyle.tabStops![3] as! CTTextTab
			#expect(CTTextTabGetAlignment(tab4) == .justified)
			#expect(CTTextTabGetLocation(tab4) == 25)

			let tab5 = newParagraphStyle.tabStops![4] as! CTTextTab
			#expect(CTTextTabGetAlignment(tab5) == .natural)
			#expect(CTTextTabGetLocation(tab5) == 30)
		}
	}

	@Test("Line height multiple passes through to NSParagraphStyle")
	func passLineHeightMultipleToNSParagraphStyle() {
		let paragraphStyle = DTCoreTextParagraphStyle()
		paragraphStyle.lineHeightMultiple = 3.1834

		let nsParagraphStyle = paragraphStyle.nsParagraphStyle()!

		#expect(nsParagraphStyle.lineHeightMultiple == CGFloat(paragraphStyle.lineHeightMultiple))
	}
}
