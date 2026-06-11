import Foundation
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Tests for the extended NSTextBlock-style API of `TextBlock` and the table model
/// classes `TextTable` and `TextTableBlock`.
@Suite("Text Table Model", .serialized)
struct TextTableTests {

  // MARK: - TextBlock extended API

  @Test("Dimensions store value and value type")
  func dimensions() {
    let block = TextBlock()

    // defaults
    #expect(block.value(for: .width) == 0)
    #expect(block.valueType(for: .width) == .absoluteValueType)
    #expect(block.verticalAlignment == .topAlignment)

    block.setValue(120, type: .absoluteValueType, for: .width)
    block.setValue(50, type: .percentageValueType, for: .maximumWidth)
    block.setValue(33, type: .absoluteValueType, for: .minimumHeight)

    #expect(block.value(for: .width) == 120)
    #expect(block.valueType(for: .width) == .absoluteValueType)
    #expect(block.value(for: .maximumWidth) == 50)
    #expect(block.valueType(for: .maximumWidth) == .percentageValueType)
    #expect(block.value(for: .minimumHeight) == 33)

    // dimensions are independent
    #expect(block.value(for: .minimumWidth) == 0)
    #expect(block.value(for: .height) == 0)

    block.setContentWidth(80, type: .percentageValueType)
    #expect(block.contentWidth == 80)
    #expect(block.contentWidthValueType == .percentageValueType)
  }

  @Test("Layer widths are stored per layer and edge")
  func layerWidths() {
    let block = TextBlock()

    block.setWidth(1, type: .absoluteValueType, for: .padding, edge: .minYEdge)
    block.setWidth(2, type: .absoluteValueType, for: .border, edge: .maxXEdge)
    block.setWidth(3, type: .percentageValueType, for: .margin, edge: .maxYEdge)

    #expect(block.width(for: .padding, edge: .minYEdge) == 1)
    #expect(block.width(for: .border, edge: .maxXEdge) == 2)
    #expect(block.width(for: .margin, edge: .maxYEdge) == 3)
    #expect(block.widthValueType(for: .margin, edge: .maxYEdge) == .percentageValueType)

    // other layer/edge combinations stay untouched
    #expect(block.width(for: .padding, edge: .maxXEdge) == 0)
    #expect(block.width(for: .border, edge: .minYEdge) == 0)

    // setting all edges at once
    block.setWidth(5, type: .absoluteValueType, for: .border)
    for edge: CGRectEdge in [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge] {
      #expect(block.width(for: .border, edge: edge) == 5)
    }
  }

  @Test("Padding convenience maps onto the padding layer")
  func paddingConvenience() {
    let block = TextBlock()
    block.padding = DTEdgeInsets(top: 1, left: 4, bottom: 3, right: 2)

    #expect(block.width(for: .padding, edge: .minYEdge) == 1)
    #expect(block.width(for: .padding, edge: .minXEdge) == 4)
    #expect(block.width(for: .padding, edge: .maxYEdge) == 3)
    #expect(block.width(for: .padding, edge: .maxXEdge) == 2)

    block.setWidth(10, type: .absoluteValueType, for: .padding, edge: .minYEdge)
    #expect(block.padding.top == 10)
    #expect(block.padding.left == 4)
  }

  @Test("Border colors are stored per edge")
  func borderColors() {
    let block = TextBlock()
    let red = DTColorCreateWithHTMLName("red")
    let blue = DTColorCreateWithHTMLName("blue")

    #expect(block.borderColor(for: .minXEdge) == nil)

    block.setBorderColor(red, for: .minYEdge)
    #expect(block.borderColor(for: .minYEdge) == red)
    #expect(block.borderColor(for: .maxYEdge) == nil)

    block.setBorderColor(blue)
    for edge: CGRectEdge in [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge] {
      #expect(block.borderColor(for: edge) == blue)
    }
  }

