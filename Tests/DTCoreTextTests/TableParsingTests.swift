import Foundation
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Tests for parsing HTML tables into the DT text block model, following the structure
/// the macOS system importer produces (documented in <doc:HTMLTablesOnMacOS>).
@Suite("Table Parsing", .serialized)
struct TableParsingTests {

  private let allEdges: [CGRectEdge] = [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge]

  // MARK: - Helpers

  private func parse(_ html: String) throws -> NSAttributedString {
    return try #require(TestHelpers.attributedString(fromHTML: html))
  }

  /// The text block arrays governing each paragraph, via the DTTextBlocks attribute.
  private func paragraphBlocks(of attributedString: NSAttributedString) -> [[TextBlock]] {
    let nsString = attributedString.string as NSString
    var result = [[TextBlock]]()
    var location = 0

    while location < nsString.length {
      let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
      let blocks =
        attributedString.attribute(
          NSAttributedString.Key(rawValue: DTTextBlocksAttribute), at: paragraphRange.location,
          effectiveRange: nil) as? [TextBlock]
      result.append(blocks ?? [])
      location = NSMaxRange(paragraphRange)
    }

    return result
  }

  private func tableCells(of attributedString: NSAttributedString) -> [TextTableBlock] {
    var cells = [TextTableBlock]()

    for blocks in paragraphBlocks(of: attributedString) {
      for case let cell as TextTableBlock in blocks where !cells.contains(where: { $0 === cell }) {
        cells.append(cell)
      }
    }

    return cells
  }

  // MARK: - Structure

  @Test("Simple 2x2 table produces one paragraph per cell and a shared table")
  func simpleTable() throws {
    let attributedString = try parse(
      "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>")

    #expect(attributedString.string == "A1\nB1\nA2\nB2\n")

    let blocks = paragraphBlocks(of: attributedString)
    #expect(blocks.map { $0.count } == [1, 1, 1, 1])

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 4)

    // one shared table instance
    let table = cells[0].table
    #expect(cells.allSatisfy { $0.table === table })
    #expect(table.numberOfColumns == 2)

    // grid coordinates in reading order
    #expect(cells.map { $0.startingRow } == [0, 0, 1, 1])
    #expect(cells.map { $0.startingColumn } == [0, 1, 0, 1])

