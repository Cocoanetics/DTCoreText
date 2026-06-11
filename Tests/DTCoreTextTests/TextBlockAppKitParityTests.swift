#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  import AppKit
  import Foundation
  import Testing

  @testable import DTCoreText

  /// Verifies that the DT text block model classes are exact mirrors of their AppKit
  /// counterparts: identical enum raw values, identical defaults, lossless conversion in
  /// both directions, and a faithful representation of what the system HTML importer
  /// produces. This suite is the executable form of the findings documented in the
  /// <doc:HTMLTablesOnMacOS> article.
  @Suite("AppKit Parity", .serialized)
  struct TextBlockAppKitParityTests {

    private static let allEdges: [CGRectEdge] = [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge]

    // MARK: - Enum raw value parity

    @Test("Dimension raw values match NSTextBlock.Dimension")
    func dimensionRawValues() {
      #expect(TextBlock.Dimension.width.rawValue == NSTextBlock.Dimension.width.rawValue)
      #expect(
        TextBlock.Dimension.minimumWidth.rawValue == NSTextBlock.Dimension.minimumWidth.rawValue)
      #expect(
        TextBlock.Dimension.maximumWidth.rawValue == NSTextBlock.Dimension.maximumWidth.rawValue)
      #expect(TextBlock.Dimension.height.rawValue == NSTextBlock.Dimension.height.rawValue)
      #expect(
        TextBlock.Dimension.minimumHeight.rawValue == NSTextBlock.Dimension.minimumHeight.rawValue)
      #expect(
        TextBlock.Dimension.maximumHeight.rawValue == NSTextBlock.Dimension.maximumHeight.rawValue)
    }

    @Test("ValueType raw values match NSTextBlock.ValueType")
    func valueTypeRawValues() {
      #expect(
        TextBlock.ValueType.absoluteValueType.rawValue
          == NSTextBlock.ValueType.absoluteValueType.rawValue)
      #expect(
        TextBlock.ValueType.percentageValueType.rawValue
          == NSTextBlock.ValueType.percentageValueType.rawValue)
    }

    @Test("Layer raw values match NSTextBlock.Layer")
    func layerRawValues() {
      #expect(TextBlock.Layer.padding.rawValue == NSTextBlock.Layer.padding.rawValue)
      #expect(TextBlock.Layer.border.rawValue == NSTextBlock.Layer.border.rawValue)
      #expect(TextBlock.Layer.margin.rawValue == NSTextBlock.Layer.margin.rawValue)
    }

    @Test("VerticalAlignment raw values match NSTextBlock.VerticalAlignment")
    func verticalAlignmentRawValues() {
      #expect(
        TextBlock.VerticalAlignment.topAlignment.rawValue
          == NSTextBlock.VerticalAlignment.topAlignment.rawValue)
      #expect(
        TextBlock.VerticalAlignment.middleAlignment.rawValue
          == NSTextBlock.VerticalAlignment.middleAlignment.rawValue)
      #expect(
        TextBlock.VerticalAlignment.bottomAlignment.rawValue
          == NSTextBlock.VerticalAlignment.bottomAlignment.rawValue)
      #expect(
        TextBlock.VerticalAlignment.baselineAlignment.rawValue
          == NSTextBlock.VerticalAlignment.baselineAlignment.rawValue)
    }

    @Test("LayoutAlgorithm raw values match NSTextTable.LayoutAlgorithm")
    func layoutAlgorithmRawValues() {
      #expect(
        TextTable.LayoutAlgorithm.automaticLayoutAlgorithm.rawValue
          == NSTextTable.LayoutAlgorithm.automaticLayoutAlgorithm.rawValue)
      #expect(
        TextTable.LayoutAlgorithm.fixedLayoutAlgorithm.rawValue
          == NSTextTable.LayoutAlgorithm.fixedLayoutAlgorithm.rawValue)
    }

    @Test("CGRectEdge raw values match NSRectEdge")
    func edgeRawValues() {
      #expect(UInt(CGRectEdge.minXEdge.rawValue) == NSRectEdge.minX.rawValue)
      #expect(UInt(CGRectEdge.minYEdge.rawValue) == NSRectEdge.minY.rawValue)
      #expect(UInt(CGRectEdge.maxXEdge.rawValue) == NSRectEdge.maxX.rawValue)
      #expect(UInt(CGRectEdge.maxYEdge.rawValue) == NSRectEdge.maxY.rawValue)
    }

    // MARK: - Property comparison helper

    /// Asserts that a DT block and an NSTextBlock carry identical block-level properties.
    private func expectEqualBlockProperties(
      _ block: TextBlock, _ nsBlock: NSTextBlock,
      sourceLocation: SourceLocation = #_sourceLocation
    ) {
      for dimension in [
        TextBlock.Dimension.width, .minimumWidth, .maximumWidth, .height, .minimumHeight,
        .maximumHeight,
      ] {
        let nsDimension = NSTextBlock.Dimension(rawValue: dimension.rawValue)!
        #expect(
          block.value(for: dimension) == nsBlock.value(for: nsDimension),
          "dimension \(dimension)", sourceLocation: sourceLocation)
        #expect(
          block.valueType(for: dimension).rawValue == nsBlock.valueType(for: nsDimension).rawValue,
          "dimension type \(dimension)", sourceLocation: sourceLocation)
      }

      for layer in [TextBlock.Layer.padding, .border, .margin] {
        let nsLayer = NSTextBlock.Layer(rawValue: layer.rawValue)!

        for edge in Self.allEdges {
          let nsEdge = NSRectEdge(rawValue: UInt(edge.rawValue))!
          #expect(
            block.width(for: layer, edge: edge) == nsBlock.width(for: nsLayer, edge: nsEdge),
            "layer \(layer) edge \(edge)", sourceLocation: sourceLocation)
          #expect(
            block.widthValueType(for: layer, edge: edge).rawValue
              == nsBlock.widthValueType(for: nsLayer, edge: nsEdge).rawValue,
            "layer type \(layer) edge \(edge)", sourceLocation: sourceLocation)
        }
      }

      for edge in Self.allEdges {
        let nsEdge = NSRectEdge(rawValue: UInt(edge.rawValue))!
        #expect(
          block.borderColor(for: edge) == nsBlock.borderColor(for: nsEdge),
          "border color edge \(edge)", sourceLocation: sourceLocation)
      }

      #expect(
        block.backgroundColor == nsBlock.backgroundColor, "background color",
        sourceLocation: sourceLocation)
      #expect(
        block.verticalAlignment.rawValue == nsBlock.verticalAlignment.rawValue,
        "vertical alignment", sourceLocation: sourceLocation)
    }

    // MARK: - Defaults and round-trip

    @Test("Freshly initialized blocks have identical defaults")
    func defaultsParity() {
      expectEqualBlockProperties(TextBlock(), NSTextBlock())

      let table = TextTable()
      let nsTable = NSTextTable()
      expectEqualBlockProperties(table, nsTable)
      #expect(table.numberOfColumns == nsTable.numberOfColumns)
      #expect(table.layoutAlgorithm.rawValue == nsTable.layoutAlgorithm.rawValue)
      #expect(table.collapsesBorders == nsTable.collapsesBorders)
      #expect(table.hidesEmptyCells == nsTable.hidesEmptyCells)
    }

    @Test("Conversion to AppKit and back is lossless")
    func conversionRoundTrip() throws {
      let table = TextTable()
      table.numberOfColumns = 3
      table.layoutAlgorithm = .fixedLayoutAlgorithm
      table.collapsesBorders = true
      table.hidesEmptyCells = true
      table.setValue(80, type: .percentageValueType, for: .width)
      table.setWidth(2, type: .absoluteValueType, for: .border)
      table.backgroundColor = NSColor.yellow

      let cell = TextTableBlock(
        table: table, startingRow: 1, rowSpan: 2, startingColumn: 0, columnSpan: 3)
      cell.setValue(120, type: .absoluteValueType, for: .width)
      cell.setValue(100, type: .absoluteValueType, for: .minimumWidth)
      cell.padding = DTEdgeInsets(top: 1, left: 4, bottom: 3, right: 2)
      cell.setWidth(0.5, type: .absoluteValueType, for: .margin)
      cell.setBorderColor(NSColor.red, for: .minYEdge)
      cell.setBorderColor(NSColor.blue, for: .maxXEdge)
      cell.verticalAlignment = .middleAlignment

      let toNS = TextBlockConverter()
      let nsCell = try #require(toNS.nsTextBlock(from: cell) as? NSTextTableBlock)

      // NS side carries identical properties
      expectEqualBlockProperties(cell, nsCell)
      expectEqualBlockProperties(table, nsCell.table)
      #expect(nsCell.startingRow == 1)
      #expect(nsCell.rowSpan == 2)
      #expect(nsCell.startingColumn == 0)
      #expect(nsCell.columnSpan == 3)
      #expect(nsCell.table.numberOfColumns == 3)
      #expect(nsCell.table.layoutAlgorithm == .fixedLayoutAlgorithm)
      #expect(nsCell.table.collapsesBorders == true)
      #expect(nsCell.table.hidesEmptyCells == true)

      // converting the same instance again returns the same NS instance
      #expect(toNS.nsTextBlock(from: cell) === nsCell)
      #expect(toNS.nsTextTable(from: table) === nsCell.table)

      // and back
      let toDT = TextBlockConverter()
      let backCell = try #require(toDT.textBlock(from: nsCell) as? TextTableBlock)

      expectEqualBlockProperties(backCell, nsCell)
      #expect(backCell.startingRow == cell.startingRow)
      #expect(backCell.rowSpan == cell.rowSpan)
      #expect(backCell.startingColumn == cell.startingColumn)
      #expect(backCell.columnSpan == cell.columnSpan)
      #expect(backCell.table.numberOfColumns == table.numberOfColumns)
      #expect(backCell.table.layoutAlgorithm == table.layoutAlgorithm)
      #expect(backCell.table.collapsesBorders == table.collapsesBorders)
      #expect(backCell.table.hidesEmptyCells == table.hidesEmptyCells)
      #expect(toDT.textBlock(from: nsCell) === backCell)
    }

    @Test("Table classes compare by identity like their AppKit counterparts")
    func identityEqualityParity() {
      // two value-identical tables are distinct objects on both sides
      #expect(NSTextTable() != NSTextTable())
      #expect(TextTable() != TextTable())

      let nsTable = NSTextTable()
      #expect(
        NSTextTableBlock(table: nsTable, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)
          != NSTextTableBlock(
            table: nsTable, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1))

      let table = TextTable()
      #expect(
        TextTableBlock(table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)
          != TextTableBlock(
            table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1))
    }

    // MARK: - System HTML importer fixtures

    /// Imports an HTML fragment via the system importer (the same call TextEdit uses).
    @MainActor
    private func systemAttributedString(fromHTML html: String) throws -> NSAttributedString {
      let data = Data(html.utf8)
      return try NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue,
        ],
        documentAttributes: nil)
    }

    /// The `textBlocks` array of the paragraph style governing each paragraph.
    private func paragraphTextBlocks(of attributedString: NSAttributedString) -> [[NSTextBlock]] {
      let nsString = attributedString.string as NSString
      var result = [[NSTextBlock]]()
      var location = 0

      while location < nsString.length {
        let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
        let style =
          attributedString.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil)
          as? NSParagraphStyle
        result.append(style?.textBlocks ?? [])
        location = NSMaxRange(paragraphRange)
      }

      return result
    }

    @Test("Simple 2x2 table: one shared table, one block per cell")
    @MainActor
    func importerSimpleTable() throws {
      let attributedString = try systemAttributedString(
        fromHTML:
          "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>")

      #expect(attributedString.string == "A1\nB1\nA2\nB2\n")

      let paragraphBlocks = paragraphTextBlocks(of: attributedString)
      #expect(paragraphBlocks.count == 4)

      let nsCells = paragraphBlocks.compactMap { $0.first as? NSTextTableBlock }
      try #require(nsCells.count == 4)

      // all cells share one table instance
      let nsTable = nsCells[0].table
      #expect(nsCells.allSatisfy { $0.table === nsTable })
      #expect(nsTable.numberOfColumns == 2)

      // grid coordinates in reading order
      #expect(nsCells.map { $0.startingRow } == [0, 0, 1, 1])
      #expect(nsCells.map { $0.startingColumn } == [0, 1, 0, 1])

      // convert to the DT model with one converter for the whole string
      let converter = TextBlockConverter()
      let cells = nsCells.compactMap { converter.textBlock(from: $0) as? TextTableBlock }
      try #require(cells.count == 4)

      // shared table identity survives the conversion
      let table = cells[0].table
      #expect(cells.allSatisfy { $0.table === table })
      #expect(table.numberOfColumns == 2)

      // importer defaults: padding 1pt, margin 0.5pt on every edge, middle alignment
      for (cell, nsCell) in zip(cells, nsCells) {
        for edge in Self.allEdges {
          #expect(cell.width(for: .padding, edge: edge) == 1)
          #expect(cell.width(for: .margin, edge: edge) == 0.5)
          #expect(cell.width(for: .border, edge: edge) == 0)
        }
        #expect(cell.verticalAlignment == .middleAlignment)
        #expect(cell.contentWidthValueType == .absoluteValueType)
        #expect(cell.contentWidth > 0)

        // full property parity with the system-imported original
        expectEqualBlockProperties(cell, nsCell)
        #expect(cell.startingRow == nsCell.startingRow)
        #expect(cell.startingColumn == nsCell.startingColumn)
      }
    }

    @Test("Column and row spans map to columnSpan/rowSpan")
    @MainActor
    func importerSpans() throws {
      let colspanString = try systemAttributedString(
        fromHTML:
          "<table><tr><td colspan=\"2\">Wide</td><td>C1</td></tr><tr><td>A2</td><td>B2</td><td>C2</td></tr></table>"
      )

      let colspanCells = paragraphTextBlocks(of: colspanString).compactMap {
        $0.first as? NSTextTableBlock
      }
      #expect(colspanCells.count == 5)
      #expect(colspanCells[0].columnSpan == 2)
      #expect(colspanCells[0].table.numberOfColumns == 3)

      // the cell after the span starts at the skipped grid index
      #expect(colspanCells[1].startingColumn == 2)

      let converter = TextBlockConverter()
      let wide = try #require(converter.textBlock(from: colspanCells[0]) as? TextTableBlock)
      #expect(wide.columnSpan == 2)
      #expect(wide.startingColumn == 0)

      let rowspanString = try systemAttributedString(
        fromHTML:
          "<table><tr><td rowspan=\"2\">Tall</td><td>B1</td></tr><tr><td>B2</td></tr></table>")

      let rowspanCells = paragraphTextBlocks(of: rowspanString).compactMap {
        $0.first as? NSTextTableBlock
      }

      // no placeholder block exists for the covered grid position
      #expect(rowspanCells.count == 3)
      #expect(rowspanCells[0].rowSpan == 2)
      #expect(rowspanCells[2].startingRow == 1)
      #expect(rowspanCells[2].startingColumn == 1)
    }

    @Test("Nested tables produce outermost-first block arrays with shared instances")
    @MainActor
    func importerNestedTables() throws {
      let attributedString = try systemAttributedString(
        fromHTML:
          "<table><tr><td>Outer A<table><tr><td>Inner 1</td><td>Inner 2</td></tr></table>after inner</td><td>Outer B</td></tr></table>"
      )

      let paragraphBlocks = paragraphTextBlocks(of: attributedString)
      #expect(paragraphBlocks.map { $0.count } == [1, 2, 2, 1, 1])

      // the outer cell block is the same instance wherever it appears
      let outerCell = try #require(paragraphBlocks[0].first as? NSTextTableBlock)
      #expect(paragraphBlocks[1][0] === outerCell)
      #expect(paragraphBlocks[2][0] === outerCell)
      #expect(paragraphBlocks[3][0] === outerCell)
      #expect(paragraphBlocks[4][0] !== outerCell)

      // inner cells belong to a different table than the outer cells
      let innerCell1 = try #require(paragraphBlocks[1][1] as? NSTextTableBlock)
      let innerCell2 = try #require(paragraphBlocks[2][1] as? NSTextTableBlock)
      #expect(innerCell1.table === innerCell2.table)
      #expect(innerCell1.table !== outerCell.table)

      // identity relationships survive conversion to the DT model
      let converter = TextBlockConverter()
      let convertedParagraphs = paragraphBlocks.map { converter.textBlocks(from: $0) }

      #expect(convertedParagraphs[1][0] === convertedParagraphs[0][0])
      #expect(convertedParagraphs[3][0] === convertedParagraphs[0][0])

      let convertedInner1 = try #require(convertedParagraphs[1][1] as? TextTableBlock)
      let convertedInner2 = try #require(convertedParagraphs[2][1] as? TextTableBlock)
      let convertedOuter = try #require(convertedParagraphs[0][0] as? TextTableBlock)
      #expect(convertedInner1.table === convertedInner2.table)
      #expect(convertedInner1.table !== convertedOuter.table)
    }

    @Test("Multi-paragraph cells share one block instance")
    @MainActor
    func importerMultiParagraphCell() throws {
      let attributedString = try systemAttributedString(
        fromHTML: "<table><tr><td><p>One</p><p>Two</p></td><td>B</td></tr></table>")

      let paragraphBlocks = paragraphTextBlocks(of: attributedString)
      #expect(paragraphBlocks.count == 3)
      #expect(paragraphBlocks[0].first === paragraphBlocks[1].first)
      #expect(paragraphBlocks[0].first !== paragraphBlocks[2].first)

      let converter = TextBlockConverter()
      let first = converter.textBlock(from: paragraphBlocks[0][0])
      let second = converter.textBlock(from: paragraphBlocks[1][0])
      #expect(first === second)
    }

    @Test("CSS box properties map onto layers, edges and colors")
    @MainActor
    func importerCSSBox() throws {
      let attributedString = try systemAttributedString(
        fromHTML: "<table style=\"border-collapse: collapse;\"><tr>"
          + "<td style=\"padding: 1px 2px 3px 4px; border-top: 1px solid #FF0000; border-right: 2px solid #00FF00; border-bottom: 3px solid #0000FF; border-left: 4px solid #FF00FF; background-color: #ABCDEF; width: 120px; vertical-align: baseline;\">styled</td>"
          + "<td>plain</td></tr></table>")

      let nsCell = try #require(
        paragraphTextBlocks(of: attributedString).first?.first as? NSTextTableBlock)

      let converter = TextBlockConverter()
      let cell = try #require(converter.textBlock(from: nsCell) as? TextTableBlock)

      // border-collapse lands on the table
      #expect(cell.table.collapsesBorders == true)

      // CSS padding order is top right bottom left; minX=left minY=top maxX=right maxY=bottom
      #expect(cell.width(for: .padding, edge: .minYEdge) == 1)
      #expect(cell.width(for: .padding, edge: .maxXEdge) == 2)
      #expect(cell.width(for: .padding, edge: .maxYEdge) == 3)
      #expect(cell.width(for: .padding, edge: .minXEdge) == 4)
      #expect(cell.padding.top == 1)
      #expect(cell.padding.right == 2)
      #expect(cell.padding.bottom == 3)
      #expect(cell.padding.left == 4)

      // per-edge border widths
      #expect(cell.width(for: .border, edge: .minYEdge) == 1)
      #expect(cell.width(for: .border, edge: .maxXEdge) == 2)
      #expect(cell.width(for: .border, edge: .maxYEdge) == 3)
      #expect(cell.width(for: .border, edge: .minXEdge) == 4)

      // per-edge border colors
      expectColor(cell.borderColor(for: .minYEdge), red: 1, green: 0, blue: 0)
      expectColor(cell.borderColor(for: .maxXEdge), red: 0, green: 1, blue: 0)
      expectColor(cell.borderColor(for: .maxYEdge), red: 0, green: 0, blue: 1)
      expectColor(cell.borderColor(for: .minXEdge), red: 1, green: 0, blue: 1)

      expectColor(
        cell.backgroundColor, red: 0xAB / 255.0, green: 0xCD / 255.0, blue: 0xEF / 255.0)

      #expect(cell.contentWidth == 120)
      #expect(cell.contentWidthValueType == .absoluteValueType)
      #expect(cell.verticalAlignment == .baselineAlignment)

      // round-trip back to AppKit preserves everything
      let backConverter = TextBlockConverter()
      expectEqualBlockProperties(cell, backConverter.nsTextBlock(from: cell))
    }

    private func expectColor(
      _ color: NSColor?, red: CGFloat, green: CGFloat, blue: CGFloat,
      sourceLocation: SourceLocation = #_sourceLocation
    ) {
      guard let rgb = color?.usingColorSpace(.sRGB) else {
        Issue.record("color is nil or not convertible", sourceLocation: sourceLocation)
        return
      }

      #expect(abs(rgb.redComponent - red) < 0.01, sourceLocation: sourceLocation)
      #expect(abs(rgb.greenComponent - green) < 0.01, sourceLocation: sourceLocation)
      #expect(abs(rgb.blueComponent - blue) < 0.01, sourceLocation: sourceLocation)
    }
  }

#endif
