//
//  HTMLAttributedStringBuilder.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//
//  Migrated to Swift with async/await, April 2026.
//

import Foundation
import CoreGraphics
import DTCoreText
import HTMLParser
import os.log

#if canImport(CoreText)
import CoreText
#endif

#if canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias PlatformColor = NSColor
#endif

private let logger = Logger(subsystem: "com.cocoanetics.DTCoreText", category: "HTMLAttributedStringBuilder")

/// Block called before an element is flushed to the output attributed string.
public typealias HTMLAttributedStringBuilderWillFlushCallback = @Sendable (DTHTMLElement) -> Void

/// Block called when an HTML parsing error occurs.
public typealias HTMLAttributedStringBuilderParseErrorCallback = @Sendable (NSAttributedString, Error) -> Void

// MARK: - Builder State Actor

/// Owns all mutable parse/build state. Events are processed sequentially.
private actor BuilderState {
	// Parsing tree
	var rootNode: DTHTMLElement?
	var bodyElement: DTHTMLElement?
	var currentTag: DTHTMLElement?
	var ignoreParseEvents = false

	// Output
	var tmpString = NSMutableAttributedString()

	// Config (set once before parsing)
	var textScale: CGFloat = 1.0
	var defaultLinkColor: PlatformColor?
	var globalStyleSheet: DTCSSStylesheet!
	var baseURL: URL?
	var defaultFontDescriptor: DTCoreTextFontDescriptor!
	var defaultParagraphStyle: DTCoreTextParagraphStyle!
	var defaultTag: DTHTMLElement!
	var shouldProcessCustomHTMLAttributes = false
	var ignoreInlineStyles = false
	var preserveDocumentTrailingSpaces = false
	var shouldKeepDocumentNodeTree = false
	var willFlushCallback: HTMLAttributedStringBuilderWillFlushCallback?
	var parseErrorCallback: HTMLAttributedStringBuilderParseErrorCallback?
	var options: [String: Any] = [:]

	// MARK: - Configuration

	func configure(options: [String: Any],
				   willFlushCallback: HTMLAttributedStringBuilderWillFlushCallback?,
				   parseErrorCallback: HTMLAttributedStringBuilderParseErrorCallback?,
				   shouldKeepDocumentNodeTree: Bool) {

		self.options = options
		self.willFlushCallback = willFlushCallback
		self.parseErrorCallback = parseErrorCallback
		self.shouldKeepDocumentNodeTree = shouldKeepDocumentNodeTree

		// Text scale
		if let scaleValue = options["NSTextSizeMultiplierDocumentOption"] as? NSNumber {
			textScale = CGFloat(scaleValue.floatValue)
		}
		if textScale == 0 { textScale = 1.0 }

		// Base URL
		baseURL = options["NSBaseURLDocumentOption"] as? URL

		// Global stylesheet
		globalStyleSheet = DTCSSStylesheet.defaultStyleSheet().copy() as? DTCSSStylesheet

		if let customSheet = options[DTDefaultStyleSheet] as? DTCSSStylesheet {
			globalStyleSheet.merge(customSheet)
		}

		// Default font
		var defaultFontSize: CGFloat = 12.0

		if let ctDescriptorValue = options[DTDefaultFontDescriptor],
		   CFGetTypeID(ctDescriptorValue as CFTypeRef) == CTFontDescriptorGetTypeID() {
			defaultFontDescriptor = DTCoreTextFontDescriptor(ctFontDescriptor: ctDescriptorValue as! CTFontDescriptor)
		} else {
			defaultFontDescriptor = DTCoreTextFontDescriptor(fontAttributes: nil)

			if let sizeNum = options[DTDefaultFontSize] as? NSNumber {
				defaultFontSize = CGFloat(sizeNum.floatValue)
			}
			defaultFontDescriptor.pointSize = defaultFontSize * textScale
			defaultFontDescriptor.fontFamily = (options[DTDefaultFontFamily] as? String) ?? "Times New Roman"

			if let name = options[DTDefaultFontName] as? String {
				defaultFontDescriptor.fontName = name
			}
		}

		// Link color
		if let linkColor = options[DTDefaultLinkColor] {
			if let colorString = linkColor as? String {
				defaultLinkColor = DTColorCreateWithHTMLName(colorString)
			} else if let color = linkColor as? PlatformColor {
				defaultLinkColor = color
			}
			if let color = defaultLinkColor {
				let hex = DTHexStringFromDTColor(color)
				globalStyleSheet.parseStyleBlock("a {color:#\(hex);}")
			}
		}

		// Link decoration
		if let dec = options[DTDefaultLinkDecoration] as? NSNumber, !dec.boolValue {
			globalStyleSheet.parseStyleBlock("a {text-decoration:none;}")
		}

		// Link highlight color
		if let highlight = options[DTDefaultLinkHighlightColor] {
			var color: PlatformColor?
			if let s = highlight as? String { color = DTColorCreateWithHTMLName(s) }
			else if let c = highlight as? PlatformColor { color = c }
			if let color {
				let hex = DTHexStringFromDTColor(color)
				globalStyleSheet.parseStyleBlock("a:active {color:#\(hex);}")
			}
		}

		// Default paragraph style
		defaultParagraphStyle = DTCoreTextParagraphStyle.`default`()

		if let lh = options[DTDefaultLineHeightMultiplier] as? NSNumber {
			defaultParagraphStyle.lineHeightMultiple = CGFloat(lh.floatValue)
		}
		if let align = options[DTDefaultTextAlignment] as? NSNumber {
			defaultParagraphStyle.alignment = CTTextAlignment(rawValue: UInt8(align.intValue)) ?? .natural
		}
		if let fi = options[DTDefaultFirstLineHeadIndent] as? NSNumber {
			defaultParagraphStyle.firstLineHeadIndent = CGFloat(fi.intValue)
		}
		if let hi = options[DTDefaultHeadIndent] as? NSNumber {
			defaultParagraphStyle.headIndent = CGFloat(hi.intValue)
		}

		// Default tag element
		defaultTag = DTHTMLElement()
		defaultTag.fontDescriptor = defaultFontDescriptor
		defaultTag.paragraphStyle = defaultParagraphStyle
		defaultTag.textScale = textScale
		defaultTag.currentTextSize = defaultFontDescriptor.pointSize
		defaultTag.underlineColor = PlatformColor.black

		if let defaultColor = options[DTDefaultTextColor] {
			if let color = defaultColor as? PlatformColor { defaultTag.textColor = color }
			else if let s = defaultColor as? String { defaultTag.textColor = DTColorCreateWithHTMLName(s) }
		}

		shouldProcessCustomHTMLAttributes = (options[DTProcessCustomHTMLAttributes] as? NSNumber)?.boolValue ?? false
		ignoreInlineStyles = (options[DTIgnoreInlineStylesOption] as? NSNumber)?.boolValue ?? false
		preserveDocumentTrailingSpaces = (options[DTDocumentPreserveTrailingSpaces] as? NSNumber)?.boolValue ?? false
	}

	// MARK: - Event Handling

	func handle(_ event: HTMLParserEvent) {
		switch event {
		case .startDocument:
			break
		case .endDocument:
			handleEndDocument()
		case let .startElement(name, attributes):
			handleStartElement(name, attributes: attributes)
		case let .endElement(name):
			handleEndElement(name)
		case let .characters(string):
			handleFoundCharacters(string)
		case let .cdata(data):
			handleFoundCDATA(data)
		case .comment, .processingInstruction:
			break
		case let .parseError(error):
			parseErrorCallback?(tmpString, error)
		}
	}

	func result() -> sending NSAttributedString {
		nonisolated(unsafe) let copy = NSAttributedString(attributedString: tmpString)
		return copy
	}

	// MARK: - Start Element

	private func handleStartElement(_ elementName: String, attributes attributeDict: [String: String]) {
		guard !ignoreParseEvents else { return }

		guard let newNode = DTHTMLElement(name: elementName, attributes: attributeDict as [AnyHashable: Any], options: options) else { return }
		var previousLastChild: DTHTMLElement?

		if let current = currentTag {
			newNode.inheritAttributes(from: current)
			newNode.interpretAttributes()

			previousLastChild = current.childNodes?.last as? DTHTMLElement
			current.addChildNode(newNode)

			if bodyElement == nil && newNode.name == "body" {
				bodyElement = newNode
			}
			if shouldProcessCustomHTMLAttributes {
				newNode.shouldProcessCustomHTMLAttributes = true
			}
		} else {
			assert(rootNode == nil, "Something went wrong, second root node found")
			if rootNode == nil {
				rootNode = newNode
				newNode.inheritAttributes(from: defaultTag)
				newNode.interpretAttributes()
			}
		}

		// Apply styles from merged stylesheet
		var matchedSelectors: NSSet?
		let mergedStyles = globalStyleSheet.mergedStyleDictionary(for: newNode, matchedSelectors: &matchedSelectors, ignoreInlineStyle: ignoreInlineStyles)

		if let mergedStyles = mergedStyles as NSDictionary? {
			newNode.applyStyleDictionary(mergedStyles as! [AnyHashable: Any])

			if let matchedSelectors {
				var classNamesToIgnore = Set<String>()
				for case let selector as String in matchedSelectors {
					if let periodRange = selector.range(of: ".") {
						classNamesToIgnore.insert(String(selector[selector.index(after: periodRange.lowerBound)...]))
					}
				}
				if !classNamesToIgnore.isEmpty {
					newNode.setValue(NSSet(array: classNamesToIgnore.map { $0 as NSString }),
									forKey: "CSSClassNamesToIgnoreForCustomAttributes")
				}
			}
		}

		// Block element eliminates previous trailing whitespace
		if let previousLastChild, newNode.displayStyle != .inline,
		   let textElement = previousLastChild as? DTTextHTMLElement,
		   textElement.text()?.isIgnorableWhitespace() == true {
			currentTag?.removeChildNode(textElement)
		}

		currentTag = newNode

		// Tag-specific start handling
		applyTagStartHandler(elementName, tag: newNode)
	}

	// MARK: - Tag Start Handlers (inline)

	private func applyTagStartHandler(_ name: String, tag: DTHTMLElement) {
		switch name {
		case "blockquote":
			tag.paragraphStyle.headIndent += 25.0 * textScale
			tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent
			tag.paragraphStyle.paragraphSpacing = defaultFontDescriptor.pointSize

		case "a":
			handleAnchorStart(tag)

		case "ul", "ol":
			tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent
			if let newListStyle = tag.listStyle() {
				var textLists = (tag.paragraphStyle.textLists as? [DTCSSListStyle]) ?? []
				textLists.append(newListStyle)
				tag.paragraphStyle.textLists = textLists
			}

		case "h1": tag.headerLevel = 1
		case "h2": tag.headerLevel = 2
		case "h3": tag.headerLevel = 3
		case "h4": tag.headerLevel = 4
		case "h5": tag.headerLevel = 5
		case "h6": tag.headerLevel = 6

		case "font":
			handleFontStart(tag)

		case "p":
			if defaultParagraphStyle.firstLineHeadIndent > 0 {
				tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent + defaultParagraphStyle.firstLineHeadIndent
			} else {
				tag.paragraphStyle.firstLineHeadIndent = tag.paragraphStyle.headIndent + tag.pTextIndent
			}

		default:
			break
		}
	}

	private func handleAnchorStart(_ tag: DTHTMLElement) {
		if tag.isColorInherited || tag.textColor == nil {
			tag.textColor = defaultLinkColor
			tag.isColorInherited = false
		}

		tag.anchorName = tag.attribute(forKey: "name")

		guard var cleanString = tag.attribute(forKey: "href")?.replacingOccurrences(of: "\n", with: ""),
			  !cleanString.trimmingCharacters(in: .whitespaces).isEmpty else {
			return
		}
		cleanString = cleanString.trimmingCharacters(in: .whitespaces)

		var link = URL(string: cleanString)
		if link == nil, let encoded = (cleanString as NSString).encodingNonASCIICharacters() {
			link = URL(string: encoded)
		}
		if link?.scheme == nil {
			if !cleanString.isEmpty {
				link = URL(string: cleanString, relativeTo: baseURL)
				if link == nil, let entityEncoded = (cleanString as NSString).addingHTMLEntities() {
					link = URL(string: entityEncoded, relativeTo: baseURL)
				}
			} else {
				link = baseURL
			}
		}
		tag.link = link
	}

	private func handleFontStart(_ tag: DTHTMLElement) {
		var pointSize: CGFloat
		if let sizeAttribute = tag.attribute(forKey: "size") {
			switch Int(sizeAttribute) ?? 0 {
			case 1: pointSize = textScale * 10.0
			case 2: pointSize = textScale * 13.0
			case 3: pointSize = textScale * 16.0
			case 4: pointSize = textScale * 18.0
			case 5: pointSize = textScale * 24.0
			case 6: pointSize = textScale * 32.0
			case 7: pointSize = textScale * 48.0
			default: pointSize = defaultFontDescriptor.pointSize
			}
		} else {
			pointSize = tag.fontDescriptor.pointSize
		}
		if let face = tag.attribute(forKey: "face") {
			let font = CTFontCreateWithName(face as CFString, pointSize, nil)
			tag.fontDescriptor = DTCoreTextFontDescriptor(ctFont: font)
		} else {
			tag.fontDescriptor.pointSize = pointSize
		}
		if let color = tag.attribute(forKey: "color") {
			tag.textColor = DTColorCreateWithHTMLName(color)
		}
	}

	// MARK: - End Element

	private func handleEndElement(_ elementName: String) {
		guard !ignoreParseEvents else { return }

		// Tag-specific end handling
		if let tag = currentTag {
			applyTagEndHandler(elementName, tag: tag)
		}

		// Flush if direct child of body or body itself
		if let tag = currentTag, tag.displayStyle != DTHTMLElementDisplayStyle.none {
			if tag === bodyElement || tag.parent() === bodyElement {
				flush(tag)
			}
		}

		// Walk up to find matching element
		while currentTag?.name != elementName {
			currentTag = currentTag?.parent()
		}

		// Closing root node — ignore everything afterwards
		if currentTag === rootNode {
			ignoreParseEvents = true
		}

		currentTag = currentTag?.parent()
	}

	// MARK: - Tag End Handlers (inline)

	private func applyTagEndHandler(_ name: String, tag: DTHTMLElement) {
		switch name {
		case "object":
			if let attachmentElement = tag as? DTTextAttachmentHTMLElement,
			   let objectAttachment = attachmentElement.textAttachment as? DTObjectTextAttachment {
				objectAttachment.childNodes = (tag.childNodes as NSArray?)?.copy() as? [Any]
			}

		case "video":
			if let attachmentElement = tag as? DTTextAttachmentHTMLElement,
			   let videoAttachment = attachmentElement.textAttachment as? DTVideoTextAttachment,
			   videoAttachment.contentURL == nil {
				for child in (attachmentElement.childNodes as? [DTHTMLElement]) ?? [] {
					if child.name == "source", let src = child.attribute(forKey: "src") {
						videoAttachment.contentURL = URL(string: src, relativeTo: baseURL)
						break
					}
				}
			}

		case "style":
			if let stylesheetElement = tag as? DTStylesheetHTMLElement {
				globalStyleSheet.merge(stylesheetElement.stylesheet())
			}

		case "link":
			guard let href = tag.attribute(forKey: "href"),
				  let type = tag.attribute(forKey: "type")?.lowercased(),
				  type == "text/css" else { break }
			guard let stylesheetURL = URL(string: href, relativeTo: baseURL),
				  stylesheetURL.isFileURL else {
				logger.warning("CSS link referencing a non-local target, ignored")
				break
			}
			if let content = try? String(contentsOf: stylesheetURL, encoding: .utf8) {
				globalStyleSheet.merge(DTCSSStylesheet(styleBlock: content))
			}

		default:
			break
		}
	}

	// MARK: - Found Characters

	private func handleFoundCharacters(_ string: String) {
		guard !ignoreParseEvents else { return }
		guard let current = currentTag else {
			assertionFailure("Cannot add text node without a current node")
			return
		}

		if !current.preserveNewlines && (string as NSString).isIgnorableWhitespace() {
			if current.displayStyle != .inline && (current.childNodes?.count ?? 0) == 0 {
				return
			}
			if let previousTag = current.childNodes?.last as? DTHTMLElement,
			   previousTag.displayStyle != .inline {
				return
			}
			if current.childNodes?.last is DTBreakHTMLElement {
				return
			}
		}

		let textNode = DTTextHTMLElement()
		textNode.setValue(string, forKey: "text")
		textNode.inheritAttributes(from: current)
		textNode.interpretAttributes()
		current.addChildNode(textNode)

		// Text directly in body needs immediate output
		if current === bodyElement {
			tmpString.append(textNode.attributedString())
			current.didOutput = true

			if shouldKeepDocumentNodeTree {
				current.addChildNode(textNode)
			}
		}
	}

	// MARK: - Found CDATA

	private func handleFoundCDATA(_ data: Data) {
		guard !ignoreParseEvents, currentTag != nil else { return }
		guard let styleBlock = String(data: data, encoding: .utf8) else { return }
		let textNode = DTHTMLParserTextNode(characters: styleBlock)
		currentTag?.addChildNode(textNode)
	}

	// MARK: - End Document

	private func handleEndDocument() {
		if !preserveDocumentTrailingSpaces {
			while (tmpString.string as NSString).hasSuffixCharacter(from: .whitespaces) {
				tmpString.deleteCharacters(in: NSRange(location: tmpString.length - 1, length: 1))
			}
		}
	}

	// MARK: - Flushing

	private func flush(_ tag: DTHTMLElement) {
		guard tag.needsOutput() else { return }

		willFlushCallback?(tag)

		guard let nodeString = tag.attributedString() else { return }

		if tag.displayStyle != .inline {
			if tmpString.length > 0 && !tmpString.string.hasSuffix("\n") {
				while (tmpString.string as NSString).hasSuffixCharacter(from: NSCharacterSet.ignorableWhitespace()) {
					tmpString.deleteCharacters(in: NSRange(location: tmpString.length - 1, length: 1))
				}
				tmpString.append(NSAttributedString(string: "\n"))
			}
		}

		tmpString.append(nodeString)
		tag.didOutput = true

		if !shouldKeepDocumentNodeTree {
			tag.removeAllChildNodes()
		}
	}
}

