import Foundation
import CoreText

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Represents a glyph run -- a number of characters from the original attributed string
/// that share the same characteristics and attributes.
@objc(DTCoreTextGlyphRun)
open class CoreTextGlyphRun: NSObject {

    private var _run: CTRun
    private var _frame: CGRect = .zero
    private var _offset: CGFloat = 0 // x distance from line origin
    private var _ascent: CGFloat = 0
    private var _descent: CGFloat = 0
    private var _leading: CGFloat = 0
    private var _width: CGFloat = 0

    private var _writingDirectionIsRightToLeft: Bool = false
    private var _isTrailingWhitespace: Bool = false

    private var _numberOfGlyphs: Int = 0
    private var _glyphPositionPoints: UnsafePointer<CGPoint>?

    private weak var _line: CoreTextLayoutLine?
    private weak var _attributes: NSDictionary?
    private var _stringIndices: [NSNumber]?
    private var _stringRange: NSRange = NSRange(location: 0, length: 0)

    private var _attachment: TextAttachment?
    private var _hyperlink: Bool = false

    private var _didCheckForAttachmentInAttributes = false
    private var _didCheckForHyperlinkInAttributes = false
    private var _didCalculateMetrics = false
    private var _didDetermineTrailingWhitespace = false

    // MARK: - Creating Glyph Runs

    /// Creates a new glyph run from a CTRun, belonging to a given layout line and with a given offset.
    @objc public init(run: CTRun, layoutLine: CoreTextLayoutLine, offset: CGFloat) {
        _run = run
        _offset = offset
        _line = layoutLine
        super.init()
    }

    open override var description: String {
        return "<\(type(of: self)) glyphs=\(numberOfGlyphs) \(_frame)>"
    }

    // MARK: - Drawing

    /// Draws the receiver into the given context.
    @objc open func draw(in context: CGContext) {
        let textMatrix = CTRunGetTextMatrix(_run)

        if textMatrix.isIdentity {
            CTRunDraw(_run, context, CFRangeMake(0, 0))
        } else {
            let pos = context.textPosition
            var matrix = textMatrix
            matrix.tx = pos.x
            matrix.ty = pos.y
            context.textMatrix = matrix
            CTRunDraw(_run, context, CFRangeMake(0, 0))
            context.textMatrix = .identity
        }
    }

    /// Draws the receiver's decoration (background highlighting, underline, strike-through).
    @objc open func drawDecoration(in context: CGContext) {
        let ctm = context.ctm
        var contentScale = max(ctm.a, -ctm.d)

        if contentScale < 1 || contentScale > 2 {
            contentScale = 2
        }

        let smallestPixelWidth: CGFloat = 1.0 / contentScale

        let backgroundColor = (self.attributes as? [NSAttributedString.Key: Any])?.dtct_backgroundColor()

        // Line-Out, Underline, Background-Color
        let drawStrikeOut = (_attributes?[NSAttributedString.Key(rawValue: DTStrikeOutAttribute)] as? NSNumber)?.boolValue ?? false
        let drawUnderline = (_attributes?[NSAttributedString.Key(rawValue: kCTUnderlineStyleAttributeName as String)] as? NSNumber)?.boolValue ?? false

        if drawStrikeOut || drawUnderline || backgroundColor != nil {
            guard let line = _line else { return }

            // calculate area covered by non-whitespace
            var lineFrame = line.frame

            // LTR line frames include trailing whitespace in width
            if !line.writingDirectionIsRightToLeft {
                lineFrame.size.width -= line.trailingWhitespaceWidth
            }

            // exclude trailing whitespace
            let runStrokeBounds = lineFrame.intersection(self.frame)

            let superscriptStyle = (_attributes?[NSAttributedString.Key(rawValue: kCTSuperscriptAttributeName as String)] as? NSNumber)?.intValue ?? 0

            var adjustedBounds = runStrokeBounds
            switch superscriptStyle {
            case 1:
                adjustedBounds.origin.y -= _ascent * 0.47
            case -1:
                adjustedBounds.origin.y += _ascent * 0.25
            default:
                break
            }

            if let backgroundColor = backgroundColor {
                let backgroundColorRect = CGRect(x: adjustedBounds.origin.x, y: lineFrame.origin.y, width: adjustedBounds.size.width, height: lineFrame.size.height).integral
                context.setFillColor(backgroundColor.cgColor)
                context.fill(backgroundColorRect)
            }

            if drawStrikeOut || drawUnderline {
                var didDrawSomething = false

                context.saveGState()

                let usedFont = _attributes?[NSAttributedString.Key(rawValue: kCTFontAttributeName as String)]
                let ctFont = usedFont as! CTFont?

                var fontUnderlineThickness: CGFloat
                if let ctFont = ctFont {
                    fontUnderlineThickness = CTFontGetUnderlineThickness(ctFont) * smallestPixelWidth
                } else {
                    fontUnderlineThickness = smallestPixelWidth
                }

                let usedUnderlineThickness = DTCeilWithContentScale(fontUnderlineThickness, contentScale)
                context.setLineWidth(usedUnderlineThickness)

                if drawStrikeOut {
                    var y: CGFloat
                    if let ctFont = ctFont {
                        let strokePosition = CTFontGetXHeight(ctFont) / 2.0
                        y = DTRoundWithContentScale(adjustedBounds.origin.y + _ascent - strokePosition, contentScale)
                    } else {
                        y = DTRoundWithContentScale(adjustedBounds.origin.y + self.frame.size.height / 2.0 + 1, contentScale)
                    }

                    if Int(usedUnderlineThickness / smallestPixelWidth) % 2 != 0 {
                        y += smallestPixelWidth / 2.0
                    }

                    context.move(to: CGPoint(x: adjustedBounds.origin.x, y: y))
                    context.addLine(to: CGPoint(x: adjustedBounds.origin.x + adjustedBounds.size.width, y: y))
                    didDrawSomething = true
                }

                // only draw underlines if Core Text didn't draw them yet
                if drawUnderline && !DTCoreTextDrawsUnderlinesWithGlyphs() {
                    let underlinePosition = line.underlineOffset
                    var y = DTRoundWithContentScale(line.baselineOrigin.y + underlinePosition - fontUnderlineThickness / 2.0, contentScale)

                    if Int(usedUnderlineThickness / smallestPixelWidth) % 2 != 0 {
                        y += smallestPixelWidth / 2.0
                    }

                    context.move(to: CGPoint(x: adjustedBounds.origin.x, y: y))
                    context.addLine(to: CGPoint(x: adjustedBounds.origin.x + adjustedBounds.size.width, y: y))
                    didDrawSomething = true
                }

                if didDrawSomething {
                    context.strokePath()
                }

                context.restoreGState()
            }
        }
    }

