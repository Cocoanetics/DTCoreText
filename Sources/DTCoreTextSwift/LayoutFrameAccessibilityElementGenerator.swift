//
//  LayoutFrameAccessibilityElementGenerator.swift
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit
import DTCoreText

/// Block that provides an accessibility object for a text attachment.
public typealias AttachmentViewProvider = (DTTextAttachment) -> Any?

/// Generates accessibility elements for a DTCoreTextLayoutFrame.
@objc(DTCoreTextLayoutFrameAccessibilityElementGenerator)
public class LayoutFrameAccessibilityElementGenerator: NSObject {

	@objc
	public func accessibilityElements(for frame: DTCoreTextLayoutFrame, view: UIView, attachmentViewProvider block: @escaping AttachmentViewProvider) -> [Any] {
		var elements = [Any]()

		guard let paragraphRanges = frame.paragraphRanges as? [NSValue] else { return elements }

		for idx in 0..<paragraphRanges.count {
			let paragraphElements = accessibilityElements(inParagraphAt: idx, layoutFrame: frame, view: view, attachmentViewProvider: block)
			elements.append(contentsOf: paragraphElements)
		}

		return elements
	}

	private func accessibilityElements(inParagraphAt index: Int, layoutFrame frame: DTCoreTextLayoutFrame, view: UIView, attachmentViewProvider block: @escaping AttachmentViewProvider) -> [Any] {
		var elements = [Any]()

		enumerateAccessibleGroups(in: frame, forParagraphAt: index) { attrs, substringRange, _, runs in
			if let element = self.accessibilityElement(for: frame.attributedStringFragment, at: substringRange, attributes: attrs, runs: runs, view: view, attachmentViewProvider: block) {
				elements.append(element)
			}
		}

		return elements
	}

	private func enumerateAccessibleGroups(in frame: DTCoreTextLayoutFrame, forParagraphAt index: Int, using block: (NSDictionary, NSRange, UnsafeMutablePointer<ObjCBool>, [DTCoreTextGlyphRun]) -> Void) {
		guard let paragraphRanges = frame.paragraphRanges as? [NSValue], index < paragraphRanges.count else { return }

		let paragraphRange = paragraphRanges[index].rangeValue
		guard let lines = frame.linesInParagraph(at: UInt(index)) as? [DTCoreTextLayoutLine] else { return }

		frame.attributedStringFragment.enumerateAttributes(in: paragraphRange, options: []) { attrs, range, stop in
			var runs = [DTCoreTextGlyphRun]()
			for line in lines {
				if let lineRuns = line.glyphRuns(with: range) as? [DTCoreTextGlyphRun] {
					runs.append(contentsOf: lineRuns)
				}
			}
			block(attrs as NSDictionary, range, stop, runs)
		}
	}

	private func accessibilityElement(for attributedString: NSAttributedString, at range: NSRange, attributes: NSDictionary, runs: [DTCoreTextGlyphRun], view: UIView, attachmentViewProvider block: AttachmentViewProvider) -> Any? {
		if let attachment = attributes[NSAttributedString.Key.attachment] as? DTTextAttachment {
			return block(attachment)
		}
		return accessibilityElement(forText: attributedString, at: range, attributes: attributes, runs: runs, view: view)
	}

	private func accessibilityElement(forText attributedString: NSAttributedString, at range: NSRange, attributes: NSDictionary, runs: [DTCoreTextGlyphRun], view: UIView) -> AccessibilityElement {
		let text = (attributedString.string as NSString).substring(with: range)

		let element = AccessibilityElement(parentView: view)
		element.accessibilityLabel = text
		element.localCoordinateAccessibilityFrame = frameForRuns(runs)

		if runs.count > 1 {
			element.localCoordinateAccessibilityActivationPoint = runs[0].frame.origin
		}

		element.accessibilityTraits = .staticText

		if attributes[DTLinkAttribute] != nil {
			element.accessibilityTraits.insert(.link)
		}

		return element
	}

	private func frameForRuns(_ runs: [DTCoreTextGlyphRun]) -> CGRect {
		var frame = CGRect.null
		for run in runs {
			frame = frame.union(run.frame)
		}
		return frame
	}
}

#endif