// MARK: - Builder

/// Builds an `NSAttributedString` from an HTML document.
@objc(DTHTMLAttributedStringBuilder)
public final class HTMLAttributedStringBuilder: NSObject, @unchecked Sendable {

	private let data: Data
	private let options: [String: Any]
	private let parser: HTMLParser
	private let state = BuilderState()

	// Cached result
	private var cachedResult: NSAttributedString?

	// MARK: - Public Properties

	/// Block called before each element is flushed to the output string.
	@objc public var willFlushCallback: HTMLAttributedStringBuilderWillFlushCallback?

	/// Block called when an HTML parsing error occurs.
	@objc public var parseErrorCallback: HTMLAttributedStringBuilderParseErrorCallback?

	/// Whether to preserve the document node tree after generation.
	@objc public var shouldKeepDocumentNodeTree = false

	// MARK: - Init

	/// Creates a builder from HTML data.
	@objc
	public init?(html data: Data, options: [String: Any]?, documentAttributes: AutoreleasingUnsafeMutablePointer<NSDictionary?>?) {
		self.data = data
		self.options = options ?? [:]

		var encoding: String.Encoding = .utf8
		if let encodingName = self.options["NSTextEncodingNameDocumentOption"] as? String {
			let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
			if cfEncoding != kCFStringEncodingInvalidId {
				encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
			}
		}

		self.parser = HTMLParser(data: data, encoding: encoding)
		super.init()
	}

