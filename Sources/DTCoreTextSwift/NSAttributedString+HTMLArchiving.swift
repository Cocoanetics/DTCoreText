//
//  NSAttributedString+HTMLArchiving.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/9/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//
//  Migrated to Swift, April 2026.
//

import Foundation
import CoreText
import DTCoreText

#if canImport(UIKit)
import UIKit
#endif

extension NSAttributedString {

	// MARK: - Private Helpers

	private static func getArchivingDictionary(with attrs: [NSAttributedString.Key: Any]) -> NSMutableDictionary {
		let archiveValue = attrs[NSAttributedString.Key(rawValue: DTArchivingAttribute)]
		if let archiveDict = archiveValue as? NSDictionary {
			return archiveDict.mutableCopy() as! NSMutableDictionary
		}
		return NSMutableDictionary()
	}

	// MARK: - Archiving

	/// Archives the attributed string to `Data` using `NSKeyedArchiver`.
	@objc
	public func convertToData() -> Data? {
		let appendString = self.mutableCopy() as! NSMutableAttributedString

		#if canImport(UIKit)
		let length = self.length
		if length > 0 {
			self.enumerateAttributes(in: NSRange(location: 0, length: length - 1), options: []) { attrs, range, _ in
				let typedAttrs = Dictionary(uniqueKeysWithValues: attrs.map { (NSAttributedString.Key(rawValue: $0.key.rawValue), $0.value) })
				let dict = Self.getArchivingDictionary(with: typedAttrs)

				if let attachment = attrs[.attachment] as? DTTextAttachment {
					var imgPath: String? = nil
					if attachment.contentURL?.scheme == "file" {
						imgPath = attachment.contentURL?.path
						let homeDir = NSHomeDirectory()
						if let path = imgPath, path.hasPrefix(homeDir), path.count > homeDir.count {
							imgPath = String(path.dropFirst(homeDir.count))
						}
					} else {
						imgPath = attachment.contentURL?.absoluteString
					}

					if let imgPath {
						dict.setObject(imgPath, forKey: NSAttributedString.Key.attachment.rawValue as NSString)
						appendString.addAttribute(NSAttributedString.Key(rawValue: DTArchivingAttribute), value: dict, range: range)
					}
					appendString.removeAttribute(NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String), range: range)
				}

				if let strokeColorRef = attrs[NSAttributedString.Key(rawValue: DTBackgroundStrokeColorAttribute)] {
					let strokeCGColor = strokeColorRef as! CGColor
					let strokeColor = UIColor(cgColor: strokeCGColor)
					dict.setObject(strokeColor, forKey: DTBackgroundStrokeColorAttribute as NSString)
					appendString.addAttribute(NSAttributedString.Key(rawValue: DTArchivingAttribute), value: dict, range: range)
					appendString.removeAttribute(NSAttributedString.Key(rawValue: DTBackgroundStrokeColorAttribute), range: range)
				}
			}
		}
		#endif

