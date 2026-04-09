//
//  CoreTextParagraphStyle.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// `CoreTextParagraphStyle` encapsulates the paragraph or ruler attributes used by the NSAttributedString classes.
/// It is a replacement for `NSParagraphStyle` on platforms where CTParagraphStyle is used.
@objc(DTCoreTextParagraphStyle)
public class CoreTextParagraphStyle: NSObject, NSCopying {

    // MARK: - Properties

    /// The indentation of the first line of the receiver.
    @objc public var firstLineHeadIndent: CGFloat = 0.0

    /// The document-wide default tab interval.
    @objc public var defaultTabInterval: CGFloat = 36.0

    /// The distance between the paragraph's top and the beginning of its text content.
    @objc public var paragraphSpacingBefore: CGFloat = 0.0

    /// The space after the end of the paragraph.
    @objc public var paragraphSpacing: CGFloat = 0.0

    /// The line height multiple.
    @objc public var lineHeightMultiple: CGFloat = 0.0

    /// The minimum height in points that any line in the receiver will occupy.
    @objc public var minimumLineHeight: CGFloat = 0.0

    /// The maximum height in points that any line in the receiver will occupy.
    @objc public var maximumLineHeight: CGFloat = 0.0

    /// The distance in points from the margin of a text container to the end of lines.
    @objc public var tailIndent: CGFloat = 0.0

    /// The distance in points from the leading margin of a text container to the beginning of lines other than the first.
    @objc public var headIndent: CGFloat = 0.0

    /// The text alignment of the receiver.
    @objc public var alignment: CTTextAlignment = .natural

    /// The base writing direction for the receiver.
    @objc public var baseWritingDirection: CTWritingDirection = .natural

    /// The CTTextTab objects that define the tab stops for the paragraph style.
    @objc public var tabStops: [Any]? {
        didSet {
            if let newValue = tabStops {
                _tabStops = NSMutableArray(array: newValue)
            } else {
                _tabStops = nil
            }
        }
    }

    /// Text lists containing the paragraph, nested from outermost to innermost.
    @objc public var textLists: [Any]?

    /// Text blocks containing the paragraph, nested from outermost to innermost.
    @objc public var textBlocks: [Any]?

    private var _tabStops: NSMutableArray?

    // MARK: - Initialization

    /// Returns the default paragraph style.
    @objc public class func defaultParagraphStyle() -> CoreTextParagraphStyle {
        return CoreTextParagraphStyle()
    }

    @objc public override init() {
        super.init()
    }

    /// Create a new paragraph style instance from a `CTParagraphStyle`.
    @objc public class func paragraphStyle(with ctParagraphStyle: CTParagraphStyle) -> CoreTextParagraphStyle {
        return CoreTextParagraphStyle(ctParagraphStyle: ctParagraphStyle)
    }

