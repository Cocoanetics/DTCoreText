import CoreText
import Foundation
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Tests for grid layout of tables in `CoreTextLayoutFrame`.
@Suite("Table Layout", .serialized)
struct TableLayoutTests {

  // MARK: - Helpers

  private func layoutFrame(
    html: String, width: CGFloat = 400
  ) throws -> (frame: CoreTextLayoutFrame, string: NSAttributedString) {
    let attributedString = try #require(TestHelpers.attributedString(fromHTML: html))
    let layouter = try #require(CoreTextLayouter(attributedString: attributedString))

    let maxRect = CGRect(x: 0, y: 0, width: width, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
    let entireString = NSRange(location: 0, length: attributedString.length)
    let frame = try #require(layouter.layoutFrame(with: maxRect, range: entireString))

    return (frame, attributedString)
  }

  private func line(
    containing text: String, in layoutFrame: CoreTextLayoutFrame,
    of attributedString: NSAttributedString
  ) throws -> CoreTextLayoutLine {
    let nsString = attributedString.string as NSString
    let range = nsString.range(of: text)
    try #require(range.location != NSNotFound, "text \(text) not found")
    return try #require(layoutFrame.lineContaining(index: UInt(range.location)))
  }

  // MARK: - Grid Geometry

  @Test("Cells of one row sit side by side, rows stack vertically")
  func basicGrid() throws {
    let (frame, string) = try layoutFrame(
      html: "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>")

    let lineA1 = try line(containing: "A1", in: frame, of: string)
    let lineB1 = try line(containing: "B1", in: frame, of: string)
    let lineA2 = try line(containing: "A2", in: frame, of: string)
    let lineB2 = try line(containing: "B2", in: frame, of: string)

    // same row: identical baseline, second column to the right
    #expect(abs(lineA1.baselineOrigin.y - lineB1.baselineOrigin.y) < 1)
    #expect(lineB1.frame.minX > lineA1.frame.maxX - 1)

    // second row strictly below the first
    #expect(lineA2.frame.minY >= lineA1.frame.maxY - 1)
    #expect(abs(lineA2.baselineOrigin.y - lineB2.baselineOrigin.y) < 1)

    // columns align across rows
    #expect(abs(lineA1.frame.minX - lineA2.frame.minX) < 1)
    #expect(abs(lineB1.frame.minX - lineB2.frame.minX) < 1)

    // the auto-sized frame includes both rows
    #expect(frame.frame.size.height > lineA2.frame.maxY - frame.frame.origin.y - 1)
  }

  @Test("Fixed layout splits the explicit table width equally")
  func fixedLayoutWidths() throws {
    let (frame, string) = try layoutFrame(
      html:
        "<table style=\"table-layout: fixed; width: 300px\"><tr><td>A</td><td>B</td></tr></table>")

    let lineA = try line(containing: "A", in: frame, of: string)
    let lineB = try line(containing: "B", in: frame, of: string)

    // each column is 150pt wide; the second cell's content starts one
    // cell margin + padding after the column boundary
    #expect(abs((lineB.frame.minX - lineA.frame.minX) - 150) < 2)
  }

  @Test("Explicit cell widths are honored")
  func explicitCellWidths() throws {
    let (frame, string) = try layoutFrame(
      html: "<table><tr><td width=\"120\">A</td><td>B</td></tr></table>")

    let lineA = try line(containing: "A", in: frame, of: string)
    let lineB = try line(containing: "B", in: frame, of: string)

    // first column is 120pt content + 3pt box extras
    #expect(abs((lineB.frame.minX - lineA.frame.minX) - 123) < 2)
  }

  @Test("Vertical alignment moves cell content within the row")
  func verticalAlignment() throws {
    let (frame, string) = try layoutFrame(
      html: "<table><tr><td>first line<br>second line</td>"
        + "<td valign=\"top\">topcell</td><td valign=\"bottom\">bottomcell</td></tr></table>")

    let lineFirst = try line(containing: "first line", in: frame, of: string)
    let lineSecond = try line(containing: "second line", in: frame, of: string)
    let lineTop = try line(containing: "topcell", in: frame, of: string)
    let lineBottom = try line(containing: "bottomcell", in: frame, of: string)

    // the tall cell defines the row height
    #expect(lineSecond.frame.minY > lineFirst.frame.minY)

    // top-aligned cell aligns with the first line, bottom-aligned with the last
    #expect(abs(lineTop.baselineOrigin.y - lineFirst.baselineOrigin.y) < 2)
    #expect(lineBottom.baselineOrigin.y > lineTop.baselineOrigin.y)
    #expect(abs(lineBottom.frame.maxY - lineSecond.frame.maxY) < 3)
  }

  @Test("Baseline-aligned cells share the first baseline across the row")
  func baselineAlignment() throws {
    let (frame, string) = try layoutFrame(
      html: "<table><tr>"
        + "<td style=\"vertical-align: baseline; font-size: 36px\">BIG</td>"
        + "<td style=\"vertical-align: baseline\">small</td>"
        + "<td valign=\"baseline\">attr</td></tr></table>")

    let lineBig = try line(containing: "BIG", in: frame, of: string)
    let lineSmall = try line(containing: "small", in: frame, of: string)
    let lineAttr = try line(containing: "attr", in: frame, of: string)

    // per NSTextBlock documentation, adjacent baseline-aligned blocks align at the
    // baseline of their first line of text
    #expect(abs(lineBig.baselineOrigin.y - lineSmall.baselineOrigin.y) < 1)
    #expect(abs(lineBig.baselineOrigin.y - lineAttr.baselineOrigin.y) < 1)

    // the small cells are pushed down, not the big one up
    #expect(lineSmall.frame.minY > lineBig.frame.minY)
  }

  @Test("Justified text inside cells stretches to the cell width")
  func justifiedCellText() throws {
    let words = Array(repeating: "word", count: 30).joined(separator: " ")
    let (frame, string) = try layoutFrame(
      html: "<table><tr><td width=\"200\" style=\"text-align: justify\">\(words)</td></tr></table>")

    let firstLine = try line(containing: "word", in: frame, of: string)

    // a justified line fills the available cell content width (200pt)
    #expect(firstLine.frame.width > 195)
    #expect(firstLine.frame.width <= 201)
  }

  @Test("Rowspan cells span multiple rows")
  func rowspan() throws {
    let (frame, string) = try layoutFrame(
      html:
        "<table><tr><td rowspan=\"2\">Tall</td><td>B1</td></tr><tr><td>B2</td></tr></table>")

    let lineTall = try line(containing: "Tall", in: frame, of: string)
    let lineB1 = try line(containing: "B1", in: frame, of: string)
    let lineB2 = try line(containing: "B2", in: frame, of: string)

    // B1 and B2 are in different rows, both to the right of the spanning cell
    #expect(lineB2.frame.minY >= lineB1.frame.maxY - 1)
    #expect(lineB1.frame.minX > lineTall.frame.maxX - 1)
    #expect(abs(lineB1.frame.minX - lineB2.frame.minX) < 1)

    // the spanning cell is middle-aligned across both rows, so it sits lower
    // than the first row's cell
    #expect(lineTall.baselineOrigin.y > lineB1.baselineOrigin.y - 1)
  }

  @Test("Nested tables lay out inside their cell")
  func nestedTable() throws {
    let (frame, string) = try layoutFrame(
      html:
        "<table><tr><td>Outer A<table><tr><td>Inner 1</td><td>Inner 2</td></tr></table>after inner</td><td>Outer B</td></tr></table>"
    )

    let lineOuterA = try line(containing: "Outer A", in: frame, of: string)
    let lineInner1 = try line(containing: "Inner 1", in: frame, of: string)
    let lineInner2 = try line(containing: "Inner 2", in: frame, of: string)
    let lineAfter = try line(containing: "after inner", in: frame, of: string)
    let lineOuterB = try line(containing: "Outer B", in: frame, of: string)

    // the inner table is below the cell text that precedes it
    #expect(lineInner1.frame.minY >= lineOuterA.frame.maxY - 1)

    // inner cells sit side by side within the outer cell
    #expect(abs(lineInner1.baselineOrigin.y - lineInner2.baselineOrigin.y) < 1)
    #expect(lineInner2.frame.minX > lineInner1.frame.maxX - 1)
    #expect(lineInner1.frame.minX >= lineOuterA.frame.minX - 1)

    // content after the inner table continues below it
    #expect(lineAfter.frame.minY >= lineInner1.frame.maxY - 1)

    // the second outer column is to the right of the inner table content
    #expect(lineOuterB.frame.minX > lineInner2.frame.maxX - 1)
  }

  @Test("Flow continues below the table")
  func flowAfterTable() throws {
    let (frame, string) = try layoutFrame(
      html: "<p>Before</p><table><tr><td>A1</td><td>B1</td></tr></table><p>After</p>")

    let lineBefore = try line(containing: "Before", in: frame, of: string)
    let lineA1 = try line(containing: "A1", in: frame, of: string)
    let lineAfter = try line(containing: "After", in: frame, of: string)

    #expect(lineA1.frame.minY > lineBefore.frame.maxY - 1)
    #expect(lineAfter.frame.minY >= lineA1.frame.maxY - 1)

    // the paragraph after the table starts at the leading margin again
    #expect(abs(lineAfter.frame.minX - lineBefore.frame.minX) < 1)
  }

  @Test("Percentage table widths resolve against the frame width")
  func percentageWidth() throws {
    let (frame, string) = try layoutFrame(
      html: "<table width=\"50%\"><tr><td width=\"50%\">A</td><td width=\"50%\">B</td></tr></table>",
      width: 400)

    let lineA = try line(containing: "A", in: frame, of: string)
    let lineB = try line(containing: "B", in: frame, of: string)

    // table is 200pt, each column 100pt
    #expect(abs((lineB.frame.minX - lineA.frame.minX) - 100) < 2)
  }

  @Test("Collapsed borders draw a single-line grid")
  func collapsedBorderGrid() throws {
    // counts distinct dark horizontal lines crossing a vertical scan column
    func darkLineRuns(html: String) throws -> Int {
      let (frame, string) = try layoutFrame(html: html, width: 200)

      let lineA1 = try line(containing: "A1", in: frame, of: string)
      let scale = 2
      let width = 200 * scale
      let height = (Int(ceil(frame.frame.maxY)) + 4) * scale

      let context = try #require(
        CGContext(
          data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
      context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
      context.translateBy(x: 0, y: CGFloat(height))
      context.scaleBy(x: CGFloat(scale), y: -CGFloat(scale))
      frame.draw(in: context, options: 0)

      // scan inside the wide cell, to the right of the short text, so only
      // horizontal border lines cross the column
      let scanX = Int((lineA1.frame.minX + 60) * CGFloat(scale))
      let data = try #require(context.data)
      let buffer = data.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * height)

      var runs = 0
      var inRun = false
      for row in 0..<height {
        let offset = row * context.bytesPerRow + scanX * 4
        let isDark =
          buffer[offset] < 128 && buffer[offset + 1] < 128 && buffer[offset + 2] < 128
        if isDark && !inRun { runs += 1 }
        inRun = isDark
      }
      return runs
    }

    // a collapsed two-row grid has exactly three horizontal lines: top, middle, bottom
    let collapsed = try darkLineRuns(
      html: "<table border=\"1\" style=\"border-collapse: collapse\">"
        + "<tr><td width=\"100\">A1</td></tr><tr><td>A2</td></tr></table>")
    #expect(collapsed == 3)

    // separated borders show the table border plus each cell's own border
    let separated = try darkLineRuns(
      html: "<table border=\"1\"><tr><td width=\"100\">A1</td></tr><tr><td>A2</td></tr></table>")
    #expect(separated >= 5)
  }

  // MARK: - Pagination

  @Test("Tall tables paginate row by row across finite-height frames")
  func tablePagination() throws {
    let rows = (1...6).map { "<tr><td>A\($0)</td><td>B\($0)</td></tr>" }.joined()
    let attributedString = try #require(
      TestHelpers.attributedString(fromHTML: "<table border=\"1\">\(rows)</table>"))
    let layouter = try #require(CoreTextLayouter(attributedString: attributedString))
    let fullRange = NSRange(location: 0, length: attributedString.length)

    // a frame that fits roughly three rows
    let firstFrame = try #require(
      layouter.layoutFrame(with: CGRect(x: 0, y: 0, width: 300, height: 60), range: fullRange))

