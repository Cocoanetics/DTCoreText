// UIKit publishes NSTextBlock/NSTextTable/NSTextTableBlock with the iOS 27 SDK
// (Xcode 27, Swift 6.4); older SDKs lack the declarations entirely.
#if canImport(UIKit) && compiler(>=6.4)

  import Foundation
  import Testing
  import UIKit

  @testable import DTCoreText

  /// Verifies that the DT text block model classes mirror the UIKit text block classes
  /// that iOS 27 makes public, that conversion through ``TextBlockConverter`` is lossless
  /// and identity-preserving, and that an attributed string parsed by DTCoreText can be
  /// handed off to TextKit with native `NSParagraphStyle.textBlocks`.
  ///
  /// This is the UIKit counterpart of the AppKit parity suite; see <doc:HTMLTablesOnMacOS>
  /// for the empirical basis of the property mapping.
  ///
  /// `@available` is not permitted on `@Test`/`@Suite` declarations, so every test
  /// guards at runtime and silently passes on simulators older than the 27 releases.
  @Suite("UIKit Parity (iOS 27)", .serialized)
  struct TextBlockUIKitParityTests {

    private static let allEdges: [CGRectEdge] = [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge]

    /// Compares raw values across the differing integer types (the DT enums mirror the
    /// historical `NSUInteger` AppKit raw types, the UIKit enums use `NSInteger`).
    private func expectSameRawValue<L: RawRepresentable, R: RawRepresentable>(
      _ lhs: L, _ rhs: R, sourceLocation: SourceLocation = #_sourceLocation
    ) where L.RawValue: BinaryInteger, R.RawValue: BinaryInteger {
      #expect(Int(lhs.rawValue) == Int(rhs.rawValue), sourceLocation: sourceLocation)
    }

    // MARK: - Enum raw value parity

    @Test("Enum raw values match the UIKit text block enums")
    func enumRawValues() {
      expectSameRawValue(TextBlock.Dimension.width, NSTextBlock.Dimension.width)
      expectSameRawValue(TextBlock.Dimension.minimumWidth, NSTextBlock.Dimension.minimumWidth)
      expectSameRawValue(TextBlock.Dimension.maximumWidth, NSTextBlock.Dimension.maximumWidth)
      expectSameRawValue(TextBlock.Dimension.height, NSTextBlock.Dimension.height)
      expectSameRawValue(TextBlock.Dimension.minimumHeight, NSTextBlock.Dimension.minimumHeight)
      expectSameRawValue(TextBlock.Dimension.maximumHeight, NSTextBlock.Dimension.maximumHeight)

      expectSameRawValue(TextBlock.ValueType.absoluteValueType, NSTextBlock.ValueType.absolute)
      expectSameRawValue(TextBlock.ValueType.percentageValueType, NSTextBlock.ValueType.percentage)

      expectSameRawValue(TextBlock.Layer.padding, NSTextBlock.Layer.padding)
      expectSameRawValue(TextBlock.Layer.border, NSTextBlock.Layer.border)
      expectSameRawValue(TextBlock.Layer.margin, NSTextBlock.Layer.margin)

      expectSameRawValue(TextBlock.VerticalAlignment.topAlignment, NSTextBlock.VerticalAlignment.top)
      expectSameRawValue(
        TextBlock.VerticalAlignment.middleAlignment, NSTextBlock.VerticalAlignment.middle)
      expectSameRawValue(
        TextBlock.VerticalAlignment.bottomAlignment, NSTextBlock.VerticalAlignment.bottom)
      expectSameRawValue(
        TextBlock.VerticalAlignment.baselineAlignment, NSTextBlock.VerticalAlignment.baseline)

      expectSameRawValue(
        TextTable.LayoutAlgorithm.automaticLayoutAlgorithm, NSTextTable.LayoutAlgorithm.automatic)
      expectSameRawValue(
        TextTable.LayoutAlgorithm.fixedLayoutAlgorithm, NSTextTable.LayoutAlgorithm.fixed)
    }

    // MARK: - Property comparison helper

    /// Asserts that a DT block and a UIKit NSTextBlock carry identical block-level properties.
    @available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *)
    private func expectEqualBlockProperties(
      _ block: TextBlock, _ nsBlock: NSTextBlock,
      sourceLocation: SourceLocation = #_sourceLocation
    ) {
      for dimension in [
        TextBlock.Dimension.width, .minimumWidth, .maximumWidth, .height, .minimumHeight,
        .maximumHeight,
      ] {
        let nsDimension = NSTextBlock.Dimension(rawValue: numericCast(dimension.rawValue))!
        #expect(
          block.value(for: dimension) == nsBlock.value(for: nsDimension),
          "dimension \(dimension)", sourceLocation: sourceLocation)
        #expect(
          Int(block.valueType(for: dimension).rawValue)
            == Int(nsBlock.valueType(for: nsDimension).rawValue),
          "dimension type \(dimension)", sourceLocation: sourceLocation)
      }

      for layer in [TextBlock.Layer.padding, .border, .margin] {
        let nsLayer = NSTextBlock.Layer(rawValue: numericCast(layer.rawValue))!

        for edge in Self.allEdges {
          #expect(
            block.width(for: layer, edge: edge) == nsBlock.width(for: nsLayer, rectEdge: edge),
            "layer \(layer) edge \(edge)", sourceLocation: sourceLocation)
          #expect(
            Int(block.widthValueType(for: layer, edge: edge).rawValue)
              == Int(nsBlock.widthValueType(for: nsLayer, rectEdge: edge).rawValue),
            "layer type \(layer) edge \(edge)", sourceLocation: sourceLocation)
        }
      }

      for edge in Self.allEdges {
        #expect(
          block.borderColor(for: edge) == nsBlock.borderColor(for: edge),
          "border color edge \(edge)", sourceLocation: sourceLocation)
      }

      #expect(
        block.backgroundColor == nsBlock.backgroundColor, "background color",
        sourceLocation: sourceLocation)
      #expect(
        Int(block.verticalAlignment.rawValue) == Int(nsBlock.verticalAlignment.rawValue),
        "vertical alignment", sourceLocation: sourceLocation)
    }

    // MARK: - Defaults and round-trip

    @Test("Freshly initialized blocks have identical defaults")
    func defaultsParity() {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      expectEqualBlockProperties(TextBlock(), NSTextBlock())

      let table = TextTable()
      let nsTable = NSTextTable()
      expectEqualBlockProperties(table, nsTable)
      #expect(table.numberOfColumns == nsTable.numberOfColumns)
      expectSameRawValue(table.layoutAlgorithm, nsTable.layoutAlgorithm)
      #expect(table.collapsesBorders == nsTable.collapsesBorders)
      #expect(table.hidesEmptyCells == nsTable.hidesEmptyCells)
    }

    @Test("Conversion to UIKit and back is lossless")
    func conversionRoundTrip() throws {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      let table = TextTable()
      table.numberOfColumns = 3
      table.layoutAlgorithm = .fixedLayoutAlgorithm
      table.collapsesBorders = true
      table.hidesEmptyCells = true
      table.setValue(80, type: .percentageValueType, for: .width)
      table.setWidth(2, type: .absoluteValueType, for: .border)
      table.backgroundColor = UIColor.yellow

      let cell = TextTableBlock(
        table: table, startingRow: 1, rowSpan: 2, startingColumn: 0, columnSpan: 3)
      cell.setValue(120, type: .absoluteValueType, for: .width)
      cell.setValue(100, type: .absoluteValueType, for: .minimumWidth)
      cell.padding = DTEdgeInsets(top: 1, left: 4, bottom: 3, right: 2)
      cell.setWidth(0.5, type: .absoluteValueType, for: .margin)
      cell.setBorderColor(UIColor.red, for: .minYEdge)
      cell.setBorderColor(UIColor.blue, for: .maxXEdge)
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
      #expect(nsCell.table.layoutAlgorithm == .fixed)
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

    // MARK: - Attributed string handoff

    private static let sampleTableHTML =
      "<table border=\"1\" cellpadding=\"4\"><tr><td bgcolor=\"#FFEEEE\">A1</td><td>B1</td></tr>"
      + "<tr><td colspan=\"2\">wide</td></tr></table>"

    /// The `textBlocks` of the paragraph style governing each paragraph.
    private func paragraphNativeBlocks(of attributedString: NSAttributedString) -> [[NSTextBlock]] {
      let nsString = attributedString.string as NSString
      var result = [[NSTextBlock]]()
      var location = 0

      while location < nsString.length {
        let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
        let style =
          attributedString.attribute(
            .paragraphStyle, at: paragraphRange.location, effectiveRange: nil)
          as? NSParagraphStyle
        result.append(style?.textBlocks ?? [])
        location = NSMaxRange(paragraphRange)
      }

      return result
    }

    @Test("DTCoreText output converts to native paragraph style text blocks")
    func nativeHandoff() throws {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      let attributedString = try #require(
        TestHelpers.attributedString(fromHTML: Self.sampleTableHTML))

      // before the conversion no paragraph carries native blocks
      #expect(paragraphNativeBlocks(of: attributedString).allSatisfy { $0.isEmpty })

      let converter = TextBlockConverter()
      let native = converter.addingNativeTextBlocks(to: attributedString)

      // text content is unchanged
      #expect(native.string == attributedString.string)

      let paragraphBlocks = paragraphNativeBlocks(of: native)
      #expect(paragraphBlocks.count == 3)

      let nsCells = paragraphBlocks.compactMap { $0.first as? NSTextTableBlock }
      try #require(nsCells.count == 3)

      // all cells share one native table instance
      let nsTable = nsCells[0].table
      #expect(nsCells.allSatisfy { $0.table === nsTable })
      #expect(nsTable.numberOfColumns == 2)

      // grid coordinates and span
      #expect(nsCells.map { $0.startingRow } == [0, 0, 1])
      #expect(nsCells.map { $0.startingColumn } == [0, 1, 0])
      #expect(nsCells[2].columnSpan == 2)

      // box properties arrived on the native cells
      for nsCell in nsCells {
        for edge in Self.allEdges {
          #expect(nsCell.width(for: .padding, rectEdge: edge) == 4)
          #expect(nsCell.width(for: .border, rectEdge: edge) == 1)
        }
      }

      // the DT attribute is still in place, so the CoreText layout keeps working
      let blocksKey = NSAttributedString.Key(rawValue: DTTextBlocksAttribute)
      #expect(native.attribute(blocksKey, at: 0, effectiveRange: nil) != nil)

      // converting back from the native blocks restores the DT model losslessly
      let backConverter = TextBlockConverter()
      let restored = backConverter.addingTextBlocksAttribute(to: native)
      let restoredBlocks = restored.attribute(blocksKey, at: 0, effectiveRange: nil)
      let restoredCell = try #require((restoredBlocks as? [TextBlock])?.first as? TextTableBlock)
      expectEqualBlockProperties(restoredCell, nsCells[0])
      #expect(restoredCell.table.numberOfColumns == 2)
    }

    // MARK: - TextKit layout

    /// Lays out an attributed string with a TextKit 1 stack. The text storage is part of
    /// the return value because it owns the layout manager — without a strong reference
    /// the layout would be discarded as soon as this function returns.
    private func textKit1Layout(_ attributedString: NSAttributedString, width: CGFloat)
      -> (NSTextStorage, NSLayoutManager, NSTextContainer)
    {
      let storage = NSTextStorage(attributedString: attributedString)
      let layoutManager = NSLayoutManager()
      storage.addLayoutManager(layoutManager)

      let container = NSTextContainer(size: CGSize(width: width, height: 1_000_000))
      container.lineFragmentPadding = 0
      layoutManager.addTextContainer(container)
      layoutManager.ensureLayout(for: container)

      return (storage, layoutManager, container)
    }

    private func boundingRect(
      of substring: String, in attributedString: NSAttributedString,
      layoutManager: NSLayoutManager, container: NSTextContainer
    ) throws -> CGRect {
      let characterRange = (attributedString.string as NSString).range(of: substring)
      try #require(characterRange.location != NSNotFound)
      let glyphRange = layoutManager.glyphRange(
        forCharacterRange: characterRange, actualCharacterRange: nil)
      return layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
    }

    @Test("TextKit 1 lays out native table blocks side by side")
    func textKitLayout() throws {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      let attributedString = try #require(
        TestHelpers.attributedString(fromHTML: Self.sampleTableHTML))
      let native = TextBlockConverter().addingNativeTextBlocks(to: attributedString)

      let (storage, layoutManager, container) = textKit1Layout(native, width: 400)
      defer { _ = storage }

      let rectA1 = try boundingRect(
        of: "A1", in: native, layoutManager: layoutManager, container: container)
      let rectB1 = try boundingRect(
        of: "B1", in: native, layoutManager: layoutManager, container: container)
      let rectWide = try boundingRect(
        of: "wide", in: native, layoutManager: layoutManager, container: container)

      print("TEXTKIT LAYOUT: A1=\(rectA1) B1=\(rectB1) wide=\(rectWide)")

      // cells of one row are side by side: B1 sits to the right of A1 on the same line
      #expect(rectB1.minX >= rectA1.maxX)
      #expect(abs(rectB1.minY - rectA1.minY) < 1)

      // the spanning row is below the first row
      #expect(rectWide.minY > rectA1.maxY)

      // without the native blocks the same string stacks all cells vertically
      let (plainStorage, plainLayoutManager, plainContainer) = textKit1Layout(
        attributedString, width: 400)
      defer { _ = plainStorage }
      let plainA1 = try boundingRect(
        of: "A1", in: attributedString, layoutManager: plainLayoutManager,
        container: plainContainer)
      let plainB1 = try boundingRect(
        of: "B1", in: attributedString, layoutManager: plainLayoutManager,
        container: plainContainer)
      #expect(plainB1.minY > plainA1.maxY - 1)
    }

    @Test("TextKit 1 renders native table blocks to an image")
    func textKitRender() throws {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      let html =
        "<table border=\"1\" cellpadding=\"4\"><thead><tr><th>Name</th><th>Value</th></tr></thead>"
        + "<tbody><tr><td>Pi</td><td>3.14159</td></tr><tr><td bgcolor=\"#FFD8A8\">Euler</td>"
        + "<td>2.71828</td></tr></tbody></table>"
      let attributedString = try #require(TestHelpers.attributedString(fromHTML: html))
      let native = TextBlockConverter().addingNativeTextBlocks(to: attributedString)

      let width: CGFloat = 400
      let (storage, layoutManager, container) = textKit1Layout(native, width: width)
      defer { _ = storage }
      let usedRect = layoutManager.usedRect(for: container)
      try #require(usedRect.height > 0)

      let size = CGSize(width: width + 20, height: ceil(usedRect.maxY) + 20)
      let renderer = UIGraphicsImageRenderer(size: size)

      let image = renderer.image { rendererContext in
        UIColor.white.setFill()
        rendererContext.fill(CGRect(origin: .zero, size: size))

        let glyphRange = layoutManager.glyphRange(for: container)
        let origin = CGPoint(x: 10, y: 10)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: origin)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: origin)
      }

      // simulator test processes run on the host, so /tmp is the Mac's /tmp
      let outputDirectory = URL(fileURLWithPath: "/tmp/table-renders-ios27-native", isDirectory: true)
      try FileManager.default.createDirectory(
        at: outputDirectory, withIntermediateDirectories: true)
      let outputURL = outputDirectory.appendingPathComponent("textkit1-table.png")
      try #require(image.pngData()).write(to: outputURL)
      print("RENDERED: \(outputURL.path)")
    }

    // MARK: - System reader/writer

    @Test("System HTML writer emits a table for native text blocks")
    @MainActor
    func systemHTMLWriter() throws {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      let attributedString = try #require(
        TestHelpers.attributedString(fromHTML: Self.sampleTableHTML))
      let native = TextBlockConverter().addingNativeTextBlocks(to: attributedString)

      let data = try native.data(
        from: NSRange(location: 0, length: native.length),
        documentAttributes: [.documentType: NSAttributedString.DocumentType.html])
      let html = try #require(String(data: data, encoding: .utf8))

      print("SYSTEM WRITER OUTPUT: \(html)")
      #expect(html.contains("<table"))
    }

    @Test("System HTML reader produces native text blocks")
    @MainActor
    func systemHTMLReader() throws {
      guard #available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *) else {
        return
      }

      let data = Data(Self.sampleTableHTML.utf8)
      let imported = try NSAttributedString(
        data: data,
        options: [
          .documentType: NSAttributedString.DocumentType.html,
          .characterEncoding: String.Encoding.utf8.rawValue,
        ],
        documentAttributes: nil)

      let paragraphBlocks = paragraphNativeBlocks(of: imported)
      let nsCells = paragraphBlocks.compactMap { $0.first as? NSTextTableBlock }
      print("SYSTEM READER: string=\(imported.string.debugDescription) cells=\(nsCells.count)")

      try #require(!nsCells.isEmpty)

      // the imported blocks convert into the DT model for the CoreText layout
      let converter = TextBlockConverter()
      let restored = converter.addingTextBlocksAttribute(to: imported)
      let blocksKey = NSAttributedString.Key(rawValue: DTTextBlocksAttribute)
      let blocks = restored.attribute(blocksKey, at: 0, effectiveRange: nil) as? [TextBlock]
      #expect(blocks?.first is TextTableBlock)
    }
  }

#endif
