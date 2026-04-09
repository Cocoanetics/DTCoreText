//
//  CoreTextLayoutFrame+Cursor.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 10.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import Foundation
import CoreGraphics

extension CoreTextLayoutFrame {

	/// Determines the closest string index to a point in the receiver's frame.
	@objc(closestCursorIndexToPoint:)
	public func closestCursorIndex(to point: CGPoint) -> Int {
		guard let lines = self.lines as? [CoreTextLayoutLine], !lines.isEmpty else {
			return NSNotFound
		}

		let firstLine = lines[0]
		if point.y < firstLine.frame.minY {
			return 0
		}

		let lastLine = lines[lines.count - 1]
		if point.y > lastLine.frame.maxY {
			let stringRange = visibleStringRange()
			if stringRange.length > 0 {
				return NSMaxRange(stringRange) - 1
			}
		}

		// Find closest line
		var closestLine: CoreTextLayoutLine?
		var closestDistance: CGFloat = .greatestFiniteMagnitude

		for line in lines {
			// Line contains point
			if line.frame.minY <= point.y && line.frame.maxY >= point.y {
				closestLine = line
				break
			}

			let top = line.frame.minY
			let bottom = line.frame.maxY
			var distance: CGFloat = .greatestFiniteMagnitude

			if top > point.y {
				distance = top - point.y
			} else if bottom < point.y {
				distance = point.y - bottom
			}

			if distance < closestDistance {
				closestLine = line
				closestDistance = distance
			}
		}

		guard let closestLine else {
			return NSNotFound
		}

		var closestIndex = closestLine.stringIndex(forPosition: point)
		let maxIndex = NSMaxRange(closestLine.stringRange()) - 1

		if closestIndex > maxIndex {
			closestIndex = maxIndex
		}

		if closestIndex >= 0 {
			return closestIndex
		}

		return NSNotFound
	}

	/// The rectangle for drawing a caret at the given string index.
	@objc(cursorRectAtIndex:)
	public func cursorRect(atIndex index: Int) -> CGRect {
		guard let line = lineContaining(UInt(index)) else {
			return .zero
		}

		let offset = line.offset(forStringIndex: index)
		var rect = line.frame
		rect.size.width = 3.0
		rect.origin.x += offset

		return rect
	}
}
