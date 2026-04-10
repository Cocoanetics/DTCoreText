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

/// Block that provides an accessibility object for a text attachment.
public typealias AttachmentViewProvider = (TextAttachment) -> Any?

/// Generates accessibility elements for a CoreTextLayoutFrame.
@objc(DTCoreTextLayoutFrameAccessibilityElementGenerator)
public class LayoutFrameAccessibilityElementGenerator: NSObject {

	@objc
	public func accessibilityElements(for frame: CoreTextLayoutFrame, view: UIView, attachmentViewProvider block: @escaping AttachmentViewProvider) -> [Any] {
		var elements = [Any]()

		guard let paragraphRanges = frame.paragraphRanges as? [NSValue] else { return elements }

		for idx in 0..<paragraphRanges.count {
			let paragraphElements = accessibilityElements(inParagraphAt: idx, layoutFrame: frame, view: view, attachmentViewProvider: block)
			elements.append(contentsOf: paragraphElements)
		}

		return elements
	}

	private func accessibilityElements(inParagraphAt index: Int, layoutFrame frame: CoreTextLayoutFrame, view: UIView, attachmentViewProvider block: @escaping AttachmentViewProvider) -> [Any] {
		var elements = [Any]()

		guard let fragment = frame.attributedStringFragment() else { return elements }
		enumerateAccessibleGroups(in: frame, forParagraphAt: index) { attrs, substringRange, _, runs in
			if let element = self.accessibilityElement(for: fragment, at: substringRange, attributes: attrs, runs: runs, view: view, attachmentViewProvider: block) {
				elements.append(element)
			}
		}

		return elements
	}

	private func enumerateAccessibleGroups(in frame: CoreTextLayoutFrame, forParagraphAt index: Int, using block: (NSDictionary, NSRange, UnsafeMutablePointer<ObjCBool>, [CoreTextGlyphRun]) -> Void) {
		guard let paragraphRanges = frame.paragraphRanges as? [NSValue], index < paragraphRanges.count else { return }

		let paragraphRange = paragraphRanges[index].rangeValue
		guard let lines = frame.linesInParagraph(at: UInt(index)) as? [CoreTextLayoutLine] else { return }

		guard let fragment = frame.attributedStringFragment() else { return }
		fragment.enumerateAttributes(in: paragraphRange, options: []) { attrs, range, stop in
			var runs = [CoreTextGlyphRun]()
			for line in lines {
				if let lineRuns = line.glyphRuns(with: range) as? [CoreTextGlyphRun] {
					runs.append(contentsOf: lineRuns)
				}
			}
			block(attrs as NSDictionary, range, stop, runs)
		}
	}

	private func accessibilityElement(for attributedString: NSAttributedString, at range: NSRange, attributes: NSDictionary, runs: [CoreTextGlyphRun], view: UIView, attachmentViewProvider block: AttachmentViewProvider) -> Any? {
		if let attachment = attributes[NSAttributedString.Key.attachment] as? TextAttachment {
			return block(attachment)
		}
		return accessibilityElement(forText: attributedString, at: range, attributes: attributes, runs: runs, view: view)
	}

	private func accessibilityElement(forText attributedString: NSAttributedString, at range: NSRange, attributes: NSDictionary, runs: [CoreTextGlyphRun], view: UIView) -> AccessibilityElement {
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

	private func frameForRuns(_ runs: [CoreTextGlyphRun]) -> CGRect {
		var frame = CGRect.null
		for run in runs {
			frame = frame.union(run.frame)
		}
		return frame
	}
}

#endif