  @Test("Equality covers the extended properties")
  func extendedEquality() {
    let block1 = TextBlock()
    let block2 = TextBlock()
    #expect(block1 == block2)

    block1.setValue(100, type: .absoluteValueType, for: .width)
    #expect(block1 != block2)

    block2.setValue(100, type: .absoluteValueType, for: .width)
    #expect(block1 == block2)

    // same value, different value type
    block2.setValue(100, type: .percentageValueType, for: .width)
    #expect(block1 != block2)
    block2.setValue(100, type: .absoluteValueType, for: .width)

    block1.verticalAlignment = .middleAlignment
    #expect(block1 != block2)
    block2.verticalAlignment = .middleAlignment
    #expect(block1 == block2)

    block1.setBorderColor(DTColorCreateWithHTMLName("red"), for: .minXEdge)
    #expect(block1 != block2)
    block2.setBorderColor(DTColorCreateWithHTMLName("red"), for: .minXEdge)
    #expect(block1 == block2)
  }

  @Test("Different block classes are never equal")
  func classMismatchInequality() {
    let block = TextBlock()
    let table = TextTable()
    let cell = TextTableBlock(table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)

    #expect(block != table)
    #expect(table != block)
    #expect(block != cell)
    #expect(cell != block)
  }

  // MARK: - TextTable

  @Test("Table properties and identity equality")
  func tableProperties() {
    let table = TextTable()

    // defaults
    #expect(table.numberOfColumns == 0)
    #expect(table.layoutAlgorithm == .automaticLayoutAlgorithm)
    #expect(table.collapsesBorders == false)
    #expect(table.hidesEmptyCells == false)

    table.numberOfColumns = 3
    table.layoutAlgorithm = .fixedLayoutAlgorithm
    table.collapsesBorders = true
    table.hidesEmptyCells = true

    #expect(table.numberOfColumns == 3)
    #expect(table.layoutAlgorithm == .fixedLayoutAlgorithm)

    // tables compare by identity like NSTextTable: identical properties are still
    // distinct tables (Foundation uniques value-equal attribute dictionaries, which
    // would otherwise merge separate tables)
    let other = TextTable()
    other.numberOfColumns = 3
    other.layoutAlgorithm = .fixedLayoutAlgorithm
    other.collapsesBorders = true
    other.hidesEmptyCells = true
    #expect(table != other)
    #expect(table == table)

    let cellA = TextTableBlock(table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)
    let cellB = TextTableBlock(table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)
    #expect(cellA != cellB)
    #expect(cellA == cellA)
  }

  @Test("Table block carries grid geometry")
  func tableBlockGeometry() {
    let table = TextTable()
    table.numberOfColumns = 3

    let cell = TextTableBlock(table: table, startingRow: 1, rowSpan: 2, startingColumn: 0, columnSpan: 3)

    #expect(cell.table === table)
    #expect(cell.startingRow == 1)
    #expect(cell.rowSpan == 2)
    #expect(cell.startingColumn == 0)
    #expect(cell.columnSpan == 3)
  }

  // MARK: - NSCoding