    let firstVisible = firstFrame.visibleStringRange()
    #expect(firstVisible.length > 0)
    #expect(firstVisible.length < attributedString.length)

    // every consumed line stays within the frame
    let firstLines = try #require(firstFrame.lines as? [CoreTextLayoutLine])
    for line in firstLines {
      #expect(line.frame.maxY <= 60 + 1)
    }

    // the continuation frame consumes the remaining rows and still forms a grid
    let continuationStart = NSMaxRange(firstVisible)
    let secondFrame = try #require(
      layouter.layoutFrame(
        with: CGRect(x: 0, y: 0, width: 300, height: 400),
        range: NSRange(
          location: continuationStart, length: attributedString.length - continuationStart)))

    let secondVisible = secondFrame.visibleStringRange()
    #expect(NSMaxRange(secondVisible) == attributedString.length)

    let nsString = attributedString.string as NSString
    let rangeA6 = nsString.range(of: "A6")
    let rangeB6 = nsString.range(of: "B6")
    try #require(rangeA6.location >= continuationStart, "A6 must be on the second page")

    let lineA6 = try #require(secondFrame.lineContaining(index: UInt(rangeA6.location)))
    let lineB6 = try #require(secondFrame.lineContaining(index: UInt(rangeB6.location)))

    // the continued rows still lay out side by side
    #expect(abs(lineA6.baselineOrigin.y - lineB6.baselineOrigin.y) < 1)
    #expect(lineB6.frame.minX > lineA6.frame.maxX - 1)
  }

  @Test("A table that does not fit at all moves entirely to the next frame")
  func tableMovesToNextFrame() throws {
    let attributedString = try #require(
      TestHelpers.attributedString(
        fromHTML: "<p>Intro text</p><table border=\"1\"><tr><td>A1</td><td>B1</td></tr>"
          + "<tr><td>A2</td><td>B2</td></tr></table>"))
    let layouter = try #require(CoreTextLayouter(attributedString: attributedString))
    let fullRange = NSRange(location: 0, length: attributedString.length)

    // fits the intro line but not a single table row
    let firstFrame = try #require(
      layouter.layoutFrame(with: CGRect(x: 0, y: 0, width: 300, height: 24), range: fullRange))

    let firstVisible = firstFrame.visibleStringRange()
    let tableStart = (attributedString.string as NSString).range(of: "A1").location
    #expect(NSMaxRange(firstVisible) <= tableStart)
    #expect(firstVisible.length > 0)
  }

  @Test("A frame consumes at least the first table row to guarantee progress")
  func tableForcedFirstRow() throws {
    let attributedString = try #require(
      TestHelpers.attributedString(
        fromHTML: "<table border=\"1\"><tr><td>A1<br>two<br>three</td></tr>"
          + "<tr><td>A2</td></tr></table>"))
    let layouter = try #require(CoreTextLayouter(attributedString: attributedString))
    let fullRange = NSRange(location: 0, length: attributedString.length)

    // far too small for even the first row — it must be consumed anyway
    let frame = try #require(
      layouter.layoutFrame(with: CGRect(x: 0, y: 0, width: 300, height: 10), range: fullRange))

    let visible = frame.visibleStringRange()
    #expect(visible.length > 0)

    let secondRowStart = (attributedString.string as NSString).range(of: "A2").location
    #expect(NSMaxRange(visible) <= secondRowStart)
  }

  // MARK: - Drawing

  @Test("Drawing a table with backgrounds and borders does not crash and paints")
  func drawingSmokeTest() throws {
    let (frame, _) = try layoutFrame(
      html: "<table border=\"1\" bgcolor=\"#FF0000\"><tr><td bgcolor=\"#00FF00\">A</td>"
        + "<td style=\"border: 2px solid blue\">B</td></tr></table>")

    let width = 400
    let height = max(Int(ceil(frame.frame.size.height)) + 10, 50)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = try #require(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))

    // white background
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

    frame.draw(in: context, options: 0)

    // at least some pixels must have been painted non-white
    let data = try #require(context.data)
    let buffer = data.bindMemory(to: UInt8.self, capacity: context.bytesPerRow * height)

    var nonWhitePixels = 0
    for row in 0..<height {
      for column in 0..<width {
        let offset = row * context.bytesPerRow + column * 4
        if buffer[offset] != 255 || buffer[offset + 1] != 255 || buffer[offset + 2] != 255 {
          nonWhitePixels += 1
        }
      }
    }

    #expect(nonWhitePixels > 50)
  }
}
