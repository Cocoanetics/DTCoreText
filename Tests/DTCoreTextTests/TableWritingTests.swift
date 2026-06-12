import Foundation
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Tests for writing tables back to HTML and round-tripping them through the parser.
@Suite("Table Writing", .serialized)
struct TableWritingTests {

  // MARK: - Helpers

  private func parse(_ html: String) throws -> NSAttributedString {
    return try #require(TestHelpers.attributedString(fromHTML: html))
  }

  private func writeFragment(_ attributedString: NSAttributedString) -> String {
    let writer = HTMLWriter(attributedString: attributedString)
    return writer.htmlFragment()
  }

  private func roundTrip(_ html: String) throws -> (
    original: NSAttributedString, fragment: String, reparsed: NSAttributedString
  ) {
    let original = try parse(html)
    let fragment = writeFragment(original)
    let reparsed = try parse(fragment)
    return (original, fragment, reparsed)
  }

  private func tableCells(of attributedString: NSAttributedString) -> [TextTableBlock] {
    let nsString = attributedString.string as NSString
    var cells = [TextTableBlock]()
    var location = 0

    while location < nsString.length {
      let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
      if let blocks = attributedString.attribute(
        NSAttributedString.Key(rawValue: DTTextBlocksAttribute), at: paragraphRange.location,
        effectiveRange: nil) as? [TextBlock]
      {
        for case let cell as TextTableBlock in blocks
        where !cells.contains(where: { $0 === cell }) {
          cells.append(cell)
        }
      }
      location = NSMaxRange(paragraphRange)
    }

    return cells
  }

  // MARK: - Tests

  @Test("Simple table writes table, tr and td tags")
  func writesBasicMarkup() throws {
    let (_, fragment, reparsed) = try roundTrip(
      "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>")

    #expect(fragment.contains("<table"))
    #expect(fragment.components(separatedBy: "<td").count == 5)
    #expect(fragment.components(separatedBy: "<tr").count == 3)
    #expect(fragment.contains("</table>"))

    // structure survives the round-trip
    #expect(reparsed.string == "A1\nB1\nA2\nB2\n")

    let cells = tableCells(of: reparsed)
    try #require(cells.count == 4)
    #expect(cells.map { $0.startingRow } == [0, 0, 1, 1])
    #expect(cells.map { $0.startingColumn } == [0, 1, 0, 1])
    #expect(cells[0].table.numberOfColumns == 2)
    #expect(cells.allSatisfy { $0.table === cells[0].table })
  }

  @Test("Spans round-trip through colspan and rowspan attributes")
  func spansRoundTrip() throws {
    let (original, fragment, reparsed) = try roundTrip(
      "<table><tr><td colspan=\"2\" rowspan=\"2\">Big</td><td>C1</td></tr><tr><td>C2</td></tr></table>"
    )

    #expect(fragment.contains("colspan=\"2\""))
    #expect(fragment.contains("rowspan=\"2\""))

    let originalCells = tableCells(of: original)
    let reparsedCells = tableCells(of: reparsed)
    try #require(originalCells.count == reparsedCells.count)

    for (originalCell, reparsedCell) in zip(originalCells, reparsedCells) {
      #expect(originalCell.startingRow == reparsedCell.startingRow)
      #expect(originalCell.startingColumn == reparsedCell.startingColumn)
      #expect(originalCell.rowSpan == reparsedCell.rowSpan)
      #expect(originalCell.columnSpan == reparsedCell.columnSpan)
    }
  }

  @Test("Cell and table styling round-trips")
  func stylingRoundTrip() throws {
    let (original, fragment, reparsed) = try roundTrip(
      "<table bgcolor=\"#FFEEDD\" cellpadding=\"5\"><tr>"
        + "<td bgcolor=\"#EEFFDD\" valign=\"top\">X</td><td width=\"120\">Y</td></tr></table>")

    #expect(fragment.contains("background-color:#ffeedd"))
    #expect(fragment.contains("background-color:#eeffdd"))
    #expect(fragment.contains("vertical-align:top"))
    #expect(fragment.contains("padding:5px"))
    #expect(fragment.contains("width:120px"))

    let originalCells = tableCells(of: original)
    let reparsedCells = tableCells(of: reparsed)
    try #require(originalCells.count == 2 && reparsedCells.count == 2)

    #expect(reparsedCells[0].table.backgroundColor == originalCells[0].table.backgroundColor)
    #expect(reparsedCells[0].backgroundColor == originalCells[0].backgroundColor)
    #expect(reparsedCells[0].verticalAlignment == .topAlignment)
    #expect(reparsedCells[0].width(for: .padding, edge: .minXEdge) == 5)
    #expect(reparsedCells[1].contentWidth == 120)
  }

  @Test("Borders and collapse mode round-trip")
  func bordersRoundTrip() throws {
    let (_, fragment, reparsed) = try roundTrip(
      "<table style=\"border-collapse: collapse\"><tr>"
        + "<td style=\"border: 2px solid #FF0000\">A</td><td>B</td></tr></table>")

    #expect(fragment.contains("border-collapse:collapse"))
    #expect(fragment.contains("border:2px solid #ff0000"))

    let cells = tableCells(of: reparsed)
    try #require(cells.count == 2)
    #expect(cells[0].table.collapsesBorders == true)
    #expect(cells[0].width(for: .border, edge: .minYEdge) == 2)
    #expect(cells[0].borderColor(for: .minYEdge) == DTColorCreateWithHTMLName("#FF0000"))
  }

