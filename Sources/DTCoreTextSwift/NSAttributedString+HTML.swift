//
//  NSAttributedString+HTML.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import Foundation

extension NSAttributedString {

	/// Creates an attributed string from HTML data.
	@objc
	public convenience init?(htmlData data: Data, documentAttributes: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) {
		self.init(htmlData: data, options: [:], documentAttributes: documentAttributes)
	}

	/// Creates an attributed string from HTML data with a base URL.
	@objc
	public convenience init?(htmlData data: Data, baseURL: URL?, documentAttributes: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) {
		var options = [String: Any]()
		if let baseURL {
			options[NSAttributedString.DocumentReadingOptionKey.baseURL.rawValue] = baseURL
		}
		self.init(htmlData: data, options: options, documentAttributes: documentAttributes)
	}

	/// Creates an attributed string from HTML data with options.
	@objc
	public convenience init?(htmlData data: Data, options: [String: Any], documentAttributes: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) {
		guard !data.isEmpty else { return nil }

		guard let builder = HTMLAttributedStringBuilder(html: data, options: options, documentAttributes: documentAttributes) else {
			return nil
		}

		if let callbackBlock = options[DTWillFlushBlockCallBack] as? HTMLAttributedStringBuilderWillFlushCallback {
			builder.willFlushCallback = callbackBlock
		}

		guard let string = builder.generatedAttributedString() else {
			return nil
		}

		self.init(attributedString: string)
	}
}
