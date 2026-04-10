import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Handler block called whenever a text block is encountered during text drawing.
public typealias CoreTextLayoutFrameTextBlockHandler = (TextBlock, CGRect, CGContext, UnsafeMutablePointer<ObjCBool>) -> Void

/// The drawing options for CoreTextLayoutFrame.
@objc(DTCoreTextLayoutFrameDrawingOptions)
public enum CoreTextLayoutFrameDrawingOptions: UInt {
    /// Default method draws links and attachments.
    case `default` = 1
    /// Links are not drawn.
    case omitLinks = 2
    /// Text attachments are omitted from drawing.
    case omitAttachments = 4
    /// Links are displayed highlighted.
    case drawLinksHighlighted = 8
}

/// Global flag for debug frames.
nonisolated(unsafe) private var _shouldDrawDebugFrames = false

/// Represents a single frame of text, wrapping CTFrame. Provides an array of text lines
/// that fit in the given rectangle.
@objc(DTCoreTextLayoutFrame)
open class CoreTextLayoutFrame: NSObject {

    /// The frame rectangle for the layout frame.
    /// Accessing this triggers line building if needed, then adjusts height/width for unknown dimensions.
    @objc open var frame: CGRect {
        get {
            if _lines == nil { _buildLines() }
            _updateFrameSize()
            return _frame
        }
        set { _frame = newValue }
    }
    private var _frame: CGRect = .zero

    private var _lines: [CoreTextLayoutLine]?
    private var _paragraphRanges: [NSValue]?
    private var _textAttachments: [TextAttachment]?
    private var _attributedStringFragment: NSAttributedString?

    private var _textFrame: CTFrame?
    private var _framesetter: CTFramesetter?

    private var _requestedStringRange: NSRange = NSRange(location: 0, length: 0)
    private var _stringRange: NSRange = NSRange(location: 0, length: 0)

    private var _additionalPaddingAtBottom: CGFloat = 0
    private var _numberLinesFitInFrame: Int = 0

    /// Custom handler to be executed before text belonging to a text block is drawn.
    @objc open var textBlockHandler: CoreTextLayoutFrameTextBlockHandler?

    /// The ratio to decide when to create a justified line.
    @objc open var justifyRatio: CGFloat = 0.6

    /// Maximum number of lines to display before truncation. Default is 0 (no limit).
    @objc open var numberOfLines: Int = 0 {
        didSet {
            if numberOfLines != oldValue {
                _lines = nil
                _frame.size.height = CGFLOAT_HEIGHT_UNKNOWN
            }
        }
    }

    /// Line break mode used to indicate how truncation should occur.
    @objc open var lineBreakMode: NSLineBreakMode = .byWordWrapping {
        didSet {
            if lineBreakMode != oldValue {
                _lines = nil
                _frame.size.height = CGFLOAT_HEIGHT_UNKNOWN
            }
        }
    }

    /// Optional attributed string to use as truncation indicator.
    @objc open var truncationString: NSAttributedString? {
        didSet {
            if truncationString != oldValue {
                if numberOfLines > 0 {
                    _lines = nil
                    _frame.size.height = CGFLOAT_HEIGHT_UNKNOWN
                }
            }
        }
    }

    // MARK: - Creating Layout Frames

    /// Creates a Layout Frame with the given frame using the attributed string loaded into the layouter.
    @objc public convenience init?(frame: CGRect, layouter: CoreTextLayouter) {
        self.init(frame: frame, layouter: layouter, range: NSRange(location: 0, length: 0))
    }

    /// Creates a Layout Frame with the given frame, layouter, and range.
    @objc public init?(frame: CGRect, layouter: CoreTextLayouter, range: NSRange) {
        super.init()

        self._frame = frame
        _attributedStringFragment = layouter.attributedString?.mutableCopy() as? NSAttributedString

        guard let fragment = _attributedStringFragment else { return nil }

        _requestedStringRange = range
        let stringLength = fragment.length

        if _requestedStringRange.location >= stringLength { return nil }

        if _requestedStringRange.length == 0 || NSMaxRange(_requestedStringRange) > stringLength {
            _requestedStringRange.length = stringLength - _requestedStringRange.location
        }

        let cfRange = CFRangeMake(_requestedStringRange.location, _requestedStringRange.length)

        guard let framesetter = layouter.framesetter else { return nil }

        _framesetter = framesetter

        let path = CGMutablePath()
        path.addRect(frame)

        _textFrame = CTFramesetterCreateFrame(framesetter, cfRange, path, nil)

        justifyRatio = 0.6
    }

    open override var description: String {
        return lines?.description ?? "[]"
    }

    // MARK: - Positioning Lines

    private func _algorithmLegacy_BaselineOrigin(toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?) -> CGPoint {
        guard let fragment = _attributedStringFragment else { return .zero }
        var lineOrigin = previousLine?.baselineOrigin ?? .zero
        let lineStartIndex = line.stringRange().location

        let lineParagraphStyle = fragment.attribute(.paragraphStyle, at: lineStartIndex, effectiveRange: nil) as! NSParagraphStyle
        let ctStyle = lineParagraphStyle as CFTypeRef as! CTParagraphStyle

        if previousLine == nil {
            if isLineFirst(inParagraph: line) {
                var paraSpacingBefore: CGFloat = 0
                CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.size, &paraSpacingBefore)
                lineOrigin.y += paraSpacingBefore
                lineOrigin.x = line.baselineOrigin.x
                lineOrigin.y = ceil(lineOrigin.y)
                return lineOrigin
            }
        }

