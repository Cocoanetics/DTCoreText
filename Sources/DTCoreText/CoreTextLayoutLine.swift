import CoreText
import Foundation
import os

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Represents one laid out line and contains a number of glyph runs.
@objc(DTCoreTextLayoutLine)
open class CoreTextLayoutLine: NSObject {

  private var _line: CTLine
  private var _frame: CGRect = .zero

  /// The baseline origin of the receiver.
  @objc open var baselineOrigin: CGPoint = .zero

  private var _ascent: CGFloat = 0
  private var _descent: CGFloat = 0
  private var _leading: CGFloat = 0
  private var _width: CGFloat = 0
  private var _trailingWhitespaceWidth: CGFloat = 0

  private var _underlineOffset: CGFloat = 0
  private var _lineHeight: CGFloat = 0

  private var _glyphRuns: NSArray?

  private var _didCalculateMetrics = false
  private var _writingDirectionIsRightToLeft = false
  private var _needsToDetectWritingDirection = true
  private var _hasScannedGlyphRunsForValues = false

  private let _lock = OSAllocatedUnfairLock()

  /// Offset to modify internal string location to get actual location.
  @objc public private(set) var stringLocationOffset: Int = 0

  // MARK: - Creating Layout Lines

  /// Creates a layout line from a given CTLine.
  @objc public convenience init?(line: CTLine) {
    self.init(line: line, stringLocationOffset: 0)
  }

  /// Creates a layout line from a given CTLine with an optional string location offset.
  @objc public init?(line: CTLine, stringLocationOffset: Int) {
    _line = line
    _needsToDetectWritingDirection = true
    self.stringLocationOffset = stringLocationOffset
    super.init()
  }

  open override var description: String {
    return
      "<\(type(of: self)) origin=\(baselineOrigin) frame=\(self.frame) range=\(self.stringRange())>"
  }

  // MARK: - String Range

  /// The range in the original string that is represented by the receiver.
  @objc open func stringRange() -> NSRange {
    let range = CTLineGetStringRange(_line)
    return NSRange(location: range.location + stringLocationOffset, length: range.length)
  }