	// MARK: - Async API (preferred)

	/// Generates the attributed string asynchronously.
	public func generatedAttributedString() async -> NSAttributedString? {
		if let cachedResult { return cachedResult }
		guard !data.isEmpty else { return nil }

		await state.configure(
			options: options,
			willFlushCallback: willFlushCallback,
			parseErrorCallback: parseErrorCallback,
			shouldKeepDocumentNodeTree: shouldKeepDocumentNodeTree
		)

		for await event in parser.parseEvents() {
			await state.handle(event)
		}

		let result = await state.result()
		cachedResult = result
		return result
	}

	// MARK: - Sync API (ObjC compatibility shim)

	/// Generates and returns the attributed string from the HTML.
	/// Blocks the calling thread. Prefer the async version for Swift callers.
	@objc
	public func generatedAttributedString() -> NSAttributedString? {
		if let cachedResult { return cachedResult }

		let semaphore = DispatchSemaphore(value: 0)
		nonisolated(unsafe) var result: NSAttributedString?

		Task { [self] in
			result = await self.generatedAttributedString()
			semaphore.signal()
		}

		semaphore.wait()
		cachedResult = result
		return result
	}

	/// Aborts the current parsing operation.
	@objc
	public func abortParsing() {
		parser.abortParsing()
	}
}