    // importer-compatible defaults
    for cell in cells {
      for edge in allEdges {
        #expect(cell.width(for: .padding, edge: edge) == 1)
        #expect(cell.width(for: .margin, edge: edge) == 0.5)
        #expect(cell.width(for: .border, edge: edge) == 0)
        #expect(cell.borderColor(for: edge) == DTColor.black)
      }
      #expect(cell.verticalAlignment == .middleAlignment)
    }
  }

  @Test("Cell paragraphs share one block instance, multiple paragraphs included")
  func multiParagraphCell() throws {
    let attributedString = try parse(
      "<table><tr><td><p>One</p><p>Two</p></td><td>B</td></tr></table>")

    #expect(attributedString.string == "One\nTwo\nB\n")

    let blocks = paragraphBlocks(of: attributedString)
    try #require(blocks.map { $0.count } == [1, 1, 1])

    #expect(blocks[0][0] === blocks[1][0])
    #expect(blocks[0][0] !== blocks[2][0])
  }

  @Test("Empty cells produce a bare newline paragraph carrying the block")
  func emptyCell() throws {
    let attributedString = try parse("<table><tr><td></td><td>B</td></tr></table>")

    #expect(attributedString.string == "\nB\n")

    let blocks = paragraphBlocks(of: attributedString)
    try #require(blocks.map { $0.count } == [1, 1])

    let emptyCell = try #require(blocks[0][0] as? TextTableBlock)
    #expect(emptyCell.startingColumn == 0)
  }

  @Test("Caption becomes a centered paragraph outside the table structure")
  func caption() throws {
    let attributedString = try parse(
      "<table><caption>The Caption</caption><tr><td>A</td><td>B</td></tr></table>")

    #expect(attributedString.string == "The Caption\nA\nB\n")

    let blocks = paragraphBlocks(of: attributedString)
    #expect(blocks.map { $0.count } == [0, 1, 1])

    let style = try #require(
      attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
    #expect(style.alignment == .center)
  }

  @Test("Nested tables nest outermost-first with shared instances")
  func nestedTable() throws {
    let attributedString = try parse(
      "<table><tr><td>Outer A<table><tr><td>Inner 1</td><td>Inner 2</td></tr></table>after inner</td><td>Outer B</td></tr></table>"
    )

    #expect(attributedString.string == "Outer A\nInner 1\nInner 2\nafter inner\nOuter B\n")

    let blocks = paragraphBlocks(of: attributedString)
    #expect(blocks.map { $0.count } == [1, 2, 2, 1, 1])

    // the outer cell block is the same instance wherever it appears
    let outerCell = try #require(blocks[0].first as? TextTableBlock)
    #expect(blocks[1][0] === outerCell)
    #expect(blocks[2][0] === outerCell)
    #expect(blocks[3][0] === outerCell)
    #expect(blocks[4][0] !== outerCell)

    // inner cells share a table that is different from the outer one
    let inner1 = try #require(blocks[1][1] as? TextTableBlock)
    let inner2 = try #require(blocks[2][1] as? TextTableBlock)
    #expect(inner1.table === inner2.table)
    #expect(inner1.table !== outerCell.table)
    #expect(inner1.table.numberOfColumns == 2)
    #expect(outerCell.table.numberOfColumns == 2)
  }

  // MARK: - Grid Geometry

  @Test("Column spans skip grid positions")
  func colspan() throws {
    let attributedString = try parse(
      "<table><tr><td colspan=\"2\">Wide</td><td>C1</td></tr><tr><td>A2</td><td>B2</td><td>C2</td></tr></table>"
    )

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 5)

    #expect(cells[0].columnSpan == 2)
    #expect(cells[0].startingColumn == 0)
    #expect(cells[1].startingColumn == 2)
    #expect(cells[0].table.numberOfColumns == 3)

    #expect(cells[2].startingRow == 1)
    #expect(cells.map { $0.startingColumn } == [0, 2, 0, 1, 2])
  }

  @Test("Row spans cover grid positions in later rows")
  func rowspan() throws {
    let attributedString = try parse(
      "<table><tr><td rowspan=\"2\">Tall</td><td>B1</td></tr><tr><td>B2</td></tr></table>")

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 3)

    #expect(cells[0].rowSpan == 2)
    #expect(cells[0].startingColumn == 0)
    #expect(cells[1].startingColumn == 1)

    // the cell in the second row skips the position covered by the rowspan
    #expect(cells[2].startingRow == 1)
    #expect(cells[2].startingColumn == 1)

    #expect(cells[0].table.numberOfColumns == 2)
  }

  // MARK: - Header Cells

  @Test("Header cells get bold centered text")
  func headerCells() throws {
    let attributedString = try parse(
      "<table><thead><tr><th>Name</th></tr></thead><tbody><tr><td>Pi</td></tr></tbody></table>")

    #expect(attributedString.string == "Name\nPi\n")

    let style = try #require(
      attributedString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
    #expect(style.alignment == .center)

    let font = try #require(attributedString.attribute(.font, at: 0, effectiveRange: nil))
    let traits = CTFontGetSymbolicTraits(font as! CTFont)
    #expect(traits.contains(.traitBold))

    let cells = tableCells(of: attributedString)
    #expect(cells.count == 2)
    #expect(cells[0].startingRow == 0)
    #expect(cells[1].startingRow == 1)
  }

  // MARK: - Legacy Attributes

  @Test("Legacy table attributes map like the system importer")
  func legacyAttributes() throws {
    let attributedString = try parse(
      "<table border=\"2\" cellpadding=\"5\" cellspacing=\"3\" bgcolor=\"#FFEEDD\">"
        + "<tr bgcolor=\"#DDEEFF\"><td bgcolor=\"#EEFFDD\">X</td><td>Y</td></tr></table>")

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 2)

    let table = cells[0].table

    // border attribute: 2pt table border, 1pt cell borders
    for edge in allEdges {
      #expect(table.width(for: .border, edge: edge) == 2)
      #expect(cells[0].width(for: .border, edge: edge) == 1)
      #expect(cells[0].width(for: .padding, edge: edge) == 5)
      #expect(cells[0].width(for: .margin, edge: edge) == 1.5)
    }

    // backgrounds: table bgcolor on the table, cell bgcolor on the cell,
    // row bgcolor on cells without their own
    #expect(table.backgroundColor == DTColorCreateWithHTMLName("#FFEEDD"))
    #expect(cells[0].backgroundColor == DTColorCreateWithHTMLName("#EEFFDD"))
    #expect(cells[1].backgroundColor == DTColorCreateWithHTMLName("#DDEEFF"))

    // block backgrounds must not be run-level background attributes
    var runBackgrounds = 0
    attributedString.enumerateAttribute(
      .backgroundColor, in: NSRange(location: 0, length: attributedString.length)
    ) { value, _, _ in
      if value != nil { runBackgrounds += 1 }
    }
    #expect(runBackgrounds == 0)
  }

  @Test("Legacy valign attributes map to vertical alignment")
  func legacyValign() throws {
    let attributedString = try parse(
      "<table><tr valign=\"bottom\"><td valign=\"top\">a</td><td>b</td><td valign=\"baseline\">c</td></tr></table>"
    )

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 3)

    #expect(cells[0].verticalAlignment == .topAlignment)
    #expect(cells[1].verticalAlignment == .bottomAlignment)
    #expect(cells[2].verticalAlignment == .baselineAlignment)
  }

  // MARK: - CSS

  @Test("CSS box properties map onto layers, edges and colors")
  func cssBox() throws {
    let attributedString = try parse(
      "<table style=\"border-collapse: collapse;\"><tr>"
        + "<td style=\"padding: 1px 2px 3px 4px; border-top: 1px solid #FF0000; border-right: 2px solid #00FF00; border-bottom: 3px solid #0000FF; border-left: 4px solid #FF00FF; background-color: #ABCDEF; width: 120px; vertical-align: baseline;\">styled</td>"
        + "<td>plain</td></tr></table>")

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 2)

    let cell = cells[0]
    let table = cell.table

    #expect(table.collapsesBorders == true)

    // collapsed tables have no cell margins
    for edge in allEdges {
      #expect(cell.width(for: .margin, edge: edge) == 0)
    }

    // CSS padding order is top right bottom left
    #expect(cell.width(for: .padding, edge: .minYEdge) == 1)
    #expect(cell.width(for: .padding, edge: .maxXEdge) == 2)
    #expect(cell.width(for: .padding, edge: .maxYEdge) == 3)
    #expect(cell.width(for: .padding, edge: .minXEdge) == 4)

    // per-edge border widths and colors
    #expect(cell.width(for: .border, edge: .minYEdge) == 1)
    #expect(cell.width(for: .border, edge: .maxXEdge) == 2)
    #expect(cell.width(for: .border, edge: .maxYEdge) == 3)
    #expect(cell.width(for: .border, edge: .minXEdge) == 4)
    #expect(cell.borderColor(for: .minYEdge) == DTColorCreateWithHTMLName("#FF0000"))
    #expect(cell.borderColor(for: .maxXEdge) == DTColorCreateWithHTMLName("#00FF00"))
    #expect(cell.borderColor(for: .maxYEdge) == DTColorCreateWithHTMLName("#0000FF"))
    #expect(cell.borderColor(for: .minXEdge) == DTColorCreateWithHTMLName("#FF00FF"))

    #expect(cell.backgroundColor == DTColorCreateWithHTMLName("#ABCDEF"))

    #expect(cell.contentWidth == 120)
    #expect(cell.contentWidthValueType == .absoluteValueType)
    #expect(cell.verticalAlignment == .baselineAlignment)

    // the plain neighbor keeps the defaults
    #expect(cells[1].width(for: .padding, edge: .minXEdge) == 1)
    #expect(cells[1].verticalAlignment == .middleAlignment)
  }

  @Test("CSS border-spacing maps onto cell margins")
  func cssBorderSpacing() throws {
    // one value applies to both axes
    let uniform = try parse("<table style=\"border-spacing: 8px\"><tr><td>A</td></tr></table>")
    let uniformCells = tableCells(of: uniform)
    try #require(uniformCells.count == 1)
    for edge in allEdges {
      #expect(uniformCells[0].width(for: .margin, edge: edge) == 4)
    }

    // two values are horizontal then vertical
    let twoValue = try parse(
      "<table style=\"border-spacing: 8px 4px\"><tr><td>A</td></tr></table>")
    let twoValueCells = tableCells(of: twoValue)
    try #require(twoValueCells.count == 1)
    #expect(twoValueCells[0].width(for: .margin, edge: .minXEdge) == 4)
    #expect(twoValueCells[0].width(for: .margin, edge: .maxXEdge) == 4)
    #expect(twoValueCells[0].width(for: .margin, edge: .minYEdge) == 2)
    #expect(twoValueCells[0].width(for: .margin, edge: .maxYEdge) == 2)

    // CSS wins over the legacy cellspacing attribute
    let both = try parse(
      "<table cellspacing=\"10\" style=\"border-spacing: 8px\"><tr><td>A</td></tr></table>")
    let bothCells = tableCells(of: both)
    try #require(bothCells.count == 1)
    #expect(bothCells[0].width(for: .margin, edge: .minXEdge) == 4)

    // border-collapse ignores any spacing
    let collapsed = try parse(
      "<table style=\"border-collapse: collapse; border-spacing: 8px\"><tr><td>A</td></tr></table>")
    let collapsedCells = tableCells(of: collapsed)
    try #require(collapsedCells.count == 1)
    for edge in allEdges {
      #expect(collapsedCells[0].width(for: .margin, edge: edge) == 0)
    }
  }

  @Test("Border styles, multi-value lists and width keywords parse")
  func borderStylesAndLists() throws {
    let attributedString = try parse(
      "<table><tr>"
        + "<td style=\"border: 2px dashed #FF0000\">dashed</td>"
        + "<td style=\"border-style: dotted\">dotted default width</td>"
        + "<td style=\"border-width: 1px 2px 3px 4px; border-style: solid\">multi width</td>"
        + "<td style=\"border: thick solid #0000FF; border-left-style: double\">keywords</td>"
        + "<td style=\"border-color: #FF0000 #00FF00; border-style: solid; border-width: medium\">color list</td>"
        + "</tr></table>")

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 5)

    // border: 2px dashed red
    for edge in allEdges {
      #expect(cells[0].width(for: .border, edge: edge) == 2)
      #expect(cells[0].borderStyle(for: edge) == .dashed)
      #expect(cells[0].borderColor(for: edge) == DTColorCreateWithHTMLName("#FF0000"))
    }

    // border-style alone implies the medium (3px) width
    for edge in allEdges {
      #expect(cells[1].borderStyle(for: edge) == .dotted)
      #expect(cells[1].width(for: .border, edge: edge) == 3)
    }

    // border-width list is top right bottom left
    #expect(cells[2].width(for: .border, edge: .minYEdge) == 1)
    #expect(cells[2].width(for: .border, edge: .maxXEdge) == 2)
    #expect(cells[2].width(for: .border, edge: .maxYEdge) == 3)
    #expect(cells[2].width(for: .border, edge: .minXEdge) == 4)

    // thick keyword = 5px; per-edge style override
    #expect(cells[3].width(for: .border, edge: .minYEdge) == 5)
    #expect(cells[3].borderStyle(for: .minYEdge) == .solid)
    #expect(cells[3].borderStyle(for: .minXEdge) == .double)

    // two-value color list: top/bottom first, right/left second; medium = 3px
    #expect(cells[4].borderColor(for: .minYEdge) == DTColorCreateWithHTMLName("#FF0000"))
    #expect(cells[4].borderColor(for: .maxYEdge) == DTColorCreateWithHTMLName("#FF0000"))
    #expect(cells[4].borderColor(for: .maxXEdge) == DTColorCreateWithHTMLName("#00FF00"))
    #expect(cells[4].borderColor(for: .minXEdge) == DTColorCreateWithHTMLName("#00FF00"))
    #expect(cells[4].width(for: .border, edge: .minYEdge) == 3)
  }

  @Test("Percentage widths are preserved as percentage value types")
  func percentageWidths() throws {
    let attributedString = try parse(
      "<table width=\"80%\"><tr><td width=\"100\">fixed</td><td width=\"50%\">half</td></tr></table>"
    )

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 2)

    let table = cells[0].table
    #expect(table.contentWidth == 80)
    #expect(table.contentWidthValueType == .percentageValueType)

    #expect(cells[0].contentWidth == 100)
    #expect(cells[0].contentWidthValueType == .absoluteValueType)

    #expect(cells[1].contentWidth == 50)
    #expect(cells[1].contentWidthValueType == .percentageValueType)
  }

  @Test("Column element widths apply to spanned cells")
  func columnWidths() throws {
    let attributedString = try parse(
      "<table><colgroup><col width=\"120\"><col width=\"60\"></colgroup><tr><td>A</td><td>B</td></tr></table>"
    )

    #expect(attributedString.string == "A\nB\n")

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 2)

    #expect(cells[0].contentWidth == 120)
    #expect(cells[1].contentWidth == 60)
  }

  @Test("Fixed table layout and min/max widths")
  func fixedLayoutAndMinMax() throws {
    let attributedString = try parse(
      "<table style=\"table-layout: fixed; width: 300px\"><tr>"
        + "<td style=\"min-width: 100px\">min</td><td style=\"max-width: 30px\">maxed</td></tr></table>"
    )

    let cells = tableCells(of: attributedString)
    try #require(cells.count == 2)

    let table = cells[0].table
    #expect(table.layoutAlgorithm == .fixedLayoutAlgorithm)
    #expect(table.contentWidth == 300)

    #expect(cells[0].value(for: .minimumWidth) == 100)
    #expect(cells[1].value(for: .maximumWidth) == 30)
  }

  // MARK: - System Importer Comparison

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @Test("Grid structure matches the system importer for the same HTML")
    @MainActor
    func matchesSystemImporter() throws {
      let fixtures = [
        "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>",
        "<table><tr><td colspan=\"2\">Wide</td><td>C1</td></tr><tr><td>A2</td><td>B2</td><td>C2</td></tr></table>",
        "<table><tr><td rowspan=\"2\">Tall</td><td>B1</td></tr><tr><td>B2</td></tr></table>",
        "<table><tr><td><p>One</p><p>Two</p></td><td>B</td></tr></table>",
      ]

      for html in fixtures {
        let dtString = try parse(html)
        let dtCells = tableCells(of: dtString)

        let nsData = Data(html.utf8)
        let nsString = try NSAttributedString(
          data: nsData,
          options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
          ],
          documentAttributes: nil)

        // collect distinct system cells in order
        var nsCells = [NSTextTableBlock]()
        let nsStringContent = nsString.string as NSString
        var location = 0
        while location < nsStringContent.length {
          let paragraphRange = nsStringContent.paragraphRange(
            for: NSRange(location: location, length: 0))
          if let style = nsString.attribute(
            .paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle,
            let cell = style.textBlocks.last as? NSTextTableBlock,
            !nsCells.contains(where: { $0 === cell })
          {
            nsCells.append(cell)
          }
          location = NSMaxRange(paragraphRange)
        }

        // identical plain text
        #expect(dtString.string == nsString.string, "string for \(html)")

        // identical grid structure
        try #require(dtCells.count == nsCells.count, "cell count for \(html)")

        for (dtCell, nsCell) in zip(dtCells, nsCells) {
          #expect(dtCell.startingRow == nsCell.startingRow, "row for \(html)")
          #expect(dtCell.startingColumn == nsCell.startingColumn, "column for \(html)")
          #expect(dtCell.rowSpan == nsCell.rowSpan, "rowSpan for \(html)")
          #expect(dtCell.columnSpan == nsCell.columnSpan, "columnSpan for \(html)")
          #expect(
            dtCell.table.numberOfColumns == nsCell.table.numberOfColumns, "columns for \(html)")
          #expect(
            dtCell.verticalAlignment.rawValue == nsCell.verticalAlignment.rawValue,
            "valign for \(html)")

          for edge in allEdges {
            let nsEdge = NSRectEdge(rawValue: UInt(edge.rawValue))!
            #expect(
              dtCell.width(for: .padding, edge: edge)
                == nsCell.width(for: .padding, edge: nsEdge), "padding for \(html)")
            #expect(
              dtCell.width(for: .margin, edge: edge) == nsCell.width(for: .margin, edge: nsEdge),
              "margin for \(html)")
          }
        }
      }
    }
  #endif
}