    /// Create a new paragraph style instance from a `CTParagraphStyle`.
    @objc public init(ctParagraphStyle: CTParagraphStyle) {
        super.init()

        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .alignment, MemoryLayout<CTTextAlignment>.size, &alignment)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .firstLineHeadIndent, MemoryLayout<CGFloat>.size, &firstLineHeadIndent)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .headIndent, MemoryLayout<CGFloat>.size, &headIndent)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .tailIndent, MemoryLayout<CGFloat>.size, &tailIndent)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .paragraphSpacing, MemoryLayout<CGFloat>.size, &paragraphSpacing)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.size, &paragraphSpacingBefore)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .defaultTabInterval, MemoryLayout<CGFloat>.size, &defaultTabInterval)

        var stops: Unmanaged<CFArray>?
        if CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .tabStops, MemoryLayout<Unmanaged<CFArray>?>.size, &stops) {
            if let stopsRef = stops {
                let stopsArray = stopsRef.takeUnretainedValue() as [AnyObject]
                self.tabStops = stopsArray
            }
        }

        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .baseWritingDirection, MemoryLayout<CTWritingDirection>.size, &baseWritingDirection)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .minimumLineHeight, MemoryLayout<CGFloat>.size, &minimumLineHeight)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .maximumLineHeight, MemoryLayout<CGFloat>.size, &maximumLineHeight)
        CTParagraphStyleGetValueForSpecifier(ctParagraphStyle, .lineHeightMultiple, MemoryLayout<CGFloat>.size, &lineHeightMultiple)
    }

    // MARK: - Bridging to/from NSParagraphStyle

    /// Create a new paragraph style instance from an `NSParagraphStyle`.
    @objc(paragraphStyleWithNSParagraphStyle:)
    public class func paragraphStyle(withNSParagraphStyle paragraphStyle: NSParagraphStyle?) -> CoreTextParagraphStyle {
        let ps = paragraphStyle ?? NSParagraphStyle.default

        let retStyle = CoreTextParagraphStyle()

        retStyle.firstLineHeadIndent = ps.firstLineHeadIndent
        retStyle.headIndent = ps.headIndent

        retStyle.paragraphSpacing = ps.paragraphSpacing
        retStyle.paragraphSpacingBefore = ps.paragraphSpacingBefore

        retStyle.lineHeightMultiple = ps.lineHeightMultiple
        retStyle.minimumLineHeight = ps.minimumLineHeight
        retStyle.maximumLineHeight = ps.maximumLineHeight

        retStyle.alignment = Self.ctTextAlignment(from: ps.alignment)

        switch ps.baseWritingDirection {
        case .natural:
            retStyle.baseWritingDirection = .natural
        case .leftToRight:
            retStyle.baseWritingDirection = .leftToRight
        case .rightToLeft:
            retStyle.baseWritingDirection = .rightToLeft
        @unknown default:
            retStyle.baseWritingDirection = .natural
        }

        // Tab stops
        let nsTabStops = ps.tabStops
        var tmpArray = [Any]()

        for textTab in nsTabStops {
            let ctAlignment = Self.ctTextAlignment(from: textTab.alignment)
            let location = textTab.location

            let tab = CTTextTabCreate(ctAlignment, Double(location), nil)
            tmpArray.append(tab)
        }

        if !tmpArray.isEmpty {
            retStyle.tabStops = tmpArray
        }

        retStyle.defaultTabInterval = ps.defaultTabInterval

        return retStyle
    }

    /// Create a CTParagraphStyle from the receiver.
    @objc public func createCTParagraphStyle() -> CTParagraphStyle {
        let stops: CFArray? = _tabStops != nil ? CFArrayCreateCopy(nil, _tabStops! as CFArray) : nil

        var settings = [CTParagraphStyleSetting]()

        withUnsafePointer(to: &alignment) { ptr in
            settings.append(CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: ptr))
        }
        withUnsafePointer(to: &firstLineHeadIndent) { ptr in
            settings.append(CTParagraphStyleSetting(spec: .firstLineHeadIndent, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
        }
        withUnsafePointer(to: &defaultTabInterval) { ptr in
            settings.append(CTParagraphStyleSetting(spec: .defaultTabInterval, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
        }

        // We need to use withExtendedLifetime to keep stops alive
        return withExtendedLifetime(stops) {
            var stopsPtr = stops
            withUnsafePointer(to: &stopsPtr) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .tabStops, valueSize: MemoryLayout<CFArray?>.size, value: ptr))
            }
            withUnsafePointer(to: &paragraphSpacing) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .paragraphSpacing, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }
            withUnsafePointer(to: &paragraphSpacingBefore) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .paragraphSpacingBefore, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }
            withUnsafePointer(to: &headIndent) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .headIndent, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }
            withUnsafePointer(to: &tailIndent) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .tailIndent, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }
            withUnsafePointer(to: &baseWritingDirection) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .baseWritingDirection, valueSize: MemoryLayout<CTWritingDirection>.size, value: ptr))
            }
            withUnsafePointer(to: &lineHeightMultiple) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .lineHeightMultiple, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }
            withUnsafePointer(to: &minimumLineHeight) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }
            withUnsafePointer(to: &maximumLineHeight) { ptr in
                settings.append(CTParagraphStyleSetting(spec: .maximumLineHeight, valueSize: MemoryLayout<CGFloat>.size, value: ptr))
            }

            return CTParagraphStyleCreate(settings, settings.count)
        }
    }

    /// Create a new `NSParagraphStyle` from the receiver.
    @objc public func nsParagraphStyle() -> NSParagraphStyle {
        let mps = NSMutableParagraphStyle()

        mps.firstLineHeadIndent = firstLineHeadIndent
        mps.paragraphSpacing = paragraphSpacing
        mps.paragraphSpacingBefore = paragraphSpacingBefore
        mps.headIndent = headIndent
        mps.tailIndent = tailIndent
        mps.minimumLineHeight = minimumLineHeight
        mps.maximumLineHeight = maximumLineHeight
        mps.lineHeightMultiple = lineHeightMultiple

        mps.alignment = Self.nsTextAlignment(from: alignment)

        switch baseWritingDirection {
        case .natural:
            mps.baseWritingDirection = .natural
        case .leftToRight:
            mps.baseWritingDirection = .leftToRight
        case .rightToLeft:
            mps.baseWritingDirection = .rightToLeft
        @unknown default:
            mps.baseWritingDirection = .natural
        }

        // Tab stops
        if let stops = _tabStops {
            var tabs = [NSTextTab]()

            for object in stops {
                let tab = object as! CTTextTab
                let ctAlignment = CTTextTabGetAlignment(tab)
                let nsAlignment = Self.nsTextAlignment(from: ctAlignment)
                let location = CGFloat(CTTextTabGetLocation(tab))

                let textTab = NSTextTab(textAlignment: nsAlignment, location: location, options: [:])
                tabs.append(textTab)
            }

            if !tabs.isEmpty {
                mps.tabStops = tabs
            }

            mps.defaultTabInterval = defaultTabInterval
        }

        return mps
    }

    // MARK: - Tab Stops

    /// Adds a tab stop to the receiver.
    @objc public func addTabStop(at position: CGFloat, alignment: CTTextAlignment) {
        let tab = CTTextTabCreate(alignment, Double(position), nil)
        if _tabStops == nil {
            _tabStops = NSMutableArray()
        }
        _tabStops!.add(tab)
    }

    // MARK: - CSS Representation

    /// Create a representation suitable for CSS.
    @objc public func cssStyleRepresentation() -> String? {
        var retString = ""

        switch alignment {
        case .left:
            retString.append("text-align:left;")
        case .right:
            retString.append("text-align:right;")
        case .center:
            retString.append("text-align:center;")
        case .justified:
            retString.append("text-align:justify;")
        case .natural:
            break // no output, this is default
        @unknown default:
            break
        }

        if lineHeightMultiple != 0 && lineHeightMultiple != 1.0 {
            let number = NSNumber(value: Double(lineHeightMultiple))
            retString.append("line-height:\(number)em;")
        }

        switch baseWritingDirection {
        case .rightToLeft:
            retString.append("direction:rtl;")
        case .leftToRight:
            retString.append("direction:ltr;")
        case .natural:
            break // no output, this is default
        @unknown default:
            break
        }

        if paragraphSpacing != 0.0 {
            let number = NSNumber(value: Double(paragraphSpacing))
            retString.append("margin-bottom:\(number)px;")
        }

        if paragraphSpacingBefore != 0.0 {
            let number = NSNumber(value: Double(paragraphSpacingBefore))
            retString.append("margin-top:\(number)px;")
        }

        if headIndent != 0.0 {
            let number = NSNumber(value: Double(headIndent))
            retString.append("margin-left:\(number)px;")
        }

        if tailIndent != 0.0 {
            // tail indent is negative if from trailing margin
            let number = NSNumber(value: Double(-tailIndent))
            retString.append("margin-right:\(number)px;")
        }

        return retString.isEmpty ? nil : retString
    }

    // MARK: - NSCopying

    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let newObject = CoreTextParagraphStyle()

        newObject.firstLineHeadIndent = firstLineHeadIndent
        newObject.tailIndent = tailIndent
        newObject.defaultTabInterval = defaultTabInterval
        newObject.paragraphSpacing = paragraphSpacing
        newObject.paragraphSpacingBefore = paragraphSpacingBefore
        newObject.lineHeightMultiple = lineHeightMultiple
        newObject.minimumLineHeight = minimumLineHeight
        newObject.maximumLineHeight = maximumLineHeight
        newObject.headIndent = headIndent
        newObject.alignment = alignment
        newObject.baseWritingDirection = baseWritingDirection
        newObject.tabStops = tabStops
        newObject.textLists = textLists
        newObject.textBlocks = textBlocks

        return newObject
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherStyle = object as? CoreTextParagraphStyle else {
            return false
        }

        if otherStyle === self {
            return true
        }

        if firstLineHeadIndent != otherStyle.firstLineHeadIndent { return false }
        if headIndent != otherStyle.headIndent { return false }
        if tailIndent != otherStyle.tailIndent { return false }
        if defaultTabInterval != otherStyle.defaultTabInterval { return false }
        if paragraphSpacing != otherStyle.paragraphSpacing { return false }
        if paragraphSpacingBefore != otherStyle.paragraphSpacingBefore { return false }
        if lineHeightMultiple != otherStyle.lineHeightMultiple { return false }
        if minimumLineHeight != otherStyle.minimumLineHeight { return false }
        if maximumLineHeight != otherStyle.maximumLineHeight { return false }
        if alignment != otherStyle.alignment { return false }
        if baseWritingDirection != otherStyle.baseWritingDirection { return false }

        if let tl = textLists as NSArray?, !(tl.isEqual(to: otherStyle.textLists ?? [])) {
            return false
        }
        if let tb = textBlocks as NSArray?, !(tb.isEqual(to: otherStyle.textBlocks ?? [])) {
            return false
        }
        if let ts = _tabStops, !(ts.isEqual(to: otherStyle._tabStops ?? NSMutableArray())) {
            return false
        }

        return true
    }

    // MARK: - Alignment Conversion Helpers

    private class func ctTextAlignment(from nsAlignment: NSTextAlignment) -> CTTextAlignment {
        switch nsAlignment {
        case .left: return .left
        case .right: return .right
        case .center: return .center
        case .justified: return .justified
        case .natural: return .natural
        @unknown default: return .natural
        }
    }

    private class func nsTextAlignment(from ctAlignment: CTTextAlignment) -> NSTextAlignment {
        switch ctAlignment {
        case .left: return .left
        case .right: return .right
        case .center: return .center
        case .justified: return .justified
        case .natural: return .natural
        @unknown default: return .natural
        }
    }
}
