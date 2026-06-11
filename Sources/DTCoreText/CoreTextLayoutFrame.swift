import CoreText
import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Handler block called whenever a text block is encountered during text drawing.
public typealias CoreTextLayoutFrameTextBlockHandler = (
  TextBlock, CGRect, CGContext, UnsafeMutablePointer<ObjCBool>
) -> Void

import os

/// Global flag for debug frames, protected by an unfair lock for thread safety.
private let _debugFrames = OSAllocatedUnfairLock(initialState: false)

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
  private var _textAttachments: [NSTextAttachment]?
  private var _attributedStringFragment: NSAttributedString?

  private var _textFrame: CTFrame?
  private var _framesetter: CTFramesetter?

  private var _requestedStringRange: NSRange = NSRange(location: 0, length: 0)
  private var _stringRange: NSRange = NSRange(location: 0, length: 0)

  private var _additionalPaddingAtBottom: CGFloat = 0
  private var _numberLinesFitInFrame: Int = 0

  // table layout results: border-box rects of cells/tables in text coordinates
  private var _tableBlockFrames = [ObjectIdentifier: CGRect]()
  private var _tablesInDrawOrder = [(table: TextTable, rect: CGRect, level: Int)]()
  private var _maxTableBottom: CGFloat = 0

  // border edges not to draw (bitmask by edge raw value), from collapsed-border
  // resolution: only the winning border of each boundary is drawn
  private var _suppressedBorderEdges = [ObjectIdentifier: UInt]()

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

  private func _algorithmLegacy_BaselineOrigin(
    toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?
  ) -> CGPoint {
    guard let fragment = _attributedStringFragment else { return .zero }
    var lineOrigin = previousLine?.baselineOrigin ?? .zero
    let lineStartIndex = line.stringRange().location

    let lineParagraphStyle =
      fragment.attribute(.paragraphStyle, at: lineStartIndex, effectiveRange: nil)
      as! NSParagraphStyle
    let ctStyle = lineParagraphStyle as CFTypeRef as! CTParagraphStyle

    if previousLine == nil {
      if isLineFirst(inParagraph: line) {
        var paraSpacingBefore: CGFloat = 0
        CTParagraphStyleGetValueForSpecifier(
          ctStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.size, &paraSpacingBefore)
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

    CTParagraphStyleGetValueForSpecifier(
      ctStyle, .minimumLineHeight, MemoryLayout<CGFloat>.size, &minLineHeight)
    if minLineHeight > 0 {
      usesForcedLineHeight = true
      if lineHeight < minLineHeight { lineHeight = minLineHeight }
    }

    if lineHeight == 0 {
      lineHeight = line.descent + line.ascent + usedLeading
    }

    if let previousLine = previousLine, isLineLast(inParagraph: previousLine) {
      let prevStyle =
        fragment.attribute(
          .paragraphStyle, at: previousLine.stringRange().location, effectiveRange: nil)
        as! NSParagraphStyle
      let prevCtStyle = prevStyle as CFTypeRef as! CTParagraphStyle

      var paraSpacing: CGFloat = 0
      CTParagraphStyleGetValueForSpecifier(
        prevCtStyle, .paragraphSpacing, MemoryLayout<CGFloat>.size, &paraSpacing)
      lineOrigin.y += paraSpacing

      var paraSpacingBefore: CGFloat = 0
      CTParagraphStyleGetValueForSpecifier(
        ctStyle, .paragraphSpacingBefore, MemoryLayout<CGFloat>.size, &paraSpacingBefore)
      lineOrigin.y += paraSpacingBefore
    }

    var lineHeightMultiplier: CGFloat = 0
    CTParagraphStyleGetValueForSpecifier(
      ctStyle, .lineHeightMultiple, MemoryLayout<CGFloat>.size, &lineHeightMultiplier)
    if lineHeightMultiplier > 0 { lineHeight *= lineHeightMultiplier }

    CTParagraphStyleGetValueForSpecifier(
      ctStyle, .maximumLineHeight, MemoryLayout<CGFloat>.size, &maxLineHeight)
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

  private func _algorithmWebKit_BaselineOrigin(
    toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?
  ) -> CGPoint {
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

    // blocks are grouped by instance identity: equal-but-distinct blocks
    // (e.g. adjacent table cells with the same styling) are separate blocks
    let lineBlocks = line.textBlocks as? [TextBlock] ?? []
    let previousLineBlocks = previousLine?.textBlocks as? [TextBlock] ?? []

    // add padding for closed text blocks
    for prevBlock in previousLineBlocks {
      if !lineBlocks.contains(where: { $0 === prevBlock }) {
        baselineOrigin.y += prevBlock.padding.bottom
      }
    }

    // add padding for newly opened text blocks
    for currBlock in lineBlocks {
      if !previousLineBlocks.contains(where: { $0 === currBlock }) {
        baselineOrigin.y += currBlock.padding.top
      }
    }

    baselineOrigin.y = ceil(baselineOrigin.y)
    return baselineOrigin
  }

  /// Finds the appropriate baseline origin for a line.
  @objc open func baselineOrigin(
    toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?,
    options: DTCoreTextLayoutFrameLinePositioningOptions
  ) -> CGPoint {
    if options.rawValue & DTCoreTextLayoutFrameLinePositioningOptions.algorithmWebKit.rawValue != 0
    {
      return _algorithmWebKit_BaselineOrigin(toPositionLine: line, afterLine: previousLine)
    }
    if options.rawValue & DTCoreTextLayoutFrameLinePositioningOptions.algorithmLegacy.rawValue != 0
    {
      return _algorithmLegacy_BaselineOrigin(toPositionLine: line, afterLine: previousLine)
    }
    return .zero
  }

  /// Deprecated: use baselineOrigin(toPositionLine:afterLine:options:) instead.
  @objc open func baselineOrigin(
    toPositionLine line: CoreTextLayoutLine, afterLine previousLine: CoreTextLayoutLine?
  ) -> CGPoint {
    return baselineOrigin(
      toPositionLine: line, afterLine: previousLine,
      options: DTCoreTextLayoutFrameLinePositioningOptions.algorithmWebKit)
  }

  // MARK: - Building Lines

  private func _buildLinesWithTypesetter() {
    guard let framesetter = _framesetter, let fragment = _attributedStringFragment else { return }
    let typesetter = CTFramesetterGetTypesetter(framesetter)

    _tableBlockFrames.removeAll()
    _tablesInDrawOrder.removeAll()
    _maxTableBottom = 0
    _suppressedBorderEdges.removeAll()

    var typesetLines = [CoreTextLayoutLine]()
    var previousLine: CoreTextLayoutLine? = nil
    var minimumBaselineYAfterTable: CGFloat? = nil

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

      // a table starting at this paragraph is laid out as a grid in one go
      if isAtBeginOfParagraph, let tableStart = _tableStart(at: lineRange.location) {
        let tableTop: CGFloat
        if let previousLine {
          tableTop =
            previousLine.frame.maxY + (previousLine.paragraphStyle?.paragraphSpacing ?? 0)
        } else {
          tableTop = _frame.origin.y
        }

        let result = _layoutTable(
          tableStart.block.table,
          level: tableStart.level,
          startingAt: lineRange.location,
          availableWidth: _frame.size.width,
          originX: _frame.origin.x,
          topY: tableTop,
          maximumY: maxY,
          mustConsumeFirstRow: typesetLines.isEmpty)

        if result.range.length > 0 {
          typesetLines.append(contentsOf: result.lines)
          _registerTableLayoutResult(result)
          minimumBaselineYAfterTable = result.bottomY

          fittingLength += result.range.length
          lineRange.location = NSMaxRange(result.range)
          previousLine = result.lines.last ?? previousLine

          if result.isPartial {
            // the remaining rows belong to a continuation frame
            break
          }
          continue
        }

        if result.scannedLength > 0 {
          // a table starts here but not even its first row fits into the
          // remaining space — it goes entirely to a continuation frame
          break
        }
        // no cells found: treat the content as normal text below
      }

      var headIndent: CGFloat = 0
      var tailIndent: CGFloat = 0

      let paragraphStyle =
        fragment.attribute(.paragraphStyle, at: lineRange.location, effectiveRange: nil)
        as! NSParagraphStyle
      let ctStyle = paragraphStyle as CFTypeRef as! CTParagraphStyle

      if isAtBeginOfParagraph {
        CTParagraphStyleGetValueForSpecifier(
          ctStyle, .firstLineHeadIndent, MemoryLayout<CGFloat>.size, &headIndent)
      } else {
        CTParagraphStyleGetValueForSpecifier(
          ctStyle, .headIndent, MemoryLayout<CGFloat>.size, &headIndent)
      }
      CTParagraphStyleGetValueForSpecifier(
        ctStyle, .tailIndent, MemoryLayout<CGFloat>.size, &tailIndent)

      let textBlocks =
        fragment.attribute(
          NSAttributedString.Key(rawValue: DTTextBlocksAttribute), at: lineRange.location,
          effectiveRange: nil) as? [TextBlock]
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
        availableSpace =
          _frame.size.width - headIndent - totalRightPadding + tailIndent - totalLeftPadding
      } else {
        availableSpace = tailIndent - headIndent - totalLeftPadding - totalRightPadding
      }

      var offset = totalLeftPadding
      let lineStartStr = (fragment.string as NSString).substring(
        with: NSRange(location: lineRange.location, length: 1))
      if lineStartStr != "\t" {
        offset += headIndent
      }

      lineRange.length = CTTypesetterSuggestLineBreak(
        typesetter, lineRange.location, Double(availableSpace))

      if NSMaxRange(lineRange) > maxIndex {
        lineRange.length = maxIndex - lineRange.location
      }

      shouldTruncateLine =
        ((numberOfLines > 0 && typesetLines.count + 1 == numberOfLines)
          || (_numberLinesFitInFrame > 0 && _numberLinesFitInFrame == typesetLines.count + 1))

      var ctLine: CTLine
      var isHyphenatedString = false

      if !shouldTruncateLine {
        let lineString = (fragment.attributedSubstring(from: lineRange).string as NSString)
        let lastChar = lineString.character(at: lineString.length - 1)

        if lastChar == 0x00AD {  // soft hyphen
          let hyphenatedString =
            fragment.attributedSubstring(from: lineRange).mutableCopy()
            as! NSMutableAttributedString
          hyphenatedString.replaceCharacters(
            in: NSRange(location: hyphenatedString.length - 1, length: 1), with: "-")
          ctLine = CTLineCreateWithAttributedString(hyphenatedString as CFAttributedString)
          isHyphenatedString = true
        } else {
          ctLine = CTTypesetterCreateLine(
            typesetter, CFRangeMake(lineRange.location, lineRange.length))
        }
      } else {
        let oldLineRange = lineRange
        lineRange.length = maxIndex - lineRange.location
        let baseLine = CTTypesetterCreateLine(
          typesetter, CFRangeMake(lineRange.location, lineRange.length))

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

        if let truncatedLine = CTLineCreateTruncatedLine(
          baseLine, Double(availableSpace), truncationType, ellipsisLine)
        {
          ctLine = truncatedLine

          // check if truncation occurred
          let truncationOccurred = !areLinesEqual(baseLine, ctLine)
          let endOfParagraphIndex = NSMaxRange(currentParagraphRange)

          if truncationType == .end {
            if truncationOccurred {
              let truncationIndex = getTruncationIndex(ctLine, ellipsisLine)
              if truncationIndex > endOfParagraphIndex {
                let subStr = fragment.attributedSubstring(
                  from: NSRange(
                    location: lineRange.location,
                    length: endOfParagraphIndex - lineRange.location - 1))
                let attrMutStr = subStr.mutableCopy() as! NSMutableAttributedString
                attrMutStr.append(attribStr!)
                ctLine = CTLineCreateWithAttributedString(attrMutStr as CFAttributedString)
              }
            } else {
              if maxIndex != endOfParagraphIndex {
                let subStr = fragment.attributedSubstring(
                  from: NSRange(
                    location: lineRange.location,
                    length: endOfParagraphIndex - lineRange.location - 1))
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
      CTParagraphStyleGetValueForSpecifier(
        ctStyle, .alignment, MemoryLayout<CTTextAlignment>.size, &textAlignment)

      // determine writing direction
      var isRTL = false
      var baseWritingDirection: CTWritingDirection = .natural
      CTParagraphStyleGetValueForSpecifier(
        ctStyle, .baseWritingDirection, MemoryLayout<CTWritingDirection>.size, &baseWritingDirection
      )
      isRTL = (baseWritingDirection == .rightToLeft)

      var lineOriginX: CGFloat

      switch textAlignment {
      case .left:
        lineOriginX = _frame.origin.x + offset
      case .natural:
        lineOriginX = _frame.origin.x + offset
        if baseWritingDirection == .rightToLeft {
          lineOriginX =
            _frame.origin.x + offset
            + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(availableSpace)))
        }
      case .right:
        lineOriginX =
          _frame.origin.x + offset
          + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(availableSpace)))
      case .center:
        lineOriginX =
          _frame.origin.x + offset
          + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 0.5, Double(availableSpace)))
      case .justified:
        let isAtEndOfParagraph =
          (currentParagraphRange.location + currentParagraphRange.length <= lineRange.location
            + lineRange.length
            || (fragment.string as NSString).character(
              at: lineRange.location + lineRange.length - 1) == 0x2028)

        if !isAtEndOfParagraph && currentLineWidth > justifyRatio * _frame.size.width {
          if let justifiedLine = CTLineCreateJustifiedLine(ctLine, 1.0, Double(availableSpace)) {
            ctLine = justifiedLine
          }
        }

        if isRTL {
          lineOriginX =
            _frame.origin.x + offset
            + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(availableSpace)))
        } else {
          lineOriginX = _frame.origin.x + offset
        }
      @unknown default:
        lineOriginX = _frame.origin.x + offset
      }

      guard
        let newLine = CoreTextLayoutLine(
          line: ctLine, stringLocationOffset: isHyphenatedString ? lineRange.location : 0)
      else {
        lineRange.location += lineRange.length
        continue
      }
      newLine.writingDirectionIsRightToLeft = isRTL

      var newLineBaselineOrigin = _algorithmWebKit_BaselineOrigin(
        toPositionLine: newLine, afterLine: previousLine)

      // following a table, flow continues below the table's lowest cell
      if let minimumY = minimumBaselineYAfterTable {
        newLineBaselineOrigin.y = max(newLineBaselineOrigin.y, ceil(minimumY + newLine.ascent))
        minimumBaselineYAfterTable = nil
      }

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
    guard
      let lines = _lines
        ?? {
          _buildLines()
          return _lines
        }()
    else { return [] }
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
    guard
      let lines = _lines
        ?? {
          _buildLines()
          return _lines
        }()
    else { return [] }
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
      let screenLastLine = allLines.last
    else {
      return .zero
    }

    // Bail out if the effective range is entirely off-screen
    if NSMaxRange(screenLastLine.stringRange()) <= effectiveRange.location
      || screenFirstLine.stringRange().location >= NSMaxRange(effectiveRange)
    {
      return .zero
    }

    // Find the first/last lines of this block
    let firstBlockLine = self.lineContaining(index: UInt(effectiveRange.location))
    let lastBlockLine = self.lineContaining(
      index: UInt(max(NSMaxRange(effectiveRange) - 1, effectiveRange.location)))

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
      let textBlocks =
        fragment.attribute(
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
        let laterBlocks =
          fragment.attribute(
            NSAttributedString.Key(rawValue: DTTextBlocksAttribute),
            at: searchIndex,
            longestEffectiveRange: &laterBlocksRange,
            in: range
          ) as? [TextBlock]

        // compare by identity: a different-but-equal block ends this block's range
        if laterBlocks?.contains(where: { $0 === blockAtLevelToHandle }) != true {
          break
        }

        currentBlockEffectiveRange = NSUnionRange(currentBlockEffectiveRange, laterBlocksRange)
        searchIndex = NSMaxRange(laterBlocksRange)
      }

      index = searchIndex

      // table cells have grid-computed frames; other blocks derive theirs from lines
      let blockFrame =
        _tableBlockFrames[ObjectIdentifier(blockAtLevelToHandle)]
        ?? _blockFrame(forEffectiveRange: currentBlockEffectiveRange, level: level)

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
  ///
  /// Levels are drawn outermost-first; the background of a table is drawn right before
  /// the blocks of its own level so that nested tables paint above outer cells.
  private func _drawTextBlocks(in context: CGContext, range: NSRange) {
    let clipRect = context.boundingBoxOfClipPath
    if _lines == nil { _buildLines() }

    var level = 0

    while true {
      let tablesAtLevel = _tablesInDrawOrder.filter { $0.level == level }

      for entry in tablesAtLevel where !entry.rect.intersection(clipRect).isNull {
        _drawTextBlock(entry.table, in: context, frame: entry.rect)
      }

      let foundBlocks = _enumerateTextBlocks(atLevel: level, inRange: range) {
        textBlock, frame, _, _ in
        let visiblePart = frame.intersection(clipRect)
        if visiblePart.isNull { return }
        _drawTextBlock(textBlock, in: context, frame: frame)
      }

      if !foundBlocks && tablesAtLevel.isEmpty {
        break
      }

      level += 1
    }
  }

  // MARK: - Drawing

  private func _drawTextBlock(
    _ textBlock: TextBlock, in context: CGContext, frame blockFrame: CGRect
  ) {
    var shouldDrawStandardBackground: ObjCBool = true
    textBlockHandler?(textBlock, blockFrame, context, &shouldDrawStandardBackground)

    if shouldDrawStandardBackground.boolValue {
      if let bgColor = textBlock.backgroundColor {
        context.setFillColor(bgColor.cgColor)
        context.fill(blockFrame)
      }

      // borders: filled strips inside each edge of the border box
      let edgeStrips: [(CGRectEdge, CGRect)] = [
        (
          .minYEdge,
          CGRect(
            x: blockFrame.minX, y: blockFrame.minY, width: blockFrame.width,
            height: textBlock.width(for: .border, edge: .minYEdge))
        ),
        (
          .maxYEdge,
          CGRect(
            x: blockFrame.minX,
            y: blockFrame.maxY - textBlock.width(for: .border, edge: .maxYEdge),
            width: blockFrame.width, height: textBlock.width(for: .border, edge: .maxYEdge))
        ),
        (
          .minXEdge,
          CGRect(
            x: blockFrame.minX, y: blockFrame.minY,
            width: textBlock.width(for: .border, edge: .minXEdge), height: blockFrame.height)
        ),
        (
          .maxXEdge,
          CGRect(
            x: blockFrame.maxX - textBlock.width(for: .border, edge: .maxXEdge),
            y: blockFrame.minY, width: textBlock.width(for: .border, edge: .maxXEdge),
            height: blockFrame.height)
        ),
      ]

      let suppressedEdgesMask = _suppressedBorderEdges[ObjectIdentifier(textBlock)] ?? 0

      for (edge, strip) in edgeStrips where !strip.isEmpty {
        if suppressedEdgesMask & (1 << UInt(edge.rawValue)) != 0 { continue }

        let borderColor = textBlock.borderColor(for: edge) ?? DTColor.black
        let borderStyle = textBlock.borderStyle(for: edge)
        let isHorizontal = (edge == .minYEdge || edge == .maxYEdge)
        let borderWidth = isHorizontal ? strip.height : strip.width

        switch borderStyle {
        case .solid:
          context.setFillColor(borderColor.cgColor)
          context.fill(strip)

        case .double:
          // two lines of one third each with a gap between them
          context.setFillColor(borderColor.cgColor)
          let third = borderWidth / 3
          if isHorizontal {
            context.fill(CGRect(x: strip.minX, y: strip.minY, width: strip.width, height: third))
            context.fill(
              CGRect(x: strip.minX, y: strip.maxY - third, width: strip.width, height: third))
          } else {
            context.fill(CGRect(x: strip.minX, y: strip.minY, width: third, height: strip.height))
            context.fill(
              CGRect(x: strip.maxX - third, y: strip.minY, width: third, height: strip.height))
          }

        case .dashed, .dotted:
          context.saveGState()
          context.setStrokeColor(borderColor.cgColor)
          context.setLineWidth(borderWidth)
          context.setLineCap(.butt)

          let dashLengths: [CGFloat] =
            borderStyle == .dotted
            ? [borderWidth, borderWidth]
            : [borderWidth * 3, borderWidth * 3]
          context.setLineDash(phase: 0, lengths: dashLengths)

          if isHorizontal {
            context.move(to: CGPoint(x: strip.minX, y: strip.midY))
            context.addLine(to: CGPoint(x: strip.maxX, y: strip.midY))
          } else {
            context.move(to: CGPoint(x: strip.midX, y: strip.minY))
            context.addLine(to: CGPoint(x: strip.midX, y: strip.maxY))
          }

          context.strokePath()
          context.restoreGState()
        }
      }
    }

    if _debugFrames.withLock({ $0 }) {
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
    let _ = (options & CoreTextLayoutFrameDrawingOptions.omitAttachments.rawValue) == 0  // drawImages currently unused; attachments are drawn via subviews

    let rect = context.boundingBoxOfClipPath

    // Swift manages CF type lifetimes automatically
    let _ = _textFrame  // ensure retained for scope

    if _debugFrames.withLock({ $0 }) {
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

      if _debugFrames.withLock({ $0 }) {
        // line bounds (blue) and baseline
        context.setStrokeColor(red: 0, green: 0, blue: 1, alpha: 1)
        context.stroke(oneLine.frame)

        context.move(to: CGPoint(x: oneLine.baselineOrigin.x - 5, y: oneLine.baselineOrigin.y))
        context.addLine(
          to: CGPoint(
            x: oneLine.baselineOrigin.x + oneLine.frame.size.width + 5, y: oneLine.baselineOrigin.y)
        )
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

        var textPosition = CGPoint(
          x: oneLine.frame.origin.x,
          y: self.frame.size.height - oneRun.frame.origin.y - oneRun.ascent)

        let superscriptStyle =
          (oneRun.attributes[
            NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)] as? NSNumber)?
          .intValue ?? 0

        switch superscriptStyle {
        case 1:
          textPosition.y += oneRun.ascent * 0.47
        case -1:
          textPosition.y -= oneRun.ascent * 0.25
        default:
          break
        }

        if let baselineOffset = (oneRun.attributes as? [NSAttributedString.Key: Any])?[
          .baselineOffset] as? NSNumber
        {
          textPosition.y += CGFloat(baselineOffset.floatValue)
        }

        context.textPosition = textPosition

        if oneRun.attachment == nil {
          // If the run was built with
          // kCTForegroundColorFromContextAttributeName = true (the anchor
          // element sets this when a link-highlight color exists so the
          // highlight color can be swapped at draw time), CTRunDraw will
          // ignore the run's own foreground color attribute and use the
          // current fill color of the context instead. We therefore have
          // to push the run's own foreground color onto the context so
          // the link text draws in the expected color rather than the
          // default black.
          let foregroundFromContext =
            (oneRun.attributes[
              NSAttributedString.Key(
                rawValue: kCTForegroundColorFromContextAttributeName as String)]
            as? NSNumber)?.boolValue ?? false

          if foregroundFromContext,
            let runColor = (oneRun.attributes as? [NSAttributedString.Key: Any])?
              .dtct_foregroundColor()
          {
            context.saveGState()
            context.setFillColor(runColor.cgColor)
            oneRun.draw(in: context)
            context.restoreGState()
          } else {
            oneRun.draw(in: context)
          }
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
  ///
  /// Any `NSTextAttachment` (including the DTCoreText `TextAttachment`
  /// subclass) encountered on a glyph run is included.
  @objc open func textAttachments() -> [NSTextAttachment] {
    if _textAttachments == nil {
      var tmpAttachments = [NSTextAttachment]()
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
  open func textAttachments(with predicate: NSPredicate) -> [NSTextAttachment] {
    return (textAttachments() as NSArray).filtered(using: predicate) as? [NSTextAttachment] ?? []
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

    frameOverAllLines.size.height = ceil(
      frameOverAllLines.size.height + 1.5 + _additionalPaddingAtBottom)
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
      var paragraphRange = plainString.rangeOfParagraphsContaining(
        NSRange(location: 0, length: 0), parBegIndex: nil, parEndIndex: nil)

      while paragraphRange.length > 0 {
        tmpArray.append(NSValue(range: paragraphRange))
        let nextBegin = NSMaxRange(paragraphRange)
        if nextBegin >= length { break }
        paragraphRange = plainString.rangeOfParagraphsContaining(
          NSRange(location: nextBegin, length: 0), parBegIndex: nil, parEndIndex: nil)
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

    return NSRange(
      location: Int(firstParagraphIndex), length: Int(lastParagraphIndex - firstParagraphIndex + 1))
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
    _debugFrames.withLock { $0 = debugFrames }
  }

  /// Returns the current value of the debug frame drawing.
  @objc public class func shouldDrawDebugFrames() -> Bool {
    _debugFrames.withLock { $0 }
  }
}

// Extension to compute the frame property correctly
extension CoreTextLayoutFrame {

  // MARK: - Table Layout

  private struct _TableStart {
    let block: TextTableBlock
    let level: Int
  }

  private struct _TableLayoutResult {
    var lines = [CoreTextLayoutLine]()
    var cellFrames = [(block: TextBlock, rect: CGRect, level: Int)]()
    var tableFrames = [(table: TextTable, rect: CGRect, level: Int)]()
    var suppressedBorderEdges = [ObjectIdentifier: UInt]()
    var bottomY: CGFloat = 0
    /// The string range consumed by this frame — trimmed when only part of the
    /// table fits (`isPartial`), zero-length when no row fits at all.
    var range = NSRange(location: 0, length: 0)
    /// The full extent of the table found at the start location, regardless of fit.
    var scannedLength = 0
    /// True when rows were cut off because they exceed the frame's maximum Y;
    /// the remaining rows belong to a continuation frame.
    var isPartial = false
  }

  private func _textBlocks(at location: Int) -> [TextBlock]? {
    guard let fragment = _attributedStringFragment, location < fragment.length else { return nil }
    return fragment.attribute(
      NSAttributedString.Key(rawValue: DTTextBlocksAttribute), at: location, effectiveRange: nil)
      as? [TextBlock]
  }

  /// The outermost table block at the given location, if any.
  private func _tableStart(at location: Int) -> _TableStart? {
    return _tableStart(at: location, atOrDeeperThan: 0)
  }

  /// The first table block at or after the given nesting level, for tables nested
  /// inside cells (or inside other blocks).
  private func _tableStart(at location: Int, atOrDeeperThan level: Int) -> _TableStart? {
    guard let blocks = _textBlocks(at: location), blocks.count > level else { return nil }

    for index in level..<blocks.count {
      if let tableBlock = blocks[index] as? TextTableBlock {
        return _TableStart(block: tableBlock, level: index)
      }
    }

    return nil
  }

  private func _registerTableLayoutResult(_ result: _TableLayoutResult) {
    for entry in result.cellFrames {
      _tableBlockFrames[ObjectIdentifier(entry.block)] = entry.rect
    }

    _tablesInDrawOrder.append(contentsOf: result.tableFrames)
    _suppressedBorderEdges.merge(result.suppressedBorderEdges) { $0 | $1 }
    _maxTableBottom = max(_maxTableBottom, result.bottomY)
  }

  private func _horizontalBoxExtras(of block: TextBlock) -> CGFloat {
    return block.width(for: .padding, edge: .minXEdge) + block.width(for: .padding, edge: .maxXEdge)
      + block.width(for: .border, edge: .minXEdge) + block.width(for: .border, edge: .maxXEdge)
      + block.width(for: .margin, edge: .minXEdge) + block.width(for: .margin, edge: .maxXEdge)
  }

  /// The widest single-line width of the paragraphs in the given range, used as the
  /// natural (content-determined) width during automatic column sizing. A nested table
  /// counts as one unbreakable unit as wide as the sum of its natural column widths.
  private func _naturalContentWidth(ofParagraphsIn range: NSRange, level: Int) -> CGFloat {
    guard let framesetter = _framesetter, let fragment = _attributedStringFragment else {
      return 0
    }

    let typesetter = CTFramesetterGetTypesetter(framesetter)
    let nsString = fragment.string as NSString

    var maxWidth: CGFloat = 0
    var location = range.location

    while location < NSMaxRange(range) {
      if let nested = _tableStart(at: location, atOrDeeperThan: level) {
        let (nestedWidth, nestedRange) = _naturalTableWidth(
          nested.block.table, level: nested.level, startingAt: location)

        if nestedRange.length > 0 {
          maxWidth = max(maxWidth, nestedWidth)
          location = NSMaxRange(nestedRange)
          continue
        }
      }

      let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
      let usableLength =
        min(NSMaxRange(paragraphRange), NSMaxRange(range)) - paragraphRange.location

      if usableLength > 0 {
        let line = CTTypesetterCreateLine(
          typesetter, CFRangeMake(paragraphRange.location, usableLength))
        let width = CGFloat(
          CTLineGetTypographicBounds(line, nil, nil, nil)
            - CTLineGetTrailingWhitespaceWidth(line))
        maxWidth = max(maxWidth, width)
      }

      location = NSMaxRange(paragraphRange)
    }

    return maxWidth
  }

  /// The natural width of a whole table: the sum of its columns' natural widths plus
  /// the table's own box extras. Used when a table is nested inside a cell.
  private func _naturalTableWidth(_ table: TextTable, level: Int, startingAt location: Int)
    -> (width: CGFloat, range: NSRange)
  {
    guard let fragment = _attributedStringFragment else {
      return (0, NSRange(location: location, length: 0))
    }

    let nsString = fragment.string as NSString
    var cells = [(block: TextTableBlock, range: NSRange)]()
    var scanLocation = location

    while scanLocation < fragment.length {
      let paragraphRange = nsString.paragraphRange(for: NSRange(location: scanLocation, length: 0))

      guard let blocks = _textBlocks(at: paragraphRange.location),
        blocks.count > level,
        let cellBlock = blocks[level] as? TextTableBlock,
        cellBlock.table === table
      else { break }

      if let lastIndex = cells.indices.last, cells[lastIndex].block === cellBlock {
        cells[lastIndex].range = NSUnionRange(cells[lastIndex].range, paragraphRange)
      } else {
        cells.append((cellBlock, paragraphRange))
      }

      scanLocation = NSMaxRange(paragraphRange)
    }

    let scannedRange = NSRange(location: location, length: scanLocation - location)
    guard !cells.isEmpty else { return (0, scannedRange) }

    let columnCount = max(
      table.numberOfColumns, cells.map { $0.block.startingColumn + $0.block.columnSpan }.max() ?? 0)
    guard columnCount > 0 else { return (0, scannedRange) }

    var columnWidths = [CGFloat](repeating: 0, count: columnCount)

    for (cellBlock, cellRange) in cells
    where cellBlock.columnSpan == 1 && cellBlock.startingColumn < columnCount {
      let extras = _horizontalBoxExtras(of: cellBlock)
      var natural: CGFloat

      let widthValue = cellBlock.value(for: .width)
      if widthValue > 0, cellBlock.valueType(for: .width) == .absoluteValueType {
        natural = widthValue + extras
      } else {
        natural = _naturalContentWidth(ofParagraphsIn: cellRange, level: level + 1) + extras
      }

      columnWidths[cellBlock.startingColumn] = max(
        columnWidths[cellBlock.startingColumn], natural)
    }

    let tableExtras =
      table.width(for: .margin, edge: .minXEdge) + table.width(for: .margin, edge: .maxXEdge)
      + table.width(for: .border, edge: .minXEdge) + table.width(for: .border, edge: .maxXEdge)
      + table.width(for: .padding, edge: .minXEdge) + table.width(for: .padding, edge: .maxXEdge)

    return (columnWidths.reduce(0, +) + tableExtras, scannedRange)
  }

  /// Resolves the grid column widths for a table: explicit widths (absolute or
  /// percentage) win, otherwise content-measured natural widths, scaled to fit the
  /// table's explicit width or the available width. This is a simplified version of
  /// the automatic/fixed algorithms documented for the system classes.
  private func _resolveColumnWidths(
    for table: TextTable, cells: [(block: TextTableBlock, range: NSRange)], columnCount: Int,
    innerAvailableWidth: CGFloat, level: Int
  ) -> [CGFloat] {
    var explicitTableWidth: CGFloat = 0
    let tableWidthValue = table.value(for: .width)

    if tableWidthValue > 0 {
      switch table.valueType(for: .width) {
      case .percentageValueType:
        explicitTableWidth = innerAvailableWidth * tableWidthValue / 100
      case .absoluteValueType:
        explicitTableWidth = min(tableWidthValue, innerAvailableWidth)
      }
    }

    let baseWidth = explicitTableWidth > 0 ? explicitTableWidth : innerAvailableWidth
    let usesFixedLayout = (table.layoutAlgorithm == .fixedLayoutAlgorithm)

    var specifiedWidths = [CGFloat](repeating: 0, count: columnCount)
    var naturalWidths = [CGFloat](repeating: 0, count: columnCount)

    for (cellBlock, cellRange) in cells {
      guard cellBlock.columnSpan == 1, cellBlock.startingColumn < columnCount else { continue }
      if usesFixedLayout && cellBlock.startingRow > 0 { continue }

      let column = cellBlock.startingColumn
      let extras = _horizontalBoxExtras(of: cellBlock)

      var specified: CGFloat = 0
      let widthValue = cellBlock.value(for: .width)

      if widthValue > 0 {
        switch cellBlock.valueType(for: .width) {
        case .percentageValueType:
          specified = baseWidth * widthValue / 100
        case .absoluteValueType:
          specified = widthValue + extras
        }
      }

      let minimumWidth = cellBlock.value(for: .minimumWidth)
      if minimumWidth > 0, cellBlock.valueType(for: .minimumWidth) == .absoluteValueType {
        specified = max(specified, minimumWidth + extras)
      }

      if specified > 0 {
        specifiedWidths[column] = max(specifiedWidths[column], specified)
      }

      if !usesFixedLayout && specified == 0 {
        var natural = _naturalContentWidth(ofParagraphsIn: cellRange, level: level + 1) + extras

        let maximumWidth = cellBlock.value(for: .maximumWidth)
        if maximumWidth > 0, cellBlock.valueType(for: .maximumWidth) == .absoluteValueType {
          natural = min(natural, maximumWidth + extras)
        }

        naturalWidths[column] = max(naturalWidths[column], min(natural, baseWidth))
      }
    }

    if usesFixedLayout {
      // fixed layout: the first row's widths decide; remaining space is shared equally
      var widths = [CGFloat](repeating: 0, count: columnCount)
      var remaining = baseWidth
      var unspecifiedColumns = 0

      for column in 0..<columnCount {
        if specifiedWidths[column] > 0 {
          widths[column] = specifiedWidths[column]
          remaining -= widths[column]
        } else {
          unspecifiedColumns += 1
        }
      }

      if unspecifiedColumns > 0 {
        let share = max(remaining, 0) / CGFloat(unspecifiedColumns)
        for column in 0..<columnCount where widths[column] == 0 {
          widths[column] = share
        }
      } else if remaining > 0 {
        let share = remaining / CGFloat(columnCount)
        for column in 0..<columnCount {
          widths[column] += share
        }
      }

      return widths
    }

    // an explicit width wins over the content's natural width — content wraps instead
    var preferredWidths = [CGFloat](repeating: 0, count: columnCount)
    for column in 0..<columnCount {
      preferredWidths[column] =
        specifiedWidths[column] > 0 ? specifiedWidths[column] : naturalWidths[column]
    }

    // distribute the needs of spanning cells over their columns
    for (cellBlock, cellRange) in cells where cellBlock.columnSpan > 1 {
      let firstColumn = cellBlock.startingColumn
      let lastColumn = min(firstColumn + cellBlock.columnSpan, columnCount) - 1
      guard firstColumn <= lastColumn else { continue }

      let extras = _horizontalBoxExtras(of: cellBlock)
      let needed = min(
        _naturalContentWidth(ofParagraphsIn: cellRange, level: level + 1) + extras, baseWidth)
      let current = preferredWidths[firstColumn...lastColumn].reduce(0, +)

      if needed > current {
        let addition = (needed - current) / CGFloat(lastColumn - firstColumn + 1)
        for column in firstColumn...lastColumn {
          preferredWidths[column] += addition
        }
      }
    }

    // columns without any sizing information (e.g. only empty cells) collapse to a
    // small minimum, like shrink-to-fit tables in browsers
    let fallbackShare = min(baseWidth / CGFloat(columnCount), 16)
    for column in 0..<columnCount where preferredWidths[column] <= 0 {
      preferredWidths[column] = fallbackShare
    }

    let total = preferredWidths.reduce(0, +)
    guard total > 0 else {
      return [CGFloat](repeating: baseWidth / CGFloat(columnCount), count: columnCount)
    }

    if explicitTableWidth > 0 {
      // columns with explicit widths keep them; the leftover is distributed over the
      // flexible columns proportionally to their preferred (content) width
      var widths = [CGFloat](repeating: 0, count: columnCount)
      var specifiedTotal: CGFloat = 0
      var flexibleColumns = [Int]()

      for column in 0..<columnCount {
        if specifiedWidths[column] > 0 {
          widths[column] = specifiedWidths[column]
          specifiedTotal += specifiedWidths[column]
        } else {
          flexibleColumns.append(column)
        }
      }

      let remaining = explicitTableWidth - specifiedTotal

      if flexibleColumns.isEmpty || remaining <= 0 {
        // only specified columns (or over-constrained): scale to fit exactly
        let scaleBase = specifiedTotal > 0 ? specifiedTotal : 1
        let factor = explicitTableWidth / scaleBase
        return widths.map { $0 * factor }
      }

      let flexiblePreferredTotal = flexibleColumns.reduce(0 as CGFloat) {
        $0 + preferredWidths[$1]
      }

      for column in flexibleColumns {
        if flexiblePreferredTotal > 0 {
          widths[column] = remaining * (preferredWidths[column] / flexiblePreferredTotal)
        } else {
          widths[column] = remaining / CGFloat(flexibleColumns.count)
        }
      }

      return widths
    }

    if total > innerAvailableWidth {
      let factor = innerAvailableWidth / total
      return preferredWidths.map { $0 * factor }
    }

    // shrink-to-fit: a table without explicit width is only as wide as its content
    return preferredWidths
  }

  /// Lays out one table (and recursively any nested tables) as a grid of cells.
  /// Lines are returned in string order with final positions; cell and table frames
  /// are border-box rects for background/border drawing.
  private func _layoutTable(
    _ table: TextTable, level: Int, startingAt location: Int, availableWidth: CGFloat,
    originX: CGFloat, topY: CGFloat, maximumY: CGFloat = .greatestFiniteMagnitude,
    mustConsumeFirstRow: Bool = true
  ) -> _TableLayoutResult {
    var result = _TableLayoutResult()

    guard let fragment = _attributedStringFragment else { return result }
    let nsString = fragment.string as NSString

    // 1. collect the cells and their string ranges (contiguous paragraphs per cell)
    var cells = [(block: TextTableBlock, range: NSRange)]()
    var scanLocation = location
    let stringLength = fragment.length

    while scanLocation < stringLength {
      let paragraphRange = nsString.paragraphRange(for: NSRange(location: scanLocation, length: 0))

      guard let blocks = _textBlocks(at: paragraphRange.location),
        blocks.count > level,
        let cellBlock = blocks[level] as? TextTableBlock,
        cellBlock.table === table
      else { break }

      if let lastIndex = cells.indices.last, cells[lastIndex].block === cellBlock {
        cells[lastIndex].range = NSUnionRange(cells[lastIndex].range, paragraphRange)
      } else {
        cells.append((cellBlock, paragraphRange))
      }

      scanLocation = NSMaxRange(paragraphRange)
    }

    guard !cells.isEmpty else { return result }

    result.range = NSRange(location: location, length: scanLocation - location)
    result.scannedLength = scanLocation - location

    // 2. the table's own box
    let marginLeft = table.width(for: .margin, edge: .minXEdge)
    let marginRight = table.width(for: .margin, edge: .maxXEdge)
    let marginTop = table.width(for: .margin, edge: .minYEdge)
    let marginBottom = table.width(for: .margin, edge: .maxYEdge)
    let edgeLeft =
      table.width(for: .border, edge: .minXEdge) + table.width(for: .padding, edge: .minXEdge)
    let edgeRight =
      table.width(for: .border, edge: .maxXEdge) + table.width(for: .padding, edge: .maxXEdge)
    let edgeTop =
      table.width(for: .border, edge: .minYEdge) + table.width(for: .padding, edge: .minYEdge)
    let edgeBottom =
      table.width(for: .border, edge: .maxYEdge) + table.width(for: .padding, edge: .maxYEdge)

    let innerAvailableWidth = max(
      availableWidth - marginLeft - marginRight - edgeLeft - edgeRight, 10)

    let columnCount = max(
      table.numberOfColumns, cells.map { $0.block.startingColumn + $0.block.columnSpan }.max() ?? 0)

    guard columnCount > 0 else { return result }

    // 3. column widths
    let columnWidths = _resolveColumnWidths(
      for: table, cells: cells, columnCount: columnCount,
      innerAvailableWidth: innerAvailableWidth, level: level)
    let gridWidth = columnWidths.reduce(0, +)

    // 4. lay out every cell's content with relative y starting at 0
    struct CellLayout {
      var block: TextTableBlock
      var flow: _TableLayoutResult
      var borderBoxX: CGFloat
      var borderBoxWidth: CGFloat
      var contentInsetTop: CGFloat
      var contentInsetBottom: CGFloat
      var contentHeight: CGFloat
    }

    let gridLeft = originX + marginLeft + edgeLeft
    var cellLayouts = [CellLayout]()

    for (cellBlock, cellRange) in cells {
      let columnX = gridLeft + columnWidths[0..<cellBlock.startingColumn].reduce(0, +)
      let spanEnd = min(cellBlock.startingColumn + cellBlock.columnSpan, columnCount)
      let spanWidth = columnWidths[cellBlock.startingColumn..<spanEnd].reduce(0, +)

      let cellMarginLeft = cellBlock.width(for: .margin, edge: .minXEdge)
      let cellMarginRight = cellBlock.width(for: .margin, edge: .maxXEdge)
      let borderBoxX = columnX + cellMarginLeft
      let borderBoxWidth = max(spanWidth - cellMarginLeft - cellMarginRight, 1)

      let insetLeft =
        cellBlock.width(for: .border, edge: .minXEdge)
        + cellBlock.width(for: .padding, edge: .minXEdge)
      let insetRight =
        cellBlock.width(for: .border, edge: .maxXEdge)
        + cellBlock.width(for: .padding, edge: .maxXEdge)
      let insetTop =
        cellBlock.width(for: .border, edge: .minYEdge)
        + cellBlock.width(for: .padding, edge: .minYEdge)
      let insetBottom =
        cellBlock.width(for: .border, edge: .maxYEdge)
        + cellBlock.width(for: .padding, edge: .maxYEdge)

      let contentWidth = max(borderBoxWidth - insetLeft - insetRight, 1)
      let contentX = borderBoxX + insetLeft

      let flow = _layoutFlow(
        range: cellRange, level: level + 1, width: contentWidth, originX: contentX, topY: 0)

      cellLayouts.append(
        CellLayout(
          block: cellBlock, flow: flow, borderBoxX: borderBoxX, borderBoxWidth: borderBoxWidth,
          contentInsetTop: insetTop, contentInsetBottom: insetBottom,
          contentHeight: flow.bottomY))
    }

    // 5. row slot heights (cell border box plus its vertical margins fill the slot)
    let rowCount = cells.map { $0.block.startingRow + $0.block.rowSpan }.max() ?? 1
    var rowHeights = [CGFloat](repeating: 0, count: rowCount)

    // baseline-aligned cells of one row align at the baseline of their first line
    // (NSTextBlockVerticalAlignment documentation); the row baseline is the lowest
    // first baseline measured from the slot top
    var rowFirstBaselines = [CGFloat](repeating: 0, count: rowCount)

    func relativeFirstBaseline(of layout: CellLayout) -> CGFloat {
      return layout.flow.lines.first?.baselineOrigin.y ?? 0
    }

    func baselineInset(of layout: CellLayout) -> CGFloat {
      // distance from slot top to the cell's natural first baseline
      return layout.block.width(for: .margin, edge: .minYEdge) + layout.contentInsetTop
        + relativeFirstBaseline(of: layout)
    }

    for layout in cellLayouts
    where layout.block.verticalAlignment == .baselineAlignment && layout.block.rowSpan == 1 {
      let row = layout.block.startingRow
      guard row < rowCount else { continue }
      rowFirstBaselines[row] = max(rowFirstBaselines[row], baselineInset(of: layout))
    }

    for layout in cellLayouts where layout.block.rowSpan == 1 {
      let row = layout.block.startingRow
      guard row < rowCount else { continue }

      // baseline-aligned content may get pushed down to meet the row baseline
      var baselinePushDown: CGFloat = 0
      if layout.block.verticalAlignment == .baselineAlignment {
        baselinePushDown = rowFirstBaselines[row] - baselineInset(of: layout)
      }

      let slotHeight =
        layout.contentHeight + layout.contentInsetTop + layout.contentInsetBottom
        + layout.block.width(for: .margin, edge: .minYEdge)
        + layout.block.width(for: .margin, edge: .maxYEdge)
        + baselinePushDown
      rowHeights[row] = max(rowHeights[row], slotHeight)
    }

    // grow the last spanned row when a rowspan cell does not fit
    for layout in cellLayouts where layout.block.rowSpan > 1 {
      let firstRow = layout.block.startingRow
      let lastRow = min(firstRow + layout.block.rowSpan, rowCount) - 1
      guard firstRow <= lastRow else { continue }

      let needed =
        layout.contentHeight + layout.contentInsetTop + layout.contentInsetBottom
        + layout.block.width(for: .margin, edge: .minYEdge)
        + layout.block.width(for: .margin, edge: .maxYEdge)
      let current = rowHeights[firstRow...lastRow].reduce(0, +)

      if needed > current {
        rowHeights[lastRow] += needed - current
      }
    }

    // 6. final positions
    var rowTops = [CGFloat](repeating: 0, count: rowCount + 1)
    rowTops[0] = topY + marginTop + edgeTop
    for row in 0..<rowCount {
      rowTops[row + 1] = rowTops[row] + rowHeights[row]
    }

    // pagination: only the leading rows that fit within maximumY are consumed by
    // this frame; the rest goes to a continuation frame starting at the first
    // excluded cell. When the frame is otherwise empty, the first row is consumed
    // regardless, so that pagination always makes progress.
    var includedRowCount = rowCount

    if rowTops[rowCount] > maximumY {
      includedRowCount = 0
      while includedRowCount < rowCount, rowTops[includedRowCount + 1] <= maximumY {
        includedRowCount += 1
      }

      if includedRowCount == 0 && mustConsumeFirstRow {
        includedRowCount = 1
      }
    }

    result.isPartial = includedRowCount < rowCount

    if includedRowCount == 0 {
      result.range = NSRange(location: location, length: 0)
      return result
    }

    if result.isPartial {
      let cutLocation =
        cells
        .filter { $0.block.startingRow >= includedRowCount }
        .map { $0.range.location }
        .min() ?? NSMaxRange(result.range)
      result.range = NSRange(location: location, length: cutLocation - location)
    }

    for var layout in cellLayouts where layout.block.startingRow < includedRowCount {
      let cellBlock = layout.block
      let cellMarginTop = cellBlock.width(for: .margin, edge: .minYEdge)
      let cellMarginBottom = cellBlock.width(for: .margin, edge: .maxYEdge)

      let firstRow = cellBlock.startingRow
      let lastRow = min(firstRow + cellBlock.rowSpan, rowCount) - 1
      let slotTop = rowTops[firstRow]
      let slotHeight = rowTops[lastRow + 1] - slotTop

      let borderBoxY = slotTop + cellMarginTop
      let borderBoxHeight = max(slotHeight - cellMarginTop - cellMarginBottom, 1)

      let innerHeight = borderBoxHeight - layout.contentInsetTop - layout.contentInsetBottom
      var verticalShift = borderBoxY + layout.contentInsetTop

      switch cellBlock.verticalAlignment {
      case .middleAlignment:
        verticalShift += max((innerHeight - layout.contentHeight) / 2, 0)
      case .bottomAlignment:
        verticalShift += max(innerHeight - layout.contentHeight, 0)
      case .baselineAlignment:
        // align the first baseline with the row's common first baseline
        if cellBlock.rowSpan == 1, firstRow < rowCount, rowFirstBaselines[firstRow] > 0 {
          verticalShift = slotTop + rowFirstBaselines[firstRow] - relativeFirstBaseline(of: layout)
        }
      default:
        break  // top aligns at the content top
      }

      for line in layout.flow.lines {
        var origin = line.baselineOrigin
        origin.y = ceil(origin.y + verticalShift)
        line.baselineOrigin = origin
      }
      for index in layout.flow.cellFrames.indices {
        layout.flow.cellFrames[index].rect.origin.y += verticalShift
      }
      for index in layout.flow.tableFrames.indices {
        layout.flow.tableFrames[index].rect.origin.y += verticalShift
      }

      result.lines.append(contentsOf: layout.flow.lines)
      result.cellFrames.append(contentsOf: layout.flow.cellFrames)
      result.tableFrames.append(contentsOf: layout.flow.tableFrames)
      result.suppressedBorderEdges.merge(layout.flow.suppressedBorderEdges) { $0 | $1 }

      result.cellFrames.append(
        (
          cellBlock,
          CGRect(
            x: layout.borderBoxX, y: borderBoxY, width: layout.borderBoxWidth,
            height: borderBoxHeight),
          level
        ))
    }

    // 6.5 collapsed borders: each interior boundary keeps only the wider of the two
    // adjacent borders; on the perimeter the wider of the table border and the outer
    // cell borders wins — yielding a single-line grid
    if table.collapsesBorders {
      var grid = [[Int?]](
        repeating: [Int?](repeating: nil, count: columnCount), count: rowCount)

      for (index, layout) in cellLayouts.enumerated() {
        let block = layout.block
        for row in block.startingRow..<min(block.startingRow + block.rowSpan, rowCount) {
          for column in block.startingColumn..<min(
            block.startingColumn + block.columnSpan, columnCount)
          {
            grid[row][column] = index
          }
        }
      }

      func suppress(_ block: TextBlock, _ edge: CGRectEdge) {
        result.suppressedBorderEdges[ObjectIdentifier(block), default: 0] |=
          (1 << UInt(edge.rawValue))
      }

      // interior vertical boundaries
      for row in 0..<rowCount {
        for column in 0..<(columnCount - 1) {
          guard let leftIndex = grid[row][column], let rightIndex = grid[row][column + 1],
            leftIndex != rightIndex
          else { continue }

          let left = cellLayouts[leftIndex].block
          let right = cellLayouts[rightIndex].block

          if left.width(for: .border, edge: .maxXEdge)
            >= right.width(for: .border, edge: .minXEdge)
          {
            suppress(right, .minXEdge)
          } else {
            suppress(left, .maxXEdge)
          }
        }
      }

      // interior horizontal boundaries
      for column in 0..<columnCount {
        for row in 0..<(rowCount - 1) {
          guard let topIndex = grid[row][column], let bottomIndex = grid[row + 1][column],
            topIndex != bottomIndex
          else { continue }

          let top = cellLayouts[topIndex].block
          let bottom = cellLayouts[bottomIndex].block

          if top.width(for: .border, edge: .maxYEdge)
            >= bottom.width(for: .border, edge: .minYEdge)
          {
            suppress(bottom, .minYEdge)
          } else {
            suppress(top, .maxYEdge)
          }
        }
      }

      // perimeter sides
      func resolvePerimeter(tableEdge: CGRectEdge, cellIndices: [Int?], cellEdge: CGRectEdge) {
        let tableWidth = table.width(for: .border, edge: tableEdge)
        let indices = cellIndices.compactMap { $0 }
        let maxCellWidth = indices.map {
          cellLayouts[$0].block.width(for: .border, edge: cellEdge)
        }.max() ?? 0

        if tableWidth >= maxCellWidth && tableWidth > 0 {
          for index in indices {
            suppress(cellLayouts[index].block, cellEdge)
          }
        } else if maxCellWidth > 0 {
          suppress(table, tableEdge)
        }
      }

      resolvePerimeter(tableEdge: .minYEdge, cellIndices: grid[0], cellEdge: .minYEdge)
      resolvePerimeter(
        tableEdge: .maxYEdge, cellIndices: grid[rowCount - 1], cellEdge: .maxYEdge)
      resolvePerimeter(
        tableEdge: .minXEdge, cellIndices: (0..<rowCount).map { grid[$0][0] },
        cellEdge: .minXEdge)
      resolvePerimeter(
        tableEdge: .maxXEdge, cellIndices: (0..<rowCount).map { grid[$0][columnCount - 1] },
        cellEdge: .maxXEdge)
    }

    // 7. the table's own border box, drawn beneath its cells; a partial table has
    // no bottom edge on this frame — it continues on the next one
    let gridBottom = rowTops[includedRowCount]
    let tableRect = CGRect(
      x: originX + marginLeft,
      y: topY + marginTop,
      width: edgeLeft + gridWidth + edgeRight,
      height: edgeTop + (gridBottom - rowTops[0]) + (result.isPartial ? 0 : edgeBottom))

    result.tableFrames.insert((table, tableRect, level), at: 0)
    result.bottomY = result.isPartial ? tableRect.maxY : tableRect.maxY + marginBottom

    return result
  }

  /// Lays out a range of text as a vertical flow of lines with the given width — the
  /// content of one table cell. Nested tables are laid out recursively.
  private func _layoutFlow(
    range: NSRange, level: Int, width: CGFloat, originX: CGFloat, topY: CGFloat
  ) -> _TableLayoutResult {
    var result = _TableLayoutResult()
    result.range = range
    result.bottomY = topY

    guard let framesetter = _framesetter, let fragment = _attributedStringFragment else {
      return result
    }

    let typesetter = CTFramesetterGetTypesetter(framesetter)
    let maxIndex = NSMaxRange(range)

    var location = range.location
    var previousLine: CoreTextLayoutLine?
    var minimumBaselineY: CGFloat?
    var currentBottom = topY

    while location < maxIndex {
      // nested table starting at this paragraph?
      if let nested = _tableStart(at: location, atOrDeeperThan: level) {
        let nestedResult = _layoutTable(
          nested.block.table, level: nested.level, startingAt: location,
          availableWidth: width, originX: originX, topY: currentBottom)

        if nestedResult.range.length > 0 {
          result.lines.append(contentsOf: nestedResult.lines)
          result.cellFrames.append(contentsOf: nestedResult.cellFrames)
          result.tableFrames.append(contentsOf: nestedResult.tableFrames)
          result.suppressedBorderEdges.merge(nestedResult.suppressedBorderEdges) { $0 | $1 }
          currentBottom = nestedResult.bottomY
          minimumBaselineY = nestedResult.bottomY
          previousLine = nestedResult.lines.last ?? previousLine
          location = NSMaxRange(nestedResult.range)
          continue
        }
      }

      var lineRange = NSRange(location: location, length: 0)
      lineRange.length = CTTypesetterSuggestLineBreak(typesetter, location, Double(width))

      if NSMaxRange(lineRange) > maxIndex {
        lineRange.length = maxIndex - location
      }

      guard lineRange.length > 0 else { break }

      var ctLine = CTTypesetterCreateLine(
        typesetter, CFRangeMake(lineRange.location, lineRange.length))

      // alignment within the cell
      let paragraphStyle =
        fragment.attribute(.paragraphStyle, at: location, effectiveRange: nil)
        as? NSParagraphStyle

      // justified text stretches all lines except the last of a paragraph
      if paragraphStyle?.alignment == .justified {
        let paragraphRange = (fragment.string as NSString).paragraphRange(
          for: NSRange(location: location, length: 0))
        let isLastLineInParagraph = NSMaxRange(lineRange) >= NSMaxRange(paragraphRange)
        let lineWidth = CGFloat(CTLineGetTypographicBounds(ctLine, nil, nil, nil))

        if !isLastLineInParagraph, lineWidth > justifyRatio * width,
          let justifiedLine = CTLineCreateJustifiedLine(ctLine, 1.0, Double(width))
        {
          ctLine = justifiedLine
        }
      }

      guard let newLine = CoreTextLayoutLine(line: ctLine, stringLocationOffset: 0) else {
        location = NSMaxRange(lineRange)
        continue
      }

      var lineOriginX = originX

      if let paragraphStyle {
        switch paragraphStyle.alignment {
        case .right:
          lineOriginX = originX + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(width)))
        case .center:
          lineOriginX = originX + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 0.5, Double(width)))
        case .natural, .justified:
          if paragraphStyle.baseWritingDirection == .rightToLeft {
            lineOriginX =
              originX + CGFloat(CTLineGetPenOffsetForFlush(ctLine, 1.0, Double(width)))
          }
        default:
          break
        }

        newLine.writingDirectionIsRightToLeft =
          (paragraphStyle.baseWritingDirection == .rightToLeft)
      }

      var baselineOrigin: CGPoint

      if let previousLine {
        baselineOrigin = _algorithmWebKit_BaselineOrigin(
          toPositionLine: newLine, afterLine: previousLine)
      } else {
        let halfLeading = max(_algorithmWebKit_halfLeading(ofLine: newLine), 0)
        baselineOrigin = CGPoint(x: originX, y: topY + newLine.ascent + halfLeading)
      }

      if let minimumY = minimumBaselineY {
        baselineOrigin.y = max(baselineOrigin.y, minimumY + newLine.ascent)
        minimumBaselineY = nil
      }

      baselineOrigin.x = lineOriginX
      baselineOrigin.y = ceil(baselineOrigin.y)
      newLine.baselineOrigin = baselineOrigin

      result.lines.append(newLine)
      currentBottom = max(currentBottom, newLine.frame.maxY)
      previousLine = newLine
      location = NSMaxRange(lineRange)
    }

    result.bottomY = currentBottom
    return result
  }

  private func _updateFrameSize() {
    guard let lines = _lines, !lines.isEmpty else { return }

    if _frame.size.height == CGFLOAT_HEIGHT_UNKNOWN {
      if let lastLine = lines.last {
        // a table's lowest cell can reach below the last line of text
        let contentBottom = max(lastLine.frame.maxY, _maxTableBottom)
        _frame.size.height = ceil(
          contentBottom - _frame.origin.y + 1.5 + _additionalPaddingAtBottom)
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