        var lineHeight: CGFloat = 0
        var minLineHeight: CGFloat = 0
        var maxLineHeight: CGFloat = 0
        var usesForcedLineHeight = false

        var usedLeading = line.leading
        if usedLeading == 0.0 {
            let tmpHeight = line.ascent + line.descent
            usedLeading = ceil(0.2 * tmpHeight)
            if usedLeading > 20 { usedLeading = 0 }
        } else {
            usedLeading = ceil(max((line.ascent + line.descent) * 0.1, usedLeading))
        }

        CTParagraphStyleGetValueForSpecifier(ctStyle, .minimumLineHeight, MemoryLayout<CGFloat>.size, &minLineHeight)
        if minLineHeight > 0 {
            usesForcedLineHeight = true
            if lineHeight < minLineHeight { lineHeight = minLineHeight }
        }

        if lineHeight == 0 {
            lineHeight = line.descent + line.ascent + usedLeading
        }

        if let previousLine = previousLine, isLineLast(inParagraph: previousLine) {
            let prevStyle = fragment.attribute(.paragraphStyle, at: previousLine.stringRange().location, effectiveRange: nil) as! NSParagraphStyle
            let prevCtStyle = prevStyle as CFTypeRef as! CTParagraphStyle

            var paraSpacing: CGFloat = 0
            CTParagraphStyleGetValueForSpecifier(prevCtStyle, .paragraphSpacing, MemoryLayout<CGFloat>.size, &paraSpacing)
            lineOrigin.y += paraSpacing

            var paraSpacingBefore: CGFloat = 0
            CTParagraphStyleGetValueForSpecifier(ctStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.size, &paraSpacingBefore)
            lineOrigin.y += paraSpacingBefore
        }

        var lineHeightMultiplier: CGFloat = 0
        CTParagraphStyleGetValueForSpecifier(ctStyle, .lineHeightMultiple, MemoryLayout<CGFloat>.size, &lineHeightMultiplier)
        if lineHeightMultiplier > 0 { lineHeight *= lineHeightMultiplier }

        CTParagraphStyleGetValueForSpecifier(ctStyle, .maximumLineHeight, MemoryLayout<CGFloat>.size, &maxLineHeight)
        if maxLineHeight > 0 && lineHeight > maxLineHeight { lineHeight = maxLineHeight }

        lineOrigin.y += lineHeight
        lineOrigin.x = line.baselineOrigin.x

        if !usesForcedLineHeight, let previousLine = previousLine {
            let previousLineBottom = previousLine.frame.maxY
            if lineOrigin.y - line.ascent < previousLineBottom {
                lineOrigin.y = previousLineBottom + line.ascent
            }
        }