		do {
			return try NSKeyedArchiver.archivedData(withRootObject: appendString, requiringSecureCoding: false)
		} catch {
			return nil
		}
	}

	/// Unarchives an attributed string from `Data` using `NSKeyedUnarchiver`.
	@objc
	public static func attributedString(with data: Data) -> NSAttributedString? {
		var appendString: NSMutableAttributedString?

		do {
			var allowedClasses: [AnyClass] = [
				NSMutableAttributedString.self,
				NSDictionary.self,
				NSString.self,
				NSNumber.self,
				NSArray.self,
				NSParagraphStyle.self,
				NSShadow.self,
				NSURL.self,
				DTTextAttachment.self,
				DTImageTextAttachment.self
			]
			#if canImport(UIKit)
			allowedClasses.append(contentsOf: [UIFont.self, UIColor.self])
			#endif
			let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: data)
			appendString = unarchived as? NSMutableAttributedString
		} catch {
			appendString = nil
		}

		guard let appendString, appendString.length > 0 else {
			return appendString?.copy() as? NSAttributedString
		}

		let length = appendString.length

		appendString.enumerateAttributes(in: NSRange(location: 0, length: length - 1), options: .longestEffectiveRangeNotRequired) { attrs, range, _ in

			#if canImport(UIKit)
			if let attachment = attrs[.attachment] as? DTTextAttachment {
				if attachment.contentURL?.scheme == "file" {
					let typedAttrs = Dictionary(uniqueKeysWithValues: attrs.map { (NSAttributedString.Key(rawValue: $0.key.rawValue), $0.value) })
					let dict = Self.getArchivingDictionary(with: typedAttrs)
					if var imgPath = dict[NSAttributedString.Key.attachment.rawValue] as? String {
						if !imgPath.hasPrefix(NSHomeDirectory()) {
							imgPath = (NSHomeDirectory() as NSString).appendingPathComponent(imgPath)
						}
						attachment.contentURL = URL(fileURLWithPath: imgPath)
					}
				}

				if let unmanagedRunDelegate = createEmbeddedObjectRunDelegate(attachment) {
					let runDelegate = unmanagedRunDelegate.takeRetainedValue()
					appendString.addAttribute(
						NSAttributedString.Key(rawValue: kCTRunDelegateAttributeName as String),
						value: runDelegate,
						range: range
					)
				}
			}

			if attrs[NSAttributedString.Key(rawValue: DTBackgroundStrokeColorAttribute)] != nil {
				let typedAttrs = Dictionary(uniqueKeysWithValues: attrs.map { (NSAttributedString.Key(rawValue: $0.key.rawValue), $0.value) })
				let dict = Self.getArchivingDictionary(with: typedAttrs)
				if let stroke = dict[DTBackgroundStrokeColorAttribute] as? UIColor {
					let strokeColor = stroke.cgColor
					appendString.addAttribute(
						NSAttributedString.Key(rawValue: DTBackgroundStrokeColorAttribute),
						value: strokeColor,
						range: range
					)
				}
			}
			#endif
		}

		return appendString.copy() as? NSAttributedString
	}

	// MARK: - HTML Attributes

	/// Returns the dictionary of custom HTML attributes at the given index.
	@objc
	public func htmlAttributes(at index: Int) -> [String: Any]? {
		return attribute(NSAttributedString.Key(rawValue: DTCustomAttributesAttribute), at: index, effectiveRange: nil) as? [String: Any]
	}

	/// Returns the range of a named HTML attribute starting from the given index, extending in both directions as long as the attribute value is equal.
	@objc
	public func rangeOfHTMLAttribute(_ name: String, at index: Int) -> NSRange {
		var rangeSoFar = NSRange(location: 0, length: 0)
		guard let attributes = attribute(NSAttributedString.Key(rawValue: DTCustomAttributesAttribute), at: index, effectiveRange: &rangeSoFar) as? [String: Any] else {
			return NSRange(location: NSNotFound, length: 0)
		}

		guard let value = attributes[name] as? NSObject else {
			return NSRange(location: NSNotFound, length: 0)
		}

		// Extend backwards
		while rangeSoFar.location > 0 {
			var extendedRange = NSRange(location: 0, length: 0)
			guard let extAttrs = attribute(NSAttributedString.Key(rawValue: DTCustomAttributesAttribute), at: rangeSoFar.location - 1, effectiveRange: &extendedRange) as? [String: Any],
				  let extendedValue = extAttrs[name] as? NSObject,
				  extendedValue.isEqual(value) else {
				break
			}
			rangeSoFar = NSUnionRange(rangeSoFar, extendedRange)
		}

		// Extend forwards
		let length = self.length
		while NSMaxRange(rangeSoFar) < length {
			var extendedRange = NSRange(location: 0, length: 0)
			guard let extAttrs = attribute(NSAttributedString.Key(rawValue: DTCustomAttributesAttribute), at: NSMaxRange(rangeSoFar), effectiveRange: &extendedRange) as? [String: Any],
				  let extendedValue = extAttrs[name] as? NSObject,
				  extendedValue.isEqual(value) else {
				break
			}
			rangeSoFar = NSUnionRange(rangeSoFar, extendedRange)
		}

		return rangeSoFar
	}
}
