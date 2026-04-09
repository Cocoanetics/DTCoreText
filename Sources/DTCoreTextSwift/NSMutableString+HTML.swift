//
//  NSMutableString+HTML.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 2011.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import Foundation

extension NSMutableString {

	/// Removes trailing whitespace characters (space, tab, newlines, vertical tab, form feed, NEL) from the receiver.
	@objc
	public func removeTrailingWhitespace() {
		let len = length
		guard len > 0 else { return }

		var index = len - 1
		var whitespaceLength = 0

		while index >= 0 {
			let c = character(at: index)
			if c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0B || c == 0x0C || c == 0x0D || c == 0x85 {
				whitespaceLength += 1
				if index == 0 { break }
				index -= 1
			} else {
				break
			}
		}

		if whitespaceLength > 0 {
			deleteCharacters(in: NSRange(location: len - whitespaceLength, length: whitespaceLength))
		}
	}
}