        lineOrigin.y = ceil(lineOrigin.y)
        return lineOrigin
    }

    private func _algorithmWebKit_halfLeading(ofLine line: CoreTextLayoutLine) -> CGFloat {
        var maxFontSize = line.lineHeight
        guard let paragraphStyle = line.paragraphStyle else { return 0 }

        if paragraphStyle.minimumLineHeight != 0 && paragraphStyle.minimumLineHeight > maxFontSize {
            maxFontSize = paragraphStyle.minimumLineHeight
        }
        if paragraphStyle.maximumLineHeight != 0 && paragraphStyle.maximumLineHeight < maxFontSize {
            maxFontSize = paragraphStyle.maximumLineHeight
        }

        var leading: CGFloat
        if paragraphStyle.lineHeightMultiple > 0 {
            leading = maxFontSize * paragraphStyle.lineHeightMultiple
        } else {
            leading = maxFontSize * 1.1
        }

        let inlineBoxHeight = line.ascent + line.descent
        return (leading - inlineBoxHeight) / 2.0
    }

    private func _algorithmWebKit_BaselineOrigin(toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?) -> CGPoint {
        var baselineOrigin = previousLine?.baselineOrigin ?? .zero

        if let previousLine = previousLine {
            baselineOrigin.y = previousLine.frame.maxY
            let halfLeading = _algorithmWebKit_halfLeading(ofLine: previousLine)

            if previousLine.attachments != nil {
                if halfLeading > 0 { baselineOrigin.y += halfLeading }
            } else {
                baselineOrigin.y += halfLeading
            }

            if isLineLast(inParagraph: previousLine) {
                if let ps = previousLine.paragraphStyle {
                    baselineOrigin.y += ps.paragraphSpacing
                }
            }
        } else {
            baselineOrigin = _frame.origin
        }

        baselineOrigin.y += line.ascent

        let halfLeading = _algorithmWebKit_halfLeading(ofLine: line)
        if line.attachments != nil {
            if halfLeading > 0 { baselineOrigin.y += halfLeading }
        } else {
            baselineOrigin.y += halfLeading
        }

        if isLineFirst(inParagraph: line) {
            if let ps = line.paragraphStyle {
                baselineOrigin.y += ps.paragraphSpacingBefore
            }
        }

        // add padding for closed text blocks
        if let prevBlocks = previousLine?.textBlocks as? [TextBlock] {
            for prevBlock in prevBlocks {
                if !(line.textBlocks?.contains(prevBlock) ?? false) {
                    baselineOrigin.y += prevBlock.padding.bottom
                }
            }
        }

        // add padding for newly opened text blocks
        if let currBlocks = line.textBlocks as? [TextBlock] {
            for currBlock in currBlocks {
                if !(previousLine?.textBlocks?.contains(currBlock) ?? false) {
                    baselineOrigin.y += currBlock.padding.top
                }
            }
        }

        baselineOrigin.y = ceil(baselineOrigin.y)
        return baselineOrigin
    }

    /// Finds the appropriate baseline origin for a line.
    @objc open func baselineOrigin(toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?, options: DTCoreTextLayoutFrameLinePositioningOptions) -> CGPoint {
        if options.rawValue & DTCoreTextLayoutFrameLinePositioningOptions.algorithmWebKit.rawValue != 0 {
            return _algorithmWebKit_BaselineOrigin(toPositionLine: line, afterLine: previousLine)
        }
        if options.rawValue & DTCoreTextLayoutFrameLinePositioningOptions.algorithmLegacy.rawValue != 0 {
            return _algorithmLegacy_BaselineOrigin(toPositionLine: line, afterLine: previousLine)
        }
        return .zero
    }

    /// Deprecated: use baselineOrigin(toPositionLine:afterLine:options:) instead.
    @objc open func baselineOrigin(toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?) -> CGPoint {
        return baselineOrigin(toPositionLine: line, afterLine: previousLine, options: DTCoreTextLayoutFrameLinePositioningOptions.algorithmWebKit)
    }

    // MARK: - Building Lines

    private func _buildLinesWithTypesetter() {
        guard let framesetter = _framesetter, let fragment = _attributedStringFragment else { return }
        let typesetter = CTFramesetterGetTypesetter(framesetter)

        var typesetLines = [CoreTextLayoutLine]()
        var previousLine: CoreTextLayoutLine? = nil

        var paragraphRanges = (self.paragraphRanges ?? []).map { $0 }
        guard !paragraphRanges.isEmpty else { return }

        var currentParagraphRange = paragraphRanges[0].rangeValue

        var lineRange = _requestedStringRange
        let maxY = _frame.maxY
        let maxIndex = NSMaxRange(_requestedStringRange)
        var fittingLength = 0
        var shouldTruncateLine = false

        repeat {
            while lineRange.location >= currentParagraphRange.location + currentParagraphRange.length {
                paragraphRanges.removeFirst()
                guard !paragraphRanges.isEmpty else { return }
                currentParagraphRange = paragraphRanges[0].rangeValue
            }

            let isAtBeginOfParagraph = (currentParagraphRange.location == lineRange.location)

            var headIndent: CGFloat = 0
            var tailIndent: CGFloat = 0

            let paragraphStyle = fragment.attribute(.paragraphStyle, at: lineRange.location, effectiveRange: nil) as! NSParagraphStyle
            let ctStyle = paragraphStyle as CFTypeRef as! CTParagraphStyle

            if isAtBeginOfParagraph {
                CTParagraphStyleGetValueForSpecifier(ctStyle, .firstLineHeadIndent, MemoryLayout<CGFloat>.size, &headIndent)
            } else {
                CTParagraphStyleGetValueForSpecifier(ctStyle, .headIndent, MemoryLayout<CGFloat>.size, &headIndent)
            }
            CTParagraphStyleGetValueForSpecifier(ctStyle, .tailIndent, MemoryLayout<CGFloat>.size, &tailIndent)

            let textBlocks = fragment.attribute(NSAttributedString.Key(rawValue: DTTextBlocksAttribute), at: lineRange.location, effectiveRange: nil) as? [TextBlock]
            var totalLeftPadding: CGFloat = 0
            var totalRightPadding: CGFloat = 0

            if let textBlocks = textBlocks {
                for block in textBlocks {
                    totalLeftPadding += block.padding.left
                    totalRightPadding += block.padding.right
                }
            }

            var availableSpace: CGFloat
            if tailIndent <= 0 {
                availableSpace = _frame.size.width - headIndent - totalRightPadding + tailIndent - totalLeftPadding
            } else {
                availableSpace = tailIndent - headIndent - totalLeftPadding - totalRightPadding
            }

            var offset = totalLeftPadding
            let lineStartStr = (fragment.string as NSString).substring(with: NSRange(location: lineRange.location, length: 1))
            if lineStartStr != "\t" {
                offset += headIndent
            }

            lineRange.length = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, Double(availableSpace))

            if NSMaxRange(lineRange) > maxIndex {
                lineRange.length = maxIndex - lineRange.location
            }

            shouldTruncateLine = ((numberOfLines > 0 && typesetLines.count + 1 == numberOfLines) || (_numberLinesFitInFrame > 0 && _numberLinesFitInFrame == typesetLines.count + 1))

            var ctLine: CTLine
            var isHyphenatedString = false

            if !shouldTruncateLine {
                let lineString = (fragment.attributedSubstring(from: lineRange).string as NSString)
                let lastChar = lineString.character(at: lineString.length - 1)

                if lastChar == 0x00AD { // soft hyphen
                    let hyphenatedString = fragment.attributedSubstring(from: lineRange).mutableCopy() as! NSMutableAttributedString
                    hyphenatedString.replaceCharacters(in: NSRange(location: hyphenatedString.length - 1, length: 1), with: "-")
                    ctLine = CTLineCreateWithAttributedString(hyphenatedString as CFAttributedString)
                    isHyphenatedString = true
                } else {
                    ctLine = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length))
                }
            } else {
                let oldLineRange = lineRange
                lineRange.length = maxIndex - lineRange.location
                let baseLine = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length))

                let truncationType = DTCTLineTruncationTypeFromNSLineBreakMode(lineBreakMode)

                var attribStr = truncationString
                if attribStr == nil {
                    var index = oldLineRange.location
                    if truncationType == .end {
                        index += max(oldLineRange.length - 1, 0)
                    } else if truncationType == .middle {
                        index += max(oldLineRange.length / 2 - 1, 0)
                    }
                    var range = NSRange()
                    let attributes = fragment.attributes(at: index, effectiveRange: &range)
                    attribStr = NSAttributedString(string: "\u{2026}", attributes: attributes)
                }

                let ellipsisLine = CTLineCreateWithAttributedString(attribStr! as CFAttributedString)

                if let truncatedLine = CTLineCreateTruncatedLine(baseLine, Double(availableSpace), truncationType, ellipsisLine) {
                    ctLine = truncatedLine

                    // check if truncation occurred
                    let truncationOccurred = !areLinesEqual(baseLine, ctLine)
                    let endOfParagraphIndex = NSMaxRange(currentParagraphRange)

                    if truncationType == .end {
                        if truncationOccurred {
                            let truncationIndex = getTruncationIndex(ctLine, ellipsisLine)
                            if truncationIndex > endOfParagraphIndex {
                                let subStr = fragment.attributedSubstring(from: NSRange(location: lineRange.location, length: endOfParagraphIndex - lineRange.location - 1))
                                let attrMutStr = subStr.mutableCopy() as! NSMutableAttributedString
                                attrMutStr.append(attribStr!)
                                ctLine = CTLineCreateWithAttributedString(attrMutStr as CFAttributedString)
                            }
                        } else {
                            if maxIndex != endOfParagraphIndex {
                                let subStr = fragment.attributedSubstring(from: NSRange(location: lineRange.location, length: endOfParagraphIndex - lineRange.location - 1))
                                let attrMutStr = subStr.mutableCopy() as! NSMutableAttributedString
                                attrMutStr.append(attribStr!)
                                ctLine = CTLineCreateWithAttributedString(attrMutStr as CFAttributedString)
                            }
                        }
                    }
                } else {
                    ctLine = baseLine
                }
            }

            let currentLineWidth = CGFloat(CTLineGetTypographicBounds(ctLine, nil, nil, nil))

            // adjust lineOrigin based on paragraph text alignment
            var textAlignment: CTTextAlignment = .natural
            CTParagraphStyleGetValueForSpecifier(ctStyle, .alignment, MemoryLayout<CTTextAlignment>.size, &textAlignment)

            // determine writing direction
            var isRTL = false
            var baseWritingDirection: CTWritingDirection = .natural
            CTParagraphStyleGetValueForSpecifier(ctStyle, .baseWritingDirection, MemoryLayout<CTWritingDirection>.size, &baseWritingDirection)
            isRTL = (baseWritingDirection == .rightToLeft)

            var lineOriginX: CGFloat

            switch textAlignment {
            case .left:
                lineOriginX = _frame.origin.x + offset
            case .natural:
                lineOriginX = _frame.origin.x + offset
                if baseWritingDirection == .rightToLeft {
                    lineOriginX = _frame.origin.x + offset + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(availableSpace)))
                }
            case .right:
                lineOriginX = _frame.origin.x + offset + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(availableSpace)))
            case .center:
                lineOriginX = _frame.origin.x + offset + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 0.5, Double(availableSpace)))
            case .justified:
                let isAtEndOfParagraph = (currentParagraphRange.location + currentParagraphRange.length <= lineRange.location + lineRange.length ||
                    (fragment.string as NSString).character(at: lineRange.location + lineRange.length - 1) == 0x2028)

                if !isAtEndOfParagraph && currentLineWidth > justifyRatio * _frame.size.width {
                    if let justifiedLine = CTLineCreateJustifiedLine(ctLine, 1.0, Double(availableSpace)) {
                        ctLine = justifiedLine
                    }
                }

                if isRTL {
                    lineOriginX = _frame.origin.x + offset + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(availableSpace)))
                } else {
                    lineOriginX = _frame.origin.x + offset
                }
            @unknown default:
                lineOriginX = _frame.origin.x + offset
            }

            guard let newLine = CoreTextLayoutLine(line: ctLine, stringLocationOffset: isHyphenatedString ? lineRange.location : 0) else {
                lineRange.location += lineRange.length
                continue
            }
            newLine.writingDirectionIsRightToLeft = isRTL

            var newLineBaselineOrigin = _algorithmWebKit_BaselineOrigin(toPositionLine: newLine, afterLine: previousLine)
            newLineBaselineOrigin.x = lineOriginX
            newLine.baselineOrigin = newLineBaselineOrigin

            var lineBottom = newLine.frame.maxY
            if let textBlocks = newLine.textBlocks as? [TextBlock], let first = textBlocks.first {
                lineBottom += first.padding.bottom
            }

            if lineBottom > maxY {
                if !typesetLines.isEmpty && lineBreakMode != .byWordWrapping {
                    _numberLinesFitInFrame = typesetLines.count
                    _buildLinesWithTypesetter()
                    return
                } else {
                    break
                }
            }

            typesetLines.append(newLine)
            fittingLength += lineRange.length
            lineRange.location += lineRange.length
            previousLine = newLine
        } while lineRange.location < maxIndex && !shouldTruncateLine

        _lines = typesetLines

        if typesetLines.isEmpty {
            _stringRange = NSRange(location: 0, length: 0)
            return
        }

        _stringRange.location = _requestedStringRange.location
        _stringRange.length = fittingLength

        if _frame.size.height == CGFLOAT_HEIGHT_UNKNOWN, let lastLine = _lines?.last {
            var totalPadding: CGFloat = 0
            if let blocks = lastLine.textBlocks as? [TextBlock] {
                for block in blocks { totalPadding += block.padding.bottom }
            }
            _additionalPaddingAtBottom = totalPadding
        }
    }

    private func _buildLines() {
        guard _frame.size.width > 0 else { return }
        _buildLinesWithTypesetter()
    }

    // MARK: - Lines

    /// The text lines that belong to the receiver.
    @objc open var lines: NSArray? {
        if _lines == nil { _buildLines() }
        return _lines as NSArray?
    }

    /// The text lines visible inside the given rectangle.
    @objc open func linesVisible(in rect: CGRect) -> [CoreTextLayoutLine] {
        guard let lines = _lines ?? { _buildLines(); return _lines }() else { return [] }
        var tmpArray = [CoreTextLayoutLine]()
        let minY = rect.minY
        let maxY = rect.maxY

        for oneLine in lines {
            let lineFrame = oneLine.frame
            if lineFrame.maxY < minY { continue }
            if lineFrame.origin.y > maxY { break }

            var adjustedFrame = lineFrame
            adjustedFrame.size.width = max(adjustedFrame.size.width, 1)
            if adjustedFrame.intersects(rect) {
                tmpArray.append(oneLine)
            }
        }
        return tmpArray
    }

    /// The text lines fully contained inside the given rectangle.
    @objc open func linesContained(in rect: CGRect) -> [CoreTextLayoutLine] {
        guard let lines = _lines ?? { _buildLines(); return _lines }() else { return [] }
        var tmpArray = [CoreTextLayoutLine]()
        let minY = rect.minY
        let maxY = rect.maxY

        for oneLine in lines {
            let lineFrame = oneLine.frame
            if lineFrame.maxY < minY { continue }
            if lineFrame.origin.y > maxY { break }
            if rect.contains(lineFrame) { tmpArray.append(oneLine) }
        }
        return tmpArray
    }

    /// The layout line that contains the given string index.
    @objc open func lineContaining(index: UInt) -> CoreTextLayoutLine? {
        guard let lines = self.lines as? [CoreTextLayoutLine] else { return nil }
        for oneLine in lines {
            if NSLocationInRange(Int(index), oneLine.stringRange()) { return oneLine }
        }
        return nil
    }

    /// Determines if the given line is the first in a paragraph.
    @objc open func isLineFirst(inParagraph line: CoreTextLayoutLine) -> Bool {
        let lineRange = line.stringRange()
        if lineRange.location == 0 { return true }
        guard let fragment = _attributedStringFragment else { return false }
        let prevChar = (fragment.string as NSString).character(at: lineRange.location - 1)
        return CharacterSet.newlines.contains(Unicode.Scalar(prevChar)!)
    }

    /// Determines if the given line is the last in a paragraph.
    @objc open func isLineLast(inParagraph line: CoreTextLayoutLine) -> Bool {
        guard let fragment = _attributedStringFragment else { return false }
        let lineString = (fragment.string as NSString).substring(with: line.stringRange())
        return lineString.hasSuffix("\n")
    }

    // MARK: - Text Block Helpers

    /// Determines the frame to use for a text block with a given effective range
    /// at a specific block nesting level.
    private func _blockFrame(forEffectiveRange effectiveRange: NSRange, level: Int) -> CGRect {
        guard let allLines = self.lines as? [CoreTextLayoutLine],
              let screenFirstLine = allLines.first,
              let screenLastLine = allLines.last else {
            return .zero
        }

        // Bail out if the effective range is entirely off-screen
        if NSMaxRange(screenLastLine.stringRange()) <= effectiveRange.location ||
            screenFirstLine.stringRange().location >= NSMaxRange(effectiveRange) {
            return .zero
        }

        // Find the first/last lines of this block
        let firstBlockLine = self.lineContaining(index: UInt(effectiveRange.location))
        let lastBlockLine = self.lineContaining(index: UInt(max(NSMaxRange(effectiveRange) - 1, effectiveRange.location)))

        var blockFrame = CGRect.zero
        blockFrame.origin = firstBlockLine?.frame.origin ?? _frame.origin
        blockFrame.origin.x = _frame.origin.x
        blockFrame.size.width = _frame.size.width

        if let lastBlockLine {
            blockFrame.size.height = lastBlockLine.frame.maxY - blockFrame.origin.y
        } else {
            blockFrame.size.height = _frame.maxY - blockFrame.origin.y
        }

        // Add top padding from nested blocks in the first line
        if let textBlocks = firstBlockLine?.textBlocks as? [TextBlock] {
            var i = textBlocks.count - 1
            while i >= level {
                let oneBlock = textBlocks[i]
                blockFrame.origin.y -= oneBlock.padding.top
                blockFrame.size.height += oneBlock.padding.top
                i -= 1
            }
        }

        // Add bottom padding from nested blocks in the last line
        if let textBlocks = lastBlockLine?.textBlocks as? [TextBlock] {
            var i = textBlocks.count - 1
            while i >= level {
                let oneBlock = textBlocks[i]
                blockFrame.size.height += oneBlock.padding.bottom
                i -= 1
            }
        }

        // Shrink left/right by the outer blocks' horizontal padding
        if let textBlocks = firstBlockLine?.textBlocks as? [TextBlock] {
            for i in 0..<min(level, textBlocks.count) {
                let outerBlock = textBlocks[i]
                blockFrame.origin.x += outerBlock.padding.left
                blockFrame.size.width -= (outerBlock.padding.left + outerBlock.padding.right)
            }
        }

        return blockFrame.integral
    }

    /// Enumerates text blocks at a single nesting level within the given range.
    /// - Returns: `true` if at least one block was found at this level.
    private func _enumerateTextBlocks(
        atLevel level: Int,
        inRange range: NSRange,
        using block: (TextBlock, CGRect, NSRange, inout Bool) -> Void
    ) -> Bool {
        guard let fragment = _attributedStringFragment else { return false }
        let length = fragment.length
        var index = range.location
        var foundBlockAtLevel = false

        while index < NSMaxRange(range) {
            var textBlocksArrayRange = NSRange(location: 0, length: 0)
            let textBlocks = fragment.attribute(
                NSAttributedString.Key(rawValue: DTTextBlocksAttribute),
                at: index,
                longestEffectiveRange: &textBlocksArrayRange,
                in: range
            ) as? [TextBlock]

            index += textBlocksArrayRange.length

            guard let textBlocks, textBlocks.count > level else { continue }

            foundBlockAtLevel = true

            let blockAtLevelToHandle = textBlocks[level]
            var searchIndex = NSMaxRange(textBlocksArrayRange)
            var currentBlockEffectiveRange = textBlocksArrayRange

            // Search forward for the end of this specific block
            while searchIndex < length && searchIndex < NSMaxRange(range) {
                var laterBlocksRange = NSRange(location: 0, length: 0)
                let laterBlocks = fragment.attribute(
                    NSAttributedString.Key(rawValue: DTTextBlocksAttribute),
                    at: searchIndex,
                    longestEffectiveRange: &laterBlocksRange,
                    in: range
                ) as? [TextBlock]

                if laterBlocks?.contains(blockAtLevelToHandle) != true {
                    break
                }

                currentBlockEffectiveRange = NSUnionRange(currentBlockEffectiveRange, laterBlocksRange)
                searchIndex = NSMaxRange(laterBlocksRange)
            }

            index = searchIndex
            let blockFrame = _blockFrame(forEffectiveRange: currentBlockEffectiveRange, level: level)

            var shouldStop = false
            block(blockAtLevelToHandle, blockFrame, currentBlockEffectiveRange, &shouldStop)
            if shouldStop { return true }
        }

        return foundBlockAtLevel
    }

    /// Enumerates all text blocks (at all nesting levels) within the given range.
    private func _enumerateTextBlocks(
        inRange range: NSRange,
        using block: (TextBlock, CGRect, NSRange, inout Bool) -> Void
    ) {
        var level = 0
        while _enumerateTextBlocks(atLevel: level, inRange: range, using: block) {
            level += 1
        }
    }

    /// Draws the background / borders of visible text blocks into the context.
    private func _drawTextBlocks(in context: CGContext, range: NSRange) {
        let clipRect = context.boundingBoxOfClipPath

        _enumerateTextBlocks(inRange: range) { textBlock, frame, _, _ in
            let visiblePart = frame.intersection(clipRect)
            if visiblePart.isNull { return }
            _drawTextBlock(textBlock, in: context, frame: frame)
        }
    }

    // MARK: - Drawing

    private func _drawTextBlock(_ textBlock: TextBlock, in context: CGContext, frame blockFrame: CGRect) {
        var shouldDrawStandardBackground: ObjCBool = true
        textBlockHandler?(textBlock, blockFrame, context, &shouldDrawStandardBackground)

        if shouldDrawStandardBackground.boolValue {
            if let bgColor = textBlock.backgroundColor {
                context.setFillColor(bgColor.cgColor)
                context.fill(blockFrame)
            }
        }

        if _shouldDrawDebugFrames {
            context.saveGState()
            context.setStrokeColor(red: 0.5, green: 0, blue: 0.5, alpha: 1.0)
            context.setLineWidth(2)
            context.stroke(blockFrame.insetBy(dx: 2, dy: 2))
            context.restoreGState()
        }
    }

    /// Draws the receiver into the given graphics context.
    @objc open func draw(in context: CGContext, options: UInt) {
        let drawLinks = (options & CoreTextLayoutFrameDrawingOptions.omitLinks.rawValue) == 0
        let _ = (options & CoreTextLayoutFrameDrawingOptions.omitAttachments.rawValue) == 0 // drawImages currently unused; attachments are drawn via subviews

        let rect = context.boundingBoxOfClipPath

        // Swift manages CF type lifetimes automatically
        let _ = _textFrame // ensure retained for scope

        if _shouldDrawDebugFrames {
            context.saveGState()

            // stroke the frame because the layout frame might be open ended
            context.saveGState()
            let dashes: [CGFloat] = [10.0, 2.0]
            context.setLineDash(phase: 0, lengths: dashes)
            context.stroke(self.frame)

            // draw center line
            context.move(to: CGPoint(x: self.frame.midX, y: self.frame.origin.y))
            context.addLine(to: CGPoint(x: self.frame.midX, y: self.frame.maxY))
            context.strokePath()

            context.restoreGState()

            // stroke the clip rect in semi-transparent red
            context.setStrokeColor(red: 1, green: 0, blue: 0, alpha: 0.5)
            context.stroke(rect)

            context.restoreGState()
        }

        let visibleLines = linesVisible(in: rect)
        guard !visibleLines.isEmpty else { return }

        // Draw the background / borders of any visible text blocks below the
        // text. The block range only needs to span the visible lines.
        if let fragment = _attributedStringFragment, fragment.length > 0 {
            let firstLine = visibleLines.first!
            let lastLine = visibleLines.last!
            let blockRangeStart = firstLine.stringRange().location
            let blockRangeEnd = NSMaxRange(lastLine.stringRange())
            let blockRange = NSRange(location: blockRangeStart, length: blockRangeEnd - blockRangeStart)
            _drawTextBlocks(in: context, range: blockRange)
        }

        context.saveGState()

        #if canImport(UIKit)
        UIGraphicsPushContext(context)
        #elseif canImport(AppKit)
        let gc = NSGraphicsContext(cgContext: context, flipped: true)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gc
        #endif

        // draw decorations
        for oneLine in visibleLines {
            if oneLine.isHorizontalRule() { continue }
            guard let runs = oneLine.glyphRuns as? [CoreTextGlyphRun] else { continue }

            if _shouldDrawDebugFrames {
                // line bounds (blue) and baseline
                context.setStrokeColor(red: 0, green: 0, blue: 1, alpha: 1)
                context.stroke(oneLine.frame)

                context.move(to: CGPoint(x: oneLine.baselineOrigin.x - 5, y: oneLine.baselineOrigin.y))
                context.addLine(to: CGPoint(x: oneLine.baselineOrigin.x + oneLine.frame.size.width + 5, y: oneLine.baselineOrigin.y))
                context.strokePath()

                // alternating red/green fills on each glyph run
                var runIndex = 0
                for oneRun in runs {
                    guard rect.intersects(oneRun.frame) else { continue }
                    if runIndex % 2 == 0 {
                        context.setFillColor(red: 1, green: 0, blue: 0, alpha: 0.2)
                    } else {
                        context.setFillColor(red: 0, green: 1, blue: 0, alpha: 0.2)
                    }
                    context.fill(oneRun.frame)
                    runIndex += 1
                }
            }

            for oneRun in runs {
                guard rect.intersects(oneRun.frame) else { continue }
                if !drawLinks && oneRun.isHyperlink { continue }
                if oneRun.attachment != nil { continue }
                if oneRun.isTrailingWhitespace() { continue }

                // set foreground color
                let color = (oneRun.attributes as? [NSAttributedString.Key: Any])?.dtct_foregroundColor()
                if let color = color {
                    context.setStrokeColor(color.cgColor)
                }

                oneRun.drawDecoration(in: context)
            }
        }

        // Flip the coordinate system
        context.textMatrix = .identity
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0, y: -self.frame.size.height)

        // draw glyphs
        for oneLine in visibleLines {
            guard let runs = oneLine.glyphRuns as? [CoreTextGlyphRun] else { continue }

            for oneRun in runs {
                guard rect.intersects(oneRun.frame) else { continue }
                if !drawLinks && oneRun.isHyperlink { continue }

                var textPosition = CGPoint(x: oneLine.frame.origin.x, y: self.frame.size.height - oneRun.frame.origin.y - oneRun.ascent)

                let superscriptStyle = (oneRun.attributes[NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)] as? NSNumber)?.intValue ?? 0

                switch superscriptStyle {
                case 1:
                    textPosition.y += oneRun.ascent * 0.47
                case -1:
                    textPosition.y -= oneRun.ascent * 0.25
                default:
                    break
                }

                if let baselineOffset = (oneRun.attributes as? [NSAttributedString.Key: Any])?[.baselineOffset] as? NSNumber {
                    textPosition.y += CGFloat(baselineOffset.floatValue)
                }

                context.textPosition = textPosition

                if oneRun.attachment == nil {
                    oneRun.draw(in: context)
                }
            }
        }

        #if canImport(UIKit)
        UIGraphicsPopContext()
        #elseif canImport(AppKit)
        NSGraphicsContext.restoreGraphicsState()
        #endif

        context.restoreGState()
    }

    /// Deprecated draw method.
    @objc open func draw(in context: CGContext, drawImages: Bool, drawLinks: Bool) {
        var options: UInt = CoreTextLayoutFrameDrawingOptions.default.rawValue
        if !drawImages { options |= CoreTextLayoutFrameDrawingOptions.omitAttachments.rawValue }
        if !drawLinks { options |= CoreTextLayoutFrameDrawingOptions.omitLinks.rawValue }
        draw(in: context, options: options)
    }

    // MARK: - Text Attachments

    /// The array of all text attachments that belong to the receiver.
    @objc open func textAttachments() -> [TextAttachment] {
        if _textAttachments == nil {
            var tmpAttachments = [TextAttachment]()
            guard let lines = self.lines as? [CoreTextLayoutLine] else { return [] }
            for oneLine in lines {
                guard let runs = oneLine.glyphRuns as? [CoreTextGlyphRun] else { continue }
                for oneRun in runs {
                    if let attachment = oneRun.attachment { tmpAttachments.append(attachment) }
                }
            }
            _textAttachments = tmpAttachments
        }
        return _textAttachments ?? []
    }

    /// The array of all text attachments matching the specified predicate.
    @objc(textAttachmentsWithPredicate:)
    open func textAttachments(with predicate: NSPredicate) -> [TextAttachment] {
        return (textAttachments() as NSArray).filtered(using: predicate) as? [TextAttachment] ?? []
    }

    // MARK: - Calculations

    /// The string range that is visible (fits into the given rectangle).
    @objc open func visibleStringRange() -> NSRange {
        guard _textFrame != nil else { return NSRange(location: 0, length: 0) }
        if _lines == nil { _buildLines() }
        return _stringRange
    }

    /// An array that maps glyphs with string indices.
    @objc open func stringIndices() -> [NSNumber] {
        var array = [NSNumber]()
        guard let lines = self.lines as? [CoreTextLayoutLine] else { return array }
        for oneLine in lines {
            array.append(contentsOf: oneLine.stringIndices())
        }
        return array
    }

    /// Retrieves the index of the text line that contains the given glyph index.
    @objc open func lineIndex(forGlyphIndex index: Int) -> Int {
        var idx = index
        var retIndex = 0
        guard let lines = self.lines as? [CoreTextLayoutLine] else { return 0 }
        for oneLine in lines {
            let count = oneLine.numberOfGlyphs()
            if idx >= count { idx -= count } else { return retIndex }
            retIndex += 1
        }
        return retIndex
    }

    /// Retrieves the frame of the glyph at the given glyph index.
    @objc open func frameOfGlyph(at index: Int) -> CGRect {
        var idx = index
        guard let lines = self.lines as? [CoreTextLayoutLine] else { return .null }
        for oneLine in lines {
            let count = oneLine.numberOfGlyphs()
            if idx >= count { idx -= count } else { return oneLine.frameOfGlyph(at: idx) }
        }
        return .null
    }

    /// Calculates the frame that is covered by the text content.
    @objc open func intrinsicContentFrame() -> CGRect {
        if _lines == nil { _buildLines() }
        guard let lines = _lines, !lines.isEmpty else { return .zero }

        let outerFrame = self.frame
        var frameOverAllLines = lines[0].frame
        frameOverAllLines.origin.y = outerFrame.origin.y

        for oneLine in lines {
            let frame = oneLine.frame.intersection(outerFrame)
            frameOverAllLines = frameOverAllLines.union(frame)
        }

        frameOverAllLines.size.height = ceil(frameOverAllLines.size.height + 1.5 + _additionalPaddingAtBottom)
        return frameOverAllLines.integral
    }

    /// The attributed string fragment.
    @objc open func attributedStringFragment() -> NSAttributedString? {
        return _attributedStringFragment
    }

    // MARK: - Paragraphs

    /// The paragraph ranges.
    @objc open var paragraphRanges: [NSValue]? {
        if _paragraphRanges == nil {
            guard let plainString = _attributedStringFragment?.string as NSString? else { return nil }
            let length = plainString.length

            var tmpArray = [NSValue]()
            var paragraphRange = plainString.rangeOfParagraphsContaining(NSRange(location: 0, length: 0), parBegIndex: nil, parEndIndex: nil)

            while paragraphRange.length > 0 {
                tmpArray.append(NSValue(range: paragraphRange))
                let nextBegin = NSMaxRange(paragraphRange)
                if nextBegin >= length { break }
                paragraphRange = plainString.rangeOfParagraphsContaining(NSRange(location: nextBegin, length: 0), parBegIndex: nil, parEndIndex: nil)
            }

            _paragraphRanges = tmpArray
        }
        return _paragraphRanges
    }

    /// Finding which paragraph a given string index belongs to.
    @objc open func paragraphIndex(containingStringIndex stringIndex: UInt) -> UInt {
        guard let ranges = paragraphRanges else { return UInt(NSNotFound) }
        for (idx, value) in ranges.enumerated() {
            let range = value.rangeValue
            if NSLocationInRange(Int(stringIndex), range) { return UInt(idx) }
        }
        return UInt(NSNotFound)
    }

    /// Determines the paragraph range encompassing the given string range.
    @objc open func paragraphRange(containingStringRange stringRange: NSRange) -> NSRange {
        let firstParagraphIndex = paragraphIndex(containingStringIndex: UInt(stringRange.location))
        var lastParagraphIndex: UInt

        if stringRange.length > 0 {
            lastParagraphIndex = paragraphIndex(containingStringIndex: UInt(NSMaxRange(stringRange) - 1))
        } else {
            lastParagraphIndex = firstParagraphIndex
        }

        return NSRange(location: Int(firstParagraphIndex), length: Int(lastParagraphIndex - firstParagraphIndex + 1))
    }

    /// The text lines that belong to the specified paragraph.
    @objc open func linesInParagraph(at index: UInt) -> [CoreTextLayoutLine]? {
        guard let ranges = paragraphRanges, Int(index) < ranges.count else { return nil }
        let range = ranges[Int(index)].rangeValue
        guard let lines = self.lines as? [CoreTextLayoutLine] else { return nil }

        var tmpArray = [CoreTextLayoutLine]()
        var insideParagraph = false
        for oneLine in lines {
            if NSLocationInRange(oneLine.stringRange().location, range) {
                insideParagraph = true
                tmpArray.append(oneLine)
            } else if insideParagraph {
                break
            }
        }
        return tmpArray.isEmpty ? nil : tmpArray
    }

    // MARK: - Debugging

    /// Switches on the debug drawing mode.
    @objc public class func setShouldDrawDebugFrames(_ debugFrames: Bool) {
        _shouldDrawDebugFrames = debugFrames
    }

    /// Returns the current value of the debug frame drawing.
    @objc public class func shouldDrawDebugFrames() -> Bool {
        return _shouldDrawDebugFrames
    }
}

// Extension to compute the frame property correctly
extension CoreTextLayoutFrame {

    private func _updateFrameSize() {
        guard let lines = _lines, !lines.isEmpty else { return }

        if _frame.size.height == CGFLOAT_HEIGHT_UNKNOWN {
            if let lastLine = lines.last {
                _frame.size.height = ceil(lastLine.frame.maxY - _frame.origin.y + 1.5 + _additionalPaddingAtBottom)
            }
        }

        if _frame.size.width == CGFLOAT_WIDTH_UNKNOWN {
            var maxWidth: CGFloat = 0
            for oneLine in lines {
                let lineWidthFromFrameOrigin = oneLine.frame.maxX - _frame.origin.x
                maxWidth = max(maxWidth, lineWidthFromFrameOrigin)
            }
            _frame.size.width = ceil(maxWidth)
        }
    }
}