  @Test("Border styles round-trip")
  func borderStylesRoundTrip() throws {
    let (_, fragment, reparsed) = try roundTrip(
      "<table><tr><td style=\"border: 2px dashed #FF0000\">dashed</td>"
        + "<td style=\"border: 3px double #0000FF\">double</td></tr></table>")

    #expect(fragment.contains("dashed"))
    #expect(fragment.contains("double"))

    let cells = tableCells(of: reparsed)
    try #require(cells.count == 2)
    #expect(cells[0].borderStyle(for: .minYEdge) == .dashed)
    #expect(cells[0].width(for: .border, edge: .minYEdge) == 2)
    #expect(cells[1].borderStyle(for: .minYEdge) == .double)
  }

  @Test("Cell spacing round-trips through border-spacing")
  func cellSpacingRoundTrip() throws {
    // legacy cellspacing attribute is normalized to CSS border-spacing
    let (_, fragment, reparsed) = try roundTrip(
      "<table cellspacing=\"10\"><tr><td>A</td><td>B</td></tr></table>")

    #expect(fragment.contains("border-spacing:10px"))

    let cells = tableCells(of: reparsed)
    try #require(cells.count == 2)
    #expect(cells[0].width(for: .margin, edge: .minXEdge) == 5)
    #expect(cells[0].width(for: .margin, edge: .minYEdge) == 5)

    // asymmetric spacing keeps both values
    let (_, asymmetricFragment, asymmetricReparsed) = try roundTrip(
      "<table style=\"border-spacing: 8px 4px\"><tr><td>A</td></tr></table>")

    #expect(asymmetricFragment.contains("border-spacing:8px 4px"))

    let asymmetricCells = tableCells(of: asymmetricReparsed)
    try #require(asymmetricCells.count == 1)
    #expect(asymmetricCells[0].width(for: .margin, edge: .minXEdge) == 4)
    #expect(asymmetricCells[0].width(for: .margin, edge: .maxXEdge) == 4)
    #expect(asymmetricCells[0].width(for: .margin, edge: .minYEdge) == 2)
    #expect(asymmetricCells[0].width(for: .margin, edge: .maxYEdge) == 2)

    // the default spacing stays implicit
    let (_, defaultFragment, defaultReparsed) = try roundTrip(
      "<table><tr><td>A</td></tr></table>")

    #expect(!defaultFragment.contains("border-spacing"))

    let defaultCells = tableCells(of: defaultReparsed)
    try #require(defaultCells.count == 1)
    #expect(defaultCells[0].width(for: .margin, edge: .minXEdge) == 0.5)
  }

  @Test("Percentage widths round-trip")
  func percentageWidthRoundTrip() throws {
    let (_, fragment, reparsed) = try roundTrip(
      "<table width=\"80%\"><tr><td width=\"50%\">half</td><td>rest</td></tr></table>")

    #expect(fragment.contains("width:80%"))
    #expect(fragment.contains("width:50%"))

    let cells = tableCells(of: reparsed)
    try #require(cells.count == 2)
    #expect(cells[0].table.contentWidth == 80)
    #expect(cells[0].table.contentWidthValueType == .percentageValueType)
    #expect(cells[0].contentWidth == 50)
    #expect(cells[0].contentWidthValueType == .percentageValueType)
  }

  @Test("Nested tables round-trip")
  func nestedTableRoundTrip() throws {
    let (original, fragment, reparsed) = try roundTrip(
      "<table><tr><td>Outer A<table><tr><td>Inner 1</td><td>Inner 2</td></tr></table>after inner</td><td>Outer B</td></tr></table>"
    )

    // two opening table tags
    #expect(fragment.components(separatedBy: "<table").count == 3)

    #expect(reparsed.string == original.string)

    let reparsedCells = tableCells(of: reparsed)
    try #require(reparsedCells.count == 4)

    // outer table has 2 columns, inner table has 2 columns, distinct instances
    let outerTable = reparsedCells[0].table
    let innerTable = reparsedCells[1].table
    #expect(innerTable !== outerTable)
    #expect(outerTable.numberOfColumns == 2)
    #expect(innerTable.numberOfColumns == 2)
  }

  @Test("Content before and after a table stays outside of it")
  func contentAroundTable() throws {
    let (_, fragment, reparsed) = try roundTrip(
      "<p>Before</p><table><tr><td>A</td></tr></table><p>After</p>")

    let tableStart = try #require(fragment.range(of: "<table"))
    let tableEnd = try #require(fragment.range(of: "</table>"))
    let beforeRange = try #require(fragment.range(of: "Before"))
    let afterRange = try #require(fragment.range(of: "After"))

    #expect(beforeRange.lowerBound < tableStart.lowerBound)
    #expect(afterRange.lowerBound > tableEnd.upperBound)

    #expect(reparsed.string == "Before\nA\nAfter\n")
  }
}