    /// Creates a CGPath containing the shapes of all glyphs in the receiver.
    @objc open func newPathWithGlyphs() -> CGPath? {
        guard let font = (self.attributes as? [NSAttributedString.Key: Any])?[NSAttributedString.Key(rawValue: kCTFontAttributeName as String)] as! CTFont? else {
            NSLog("CTFont missing on %@", self)
            return nil
        }

        guard let glyphs = CTRunGetGlyphsPtr(_run),
              let positions = CTRunGetPositionsPtr(_run) else { return nil }

        let mutablePath = CGMutablePath()

        for i in 0..<CTRunGetGlyphCount(_run) {
            let glyph = glyphs[i]
            let position = positions[i]

            var glyphTransform = CTRunGetTextMatrix(_run)
            glyphTransform = glyphTransform.scaledBy(x: 1, y: -1)

            if let glyphPath = CTFontCreatePathForGlyph(font, glyph, &glyphTransform) {
                var posTransform = CGAffineTransform(translationX: position.x, y: position.y)
                mutablePath.addPath(glyphPath, transform: posTransform)
            }
        }

        return mutablePath
    }

    // MARK: - Calculations

    private func calculateMetrics() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !_didCalculateMetrics {
            _width = CGFloat(CTRunGetTypographicBounds(_run, CFRangeMake(0, 0), &_ascent, &_descent, &_leading))
            _didCalculateMetrics = true
        }
    }

    /// Determines the frame of a specific glyph.
    @objc open func frameOfGlyph(at index: Int) -> CGRect {
        if !_didCalculateMetrics {
            calculateMetrics()
        }

        if _glyphPositionPoints == nil {
            _glyphPositionPoints = CTRunGetPositionsPtr(_run)
        }

        guard let glyphPositionPoints = _glyphPositionPoints, index < numberOfGlyphs else {
            return .null
        }

        guard let line = _line else { return .null }

        let glyphPosition = glyphPositionPoints[index]

        var rect = CGRect(x: line.baselineOrigin.x + glyphPosition.x, y: line.baselineOrigin.y - _ascent, width: _offset + _width - glyphPosition.x, height: _ascent + _descent)

        if index < numberOfGlyphs - 1 {
            rect.size.width = glyphPositionPoints[index + 1].x - glyphPosition.x
        }

        return rect
    }

    /// The string indices of the receiver.
    @objc open func stringIndices() -> [NSNumber] {
        if _stringIndices == nil {
            guard let indices = CTRunGetStringIndicesPtr(_run) else { return [] }
            let count = numberOfGlyphs
            var array = [NSNumber]()
            array.reserveCapacity(count)
            for i in 0..<count {
                array.append(NSNumber(value: indices[i]))
            }
            _stringIndices = array
        }
        return _stringIndices!
    }

    /// Bounds of an image encompassing the entire run.
    @objc open func imageBounds(in context: CGContext) -> CGRect {
        return CTRunGetImageBounds(_run, context, CFRangeMake(0, 0))
    }

    /// The string range (of the attributed string) represented by the receiver.
    @objc open func stringRange() -> NSRange {
        if _stringRange.length == 0 {
            let range = CTRunGetStringRange(_run)
            _stringRange = NSRange(location: range.location + (_line?.stringLocationOffset ?? 0), length: range.length)
        }
        return _stringRange
    }

    /// Fix metrics from attachment if needed.
    @objc open func fixMetricsFromAttachment() {
        if let attachment = self.attachment {
            if !_didCalculateMetrics {
                calculateMetrics()
            }
            _descent = 0
            _ascent = attachment.displaySize.height
        }
    }

    /// Returns YES if the receiver represents trailing whitespace in a line.
    @objc open func isTrailingWhitespace() -> Bool {
        if _didDetermineTrailingWhitespace {
            return _isTrailingWhitespace
        }

        guard let line = _line else {
            _didDetermineTrailingWhitespace = true
            return false
        }

        var isTrailing: Bool
        if line.writingDirectionIsRightToLeft {
            isTrailing = (self === (line.glyphRuns as? [CoreTextGlyphRun])?.first)
        } else {
            isTrailing = (self === (line.glyphRuns as? [CoreTextGlyphRun])?.last)
        }

        if isTrailing {
            if !_didCalculateMetrics {
                calculateMetrics()
            }

            if line.trailingWhitespaceWidth >= _width {
                _isTrailingWhitespace = true
            }
        }

        _didDetermineTrailingWhitespace = true
        return _isTrailingWhitespace
    }

    // MARK: - Properties

    /// The number of glyphs that the receiver is made up of.
    @objc open var numberOfGlyphs: Int {
        if _numberOfGlyphs == 0 {
            _numberOfGlyphs = CTRunGetGlyphCount(_run)
        }
        return _numberOfGlyphs
    }

    /// The Core Text attributes that are shared by all glyphs of the receiver.
    @objc open var attributes: NSDictionary {
        if _attributes == nil {
            _attributes = CTRunGetAttributes(_run) as NSDictionary
        }
        return _attributes!
    }

    /// The text attachment of the receiver, or nil if there is none.
    @objc open var attachment: TextAttachment? {
        if _attachment == nil && !_didCheckForAttachmentInAttributes {
            _attachment = (self.attributes as? [NSAttributedString.Key: Any])?[.attachment] as? TextAttachment
            _didCheckForAttachmentInAttributes = true
        }
        return _attachment
    }

    /// Returns YES if the receiver is part of a hyperlink.
    @objc open var isHyperlink: Bool {
        if !_hyperlink && !_didCheckForHyperlinkInAttributes {
            _hyperlink = (self.attributes as? [NSAttributedString.Key: Any])?[NSAttributedString.Key(rawValue: DTLinkAttribute)] != nil
            _didCheckForHyperlinkInAttributes = true
        }
        return _hyperlink
    }

    /// The frame rectangle of the glyph run, relative to the layout frame coordinate system.
    @objc open var frame: CGRect {
        if !_didCalculateMetrics {
            calculateMetrics()
        }
        guard let line = _line else { return .zero }
        return CGRect(x: line.baselineOrigin.x + _offset, y: line.baselineOrigin.y - _ascent, width: _width, height: _ascent + _descent)
    }

    /// The width of the receiver.
    @objc open var width: CGFloat {
        if !_didCalculateMetrics { calculateMetrics() }
        return _width
    }

    /// The ascent (height above the baseline) of the receiver.
    @objc open var ascent: CGFloat {
        if !_didCalculateMetrics { calculateMetrics() }
        return _ascent
    }

    /// The descent (height below the baseline) of the receiver.
    @objc open var descent: CGFloat {
        if !_didCalculateMetrics { calculateMetrics() }
        return _descent
    }

    /// The leading (additional space above the ascent) of the receiver.
    @objc open var leading: CGFloat {
        if !_didCalculateMetrics { calculateMetrics() }
        return _leading
    }

    /// YES if the writing direction is Right-to-Left.
    @objc open var writingDirectionIsRightToLeft: Bool {
        let status = CTRunGetStatus(_run)
        return status.contains(.rightToLeft)
    }
}

// Helper: check if DTCoreTextDrawsUnderlinesWithGlyphs is available
private func DTCoreTextDrawsUnderlinesWithGlyphs() -> Bool {
    // On modern systems (iOS 7+, macOS 10.9+), Core Text draws underlines with glyphs
    if #available(iOS 7.0, macOS 10.9, *) {
        return true
    }
    return false
}
