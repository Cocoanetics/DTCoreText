import CoreText
import Foundation

/// Compares two CTLines for glyph equality.
/// - Parameters:
///   - line1: The first CTLine
///   - line2: The second CTLine
/// - Returns: true if both lines have identical glyph runs
public func areLinesEqual(_ line1: CTLine?, _ line2: CTLine?) -> Bool {
  guard let line1 = line1, let line2 = line2 else {
    return false
  }

  let glyphRuns1 = CTLineGetGlyphRuns(line1) as! [CTRun]
  let glyphRuns2 = CTLineGetGlyphRuns(line2) as! [CTRun]

  guard glyphRuns1.count == glyphRuns2.count else {
    return false
  }

  for i in 0..<glyphRuns1.count {
    let run1 = glyphRuns1[i]
    let run2 = glyphRuns2[i]

    let countInRun1 = CTRunGetGlyphCount(run1)
    let countInRun2 = CTRunGetGlyphCount(run2)

    guard countInRun1 == countInRun2 else {
      return false
    }

    var glyphs1 = [CGGlyph](repeating: 0, count: countInRun1)
    var glyphs2 = [CGGlyph](repeating: 0, count: countInRun2)

    CTRunGetGlyphs(run1, CFRangeMake(0, countInRun1), &glyphs1)
    CTRunGetGlyphs(run2, CFRangeMake(0, countInRun2), &glyphs2)

    if glyphs1 != glyphs2 {
      return false
    }
  }

  return true
}

/// Determines the truncation index in a CTLine given a truncation token line.
/// - Parameters:
///   - line: The original CTLine
///   - trunc: The truncation token CTLine
/// - Returns: The string index where truncation occurs
public func getTruncationIndex(_ line: CTLine?, _ trunc: CTLine?) -> CFIndex {
  guard let line = line, let trunc = trunc else {
    return 0
  }

  let truncCount = CFArrayGetCount(CTLineGetGlyphRuns(trunc))
  let lineRuns = CTLineGetGlyphRuns(line)
  let lineRunsCount = CFArrayGetCount(lineRuns)

  let index = lineRunsCount - truncCount - 1

  if index < 0 {
    return 0
  } else {
    let lineLastRun = unsafeBitCast(CFArrayGetValueAtIndex(lineRuns, index), to: CTRun.self)
    let lastRunRange = CTRunGetStringRange(lineLastRun)
    return lastRunRange.location + lastRunRange.length
  }
}