  /// The number of glyphs the receiver consists of.
  @objc open func numberOfGlyphs() -> Int {
    var ret = 0
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return 0 }
    for oneRun in runs {
      ret += oneRun.numberOfGlyphs
    }
    return ret
  }

  // MARK: - Drawing

  /// Draws the receiver in a given graphics context.
  @objc open func draw(in context: CGContext) {
    CTLineDraw(_line, context)
  }

  /// Creates a CGPath containing the shapes of all glyphs in the line.
  @objc open func newPathWithGlyphs() -> CGPath? {
    let mutablePath = CGMutablePath()
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return mutablePath }

    for oneRun in runs {
      if let glyphPath = oneRun.newPathWithGlyphs() {
        let posTransform = CGAffineTransform(translationX: baselineOrigin.x, y: baselineOrigin.y)
        mutablePath.addPath(glyphPath, transform: posTransform)
      }
    }

    return mutablePath
  }

  // MARK: - Creating Variants

  /// Creates a version of the receiver that is justified to the given width.
  @objc open func justifiedLine(
    withFactor justificationFactor: CGFloat, justificationWidth: CGFloat
  ) -> CoreTextLayoutLine? {
    guard
      let justifiedLine = CTLineCreateJustifiedLine(
        _line, justificationFactor, Double(justificationWidth))
    else { return nil }
    let newLine = CoreTextLayoutLine(line: justifiedLine)
    return newLine
  }

  // MARK: - Calculations

  /// The string indices of the receiver.
  @objc open func stringIndices() -> [NSNumber] {
    var array = [NSNumber]()
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return array }
    for oneRun in runs {
      array.append(contentsOf: oneRun.stringIndices())
    }
    return array
  }

  /// Determines the frame of a specific glyph.
  @objc open func frameOfGlyph(at index: Int) -> CGRect {
    var idx = index
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return .zero }
    for oneRun in runs {
      let count = oneRun.numberOfGlyphs
      if idx >= count {
        idx -= count
      } else {
        return oneRun.frameOfGlyph(at: idx)
      }
    }
    return .zero
  }

  /// Retrieves the glyphRuns with a given range.
  @objc open func glyphRuns(with range: NSRange) -> [CoreTextGlyphRun] {
    var tmpArray = [CoreTextGlyphRun]()
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return tmpArray }

    for oneRun in runs {
      let runRange = oneRun.stringRange()
      let intersectionRange = NSIntersectionRange(range, runRange)
      if intersectionRange.length > 0 {
        tmpArray.append(oneRun)
      }
    }
    return tmpArray
  }

  /// The frame of a number of glyphs with a given range.
  @objc open func frameOfGlyphs(with range: NSRange) -> CGRect {
    let runs = glyphRuns(with: range)
    var tmpRect = CGRect(
      x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude, width: 0, height: 0)

    for oneRun in runs {
      let glyphFrame = oneRun.frame
      if glyphFrame.origin.x < tmpRect.origin.x { tmpRect.origin.x = glyphFrame.origin.x }
      if glyphFrame.origin.y < tmpRect.origin.y { tmpRect.origin.y = glyphFrame.origin.y }
      if glyphFrame.size.height > tmpRect.size.height {
        tmpRect.size.height = glyphFrame.size.height
      }
      tmpRect.size.width = glyphFrame.origin.x + glyphFrame.size.width - tmpRect.origin.x
    }

    let maxX = self.frame.maxX - _trailingWhitespaceWidth
    if tmpRect.maxX > maxX {
      tmpRect.size.width = maxX - tmpRect.origin.x
    }

    return tmpRect
  }

  /// Bounds of an image encompassing the entire run.
  @objc open func imageBounds(in context: CGContext) -> CGRect {
    return CTLineGetImageBounds(_line, context)
  }

  /// Determines the graphical offset for a given string index.
  @objc open func offset(forStringIndex index: Int) -> CGFloat {
    let adjustedIndex = index - stringLocationOffset
    return CGFloat(CTLineGetOffsetForStringIndex(_line, adjustedIndex, nil))
  }

  /// Determines the string index that is closest to a given point.
  @objc open func stringIndex(for position: CGPoint) -> Int {
    var adjustedPosition = position
    let frame = self.frame
    adjustedPosition.x -= frame.origin.x
    adjustedPosition.y -= frame.origin.y

    var index = CTLineGetStringIndexForPosition(_line, adjustedPosition)
    index += stringLocationOffset
    return index
  }

  private func _calculateMetrics() {
    _lock.lock()
    defer { _lock.unlock() }

    if !_didCalculateMetrics {
      _width = CGFloat(CTLineGetTypographicBounds(_line, &_ascent, &_descent, &_leading))
      _trailingWhitespaceWidth = CGFloat(CTLineGetTrailingWhitespaceWidth(_line))
      _didCalculateMetrics = true
    }
  }

  /// Method to efficiently determine if the receiver is a horizontal rule.
  @objc open func isHorizontalRule() -> Bool {
    if self.stringRange().length > 1 { return false }
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return false }
    if runs.count > 1 { return false }
    guard let singleRun = runs.last else { return false }
    return (singleRun.attributes as? [NSAttributedString.Key: Any])?[
      NSAttributedString.Key(rawValue: DTHorizontalRuleStyleAttribute)] != nil
  }

  // MARK: - Determining Values from the glyph runs

  private func _scanGlyphRunsForValues() {
    _lock.lock()
    defer { _lock.unlock() }

    var maxOffset: CGFloat = 0
    var maxFontSize: CGFloat = 0

    // Ensure glyph runs are built (we already hold _lock; accessing the
    // `glyphRuns` property would re-enter it).
    _ensureGlyphRuns()
    guard let runs = _glyphRuns as? [CoreTextGlyphRun] else { return }

    for oneRun in runs {
      if let usedFont = (oneRun.attributes as? [NSAttributedString.Key: Any])?[
        NSAttributedString.Key(rawValue: kCTFontAttributeName as String)] as! CTFont?
      {
        maxOffset = max(maxOffset, abs(CTFontGetUnderlinePosition(usedFont)))
        maxFontSize = max(maxFontSize, CTFontGetSize(usedFont))
      }
    }

    _underlineOffset = maxOffset
    _lineHeight = maxFontSize
    _hasScannedGlyphRunsForValues = true
  }

  // MARK: - Properties

  /// Lazily builds the glyph runs array. Caller must already hold `_lock`.
  private func _ensureGlyphRuns() {
    if _glyphRuns == nil {
      let runs = CTLineGetGlyphRuns(_line)
      let runCount = CFArrayGetCount(runs)

      if runCount > 0 {
        let tmpArray = NSMutableArray(capacity: runCount)

        for i in 0..<runCount {
          let oneRun = unsafeBitCast(CFArrayGetValueAtIndex(runs, i), to: CTRun.self)

          var positions = CTRunGetPositionsPtr(oneRun)
          var shouldFreePositions = false

          if positions == nil {
            let glyphCount = CTRunGetGlyphCount(oneRun)
            shouldFreePositions = true
            let positionsBuffer = UnsafeMutablePointer<CGPoint>.allocate(capacity: glyphCount)
            CTRunGetPositions(oneRun, CFRangeMake(0, 0), positionsBuffer)
            positions = UnsafePointer(positionsBuffer)
          }

          let position = positions![0]
          let glyphRun = CoreTextGlyphRun(run: oneRun, layoutLine: self, offset: position.x)
          tmpArray.add(glyphRun)

          if shouldFreePositions {
            let mutable = UnsafeMutablePointer(mutating: positions!)
            mutable.deallocate()
          }
        }

        _glyphRuns = tmpArray
      }
    }
  }

  /// The glyph runs that the line contains.
  @objc open var glyphRuns: NSArray? {
    _lock.lock()
    defer { _lock.unlock() }
    _ensureGlyphRuns()
    return _glyphRuns
  }

  /// The frame of the receiver relative to the layout frame.
  @objc open var frame: CGRect {
    if !_didCalculateMetrics { _calculateMetrics() }

    var frame = CGRect(
      x: baselineOrigin.x, y: baselineOrigin.y - _ascent, width: _width, height: _ascent + _descent)

    // make sure that HR are extremely wide to be picked up
    if isHorizontalRule() {
      frame.size.width = .greatestFiniteMagnitude
    }

    return frame
  }

  /// The ascent (height above the baseline) of the receiver.
  @objc open var ascent: CGFloat {
    get {
      if !_didCalculateMetrics { _calculateMetrics() }
      return _ascent
    }
    set {
      if !_didCalculateMetrics { _calculateMetrics() }
      _ascent = newValue
    }
  }

  /// The descent (height below the baseline) of the receiver.
  @objc open var descent: CGFloat {
    if !_didCalculateMetrics { _calculateMetrics() }
    return _descent
  }

  /// The leading (additional space above the ascent) of the receiver.
  @objc open var leading: CGFloat {
    if !_didCalculateMetrics { _calculateMetrics() }
    return _leading
  }

  /// The offset for the underline.
  @objc open var underlineOffset: CGFloat {
    if !_hasScannedGlyphRunsForValues { _scanGlyphRunsForValues() }
    return _underlineOffset
  }

  /// The line height determined by the maximum font size.
  @objc open var lineHeight: CGFloat {
    if !_hasScannedGlyphRunsForValues { _scanGlyphRunsForValues() }
    return _lineHeight
  }

  /// The paragraph style of the paragraph this line belongs to.
  @objc open var paragraphStyle: CoreTextParagraphStyle? {
    guard let lastRun = (glyphRuns as? [CoreTextGlyphRun])?.last else { return nil }
    return (lastRun.attributes as? [NSAttributedString.Key: Any])?.dtct_paragraphStyle()
  }

  /// The text blocks that the receiver belongs to.
  @objc open var textBlocks: NSArray? {
    guard let lastRun = (glyphRuns as? [CoreTextGlyphRun])?.last else { return nil }
    return (lastRun.attributes as? [NSAttributedString.Key: Any])?[
      NSAttributedString.Key(rawValue: DTTextBlocksAttribute)] as? NSArray
  }

  /// The text attachments occurring in glyph runs of the receiver.
  ///
  /// Elements are `NSTextAttachment` (or subclasses); any native attachment on
  /// the run, not just `TextAttachment`, is included.
  @objc open var attachments: NSArray? {
    var tmpArray = [NSTextAttachment]()
    guard let runs = glyphRuns as? [CoreTextGlyphRun] else { return nil }
    for oneRun in runs {
      if let attachment = oneRun.attachment {
        tmpArray.append(attachment)
      }
    }
    return tmpArray.isEmpty ? nil : tmpArray as NSArray
  }

  /// The width of the trailing whitespace of the receiver.
  @objc open var trailingWhitespaceWidth: CGFloat {
    if !_didCalculateMetrics { _calculateMetrics() }
    return _trailingWhitespaceWidth
  }

  /// YES if the writing direction is Right-to-Left.
  @objc open var writingDirectionIsRightToLeft: Bool {
    get {
      if _needsToDetectWritingDirection {
        if let firstRun = (glyphRuns as? [CoreTextGlyphRun])?.first {
          _writingDirectionIsRightToLeft = firstRun.writingDirectionIsRightToLeft
        }
      }
      return _writingDirectionIsRightToLeft
    }
    set {
      _writingDirectionIsRightToLeft = newValue
      _needsToDetectWritingDirection = false
    }
  }
}