  private func archiveRoundTrip<T: NSObject & NSCoding>(_ object: T) throws -> T {
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: object, requiringSecureCoding: false)
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
    unarchiver.requiresSecureCoding = false
    let result = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as! T
    return result
  }

  @Test("NSCoding round-trip preserves extended properties")
  func codingExtendedProperties() throws {
    let block = TextBlock()
    block.setValue(120, type: .absoluteValueType, for: .width)
    block.setValue(50, type: .percentageValueType, for: .maximumWidth)
    block.setWidth(1, type: .absoluteValueType, for: .padding, edge: .minYEdge)
    block.setWidth(2.5, type: .absoluteValueType, for: .margin)
    block.setWidth(4, type: .percentageValueType, for: .border, edge: .maxXEdge)
    block.setBorderColor(DTColorCreateWithHTMLName("red"), for: .minYEdge)
    block.setBorderStyle(.dashed, for: .minYEdge)
    block.setBorderStyle(.double, for: .maxXEdge)
    block.backgroundColor = DTColorCreateWithHTMLName("yellow")
    block.verticalAlignment = .baselineAlignment

    let unarchived = try archiveRoundTrip(block)

    #expect(unarchived == block)
    #expect(unarchived.borderStyle(for: .minYEdge) == .dashed)
    #expect(unarchived.borderStyle(for: .maxXEdge) == .double)
    #expect(unarchived.borderStyle(for: .maxYEdge) == .solid)
    #expect(unarchived.value(for: .maximumWidth) == 50)
    #expect(unarchived.valueType(for: .maximumWidth) == .percentageValueType)
    #expect(unarchived.widthValueType(for: .border, edge: .maxXEdge) == .percentageValueType)
    #expect(unarchived.verticalAlignment == .baselineAlignment)
  }

  @Test("Legacy archives with only padding and background color stay readable")
  func codingLegacyFormat() throws {
    let payload = LegacyTextBlockPayload(
      insets: DTEdgeInsets(top: 10, left: 20, bottom: 30, right: 40),
      color: DTColorCreateWithHTMLName("red"))

    let archiver = NSKeyedArchiver(requiringSecureCoding: false)
    archiver.setClassName("DTTextBlock", for: LegacyTextBlockPayload.self)
    archiver.encode(payload, forKey: NSKeyedArchiveRootObjectKey)
    archiver.finishEncoding()

    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
    unarchiver.requiresSecureCoding = false
    let block = try #require(
      unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? TextBlock)

    #expect(block.padding.top == 10)
    #expect(block.padding.left == 20)
    #expect(block.padding.bottom == 30)
    #expect(block.padding.right == 40)
    #expect(block.backgroundColor == DTColorCreateWithHTMLName("red"))
    #expect(block.verticalAlignment == .topAlignment)
  }

  @Test("NSCoding round-trip preserves table properties")
  func codingTable() throws {
    let table = TextTable()
    table.numberOfColumns = 4
    table.layoutAlgorithm = .fixedLayoutAlgorithm
    table.collapsesBorders = true
    table.hidesEmptyCells = true
    table.setWidth(2, type: .absoluteValueType, for: .border)
    table.backgroundColor = DTColorCreateWithHTMLName("yellow")

    let unarchived = try archiveRoundTrip(table)

    #expect(unarchived.numberOfColumns == 4)
    #expect(unarchived.layoutAlgorithm == .fixedLayoutAlgorithm)
    #expect(unarchived.collapsesBorders == true)
    #expect(unarchived.hidesEmptyCells == true)
    #expect(unarchived.width(for: .border, edge: .minXEdge) == 2)
    #expect(unarchived.backgroundColor == DTColorCreateWithHTMLName("yellow"))
  }

  @Test("NSCoding preserves the shared table instance across cells")
  func codingSharedTableIdentity() throws {
    let table = TextTable()
    table.numberOfColumns = 2

    let cellA = TextTableBlock(
      table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1)
    let cellB = TextTableBlock(
      table: table, startingRow: 0, rowSpan: 1, startingColumn: 1, columnSpan: 2)

    let data = try NSKeyedArchiver.archivedData(
      withRootObject: [cellA, cellB], requiringSecureCoding: false)
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
    unarchiver.requiresSecureCoding = false
    let cells = try #require(
      unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [TextTableBlock])

    #expect(cells.count == 2)
    #expect(cells[0].table === cells[1].table)
    #expect(cells[0].table.numberOfColumns == 2)
    #expect(cells[0].startingColumn == 0)
    #expect(cells[1].startingColumn == 1)
    #expect(cells[1].columnSpan == 2)
    #expect(cells[0].startingRow == cellA.startingRow)
    #expect(cells[1].rowSpan == cellB.rowSpan)
  }
}

/// Encodes only the keys that pre-table versions of DTCoreText wrote for a DTTextBlock,
/// to simulate decoding a legacy archive.
@objc(DTTestLegacyTextBlockPayload)
private final class LegacyTextBlockPayload: NSObject, NSCoding {
  let insets: DTEdgeInsets
  let color: DTColor?

  init(insets: DTEdgeInsets, color: DTColor?) {
    self.insets = insets
    self.color = color
  }

  func encode(with coder: NSCoder) {
    coder.encodeDTEdgeInsets(insets, forKey: "padding")
    coder.encode(color, forKey: "backgroundColor")
  }

  required init?(coder: NSCoder) {
    return nil
  }
}
