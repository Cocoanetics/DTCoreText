//
//  TextBlockConverter.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.06.26.
//  Copyright (c) 2026 Drobnik.com. All rights reserved.
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

  import AppKit

  /// Converts between the DT text block model classes and their AppKit counterparts.
  ///
  /// The system expresses table membership through shared instances: all paragraphs of one
  /// cell share one `NSTextTableBlock` and all cells of one table share one `NSTextTable`.
  /// A converter instance therefore caches every object it has converted and returns the
  /// same output instance for the same input instance. Use one converter per attributed
  /// string (or per document) so that this identity mapping is preserved across paragraphs.
  ///
  /// On iOS 27 and later the same conversions will be provided for the then-native UIKit
  /// counterparts of these classes.
  @objc(DTTextBlockConverter)
  public final class TextBlockConverter: NSObject {

    private static let allDimensions: [TextBlock.Dimension] = [
      .width, .minimumWidth, .maximumWidth, .height, .minimumHeight, .maximumHeight,
    ]

    private static let allLayers: [TextBlock.Layer] = [.padding, .border, .margin]

    private static let allEdges: [CGRectEdge] = [.minXEdge, .minYEdge, .maxXEdge, .maxYEdge]

    // identity maps for both directions
    private var nsTablesByTable = [ObjectIdentifier: NSTextTable]()
    private var tablesByNSTable = [ObjectIdentifier: TextTable]()
    private var nsBlocksByBlock = [ObjectIdentifier: NSTextBlock]()
    private var blocksByNSBlock = [ObjectIdentifier: TextBlock]()

    // MARK: - Converting to AppKit

    /// Converts a ``TextBlock``, ``TextTable`` or ``TextTableBlock`` to its AppKit counterpart.
    ///
    /// Repeated calls with the same instance return the same output instance.
    @objc public func nsTextBlock(from block: TextBlock) -> NSTextBlock {
      if let existing = nsBlocksByBlock[ObjectIdentifier(block)] {
        return existing
      }

      let result: NSTextBlock

      if let tableBlock = block as? TextTableBlock {
        result = NSTextTableBlock(
          table: nsTextTable(from: tableBlock.table),
          startingRow: tableBlock.startingRow,
          rowSpan: tableBlock.rowSpan,
          startingColumn: tableBlock.startingColumn,
          columnSpan: tableBlock.columnSpan)
      } else if let table = block as? TextTable {
        return nsTextTable(from: table)
      } else {
        result = NSTextBlock()
      }

      Self.copyProperties(from: block, to: result)
      nsBlocksByBlock[ObjectIdentifier(block)] = result

      return result
    }

    /// Converts a ``TextTable`` to an `NSTextTable`.
    ///
    /// Repeated calls with the same instance return the same output instance.
    @objc public func nsTextTable(from table: TextTable) -> NSTextTable {
      if let existing = nsTablesByTable[ObjectIdentifier(table)] {
        return existing
      }

      let result = NSTextTable()
      result.numberOfColumns = table.numberOfColumns
      result.layoutAlgorithm =
        NSTextTable.LayoutAlgorithm(rawValue: table.layoutAlgorithm.rawValue)
        ?? .automaticLayoutAlgorithm
      result.collapsesBorders = table.collapsesBorders
      result.hidesEmptyCells = table.hidesEmptyCells

      Self.copyProperties(from: table, to: result)
      nsTablesByTable[ObjectIdentifier(table)] = result

      return result
    }

    /// Converts an array of blocks, e.g. the `textBlocks` of one paragraph style.
    @objc public func nsTextBlocks(from blocks: [TextBlock]) -> [NSTextBlock] {
      return blocks.map { nsTextBlock(from: $0) }
    }

    // MARK: - Converting from AppKit

    /// Converts an `NSTextBlock`, `NSTextTable` or `NSTextTableBlock` to its DT counterpart.
    ///
    /// Repeated calls with the same instance return the same output instance.
    @objc public func textBlock(from nsBlock: NSTextBlock) -> TextBlock {
      if let existing = blocksByNSBlock[ObjectIdentifier(nsBlock)] {
        return existing
      }

      let result: TextBlock

      if let nsTableBlock = nsBlock as? NSTextTableBlock {
        result = TextTableBlock(
          table: textTable(from: nsTableBlock.table),
          startingRow: nsTableBlock.startingRow,
          rowSpan: nsTableBlock.rowSpan,
          startingColumn: nsTableBlock.startingColumn,
          columnSpan: nsTableBlock.columnSpan)
      } else if let nsTable = nsBlock as? NSTextTable {
        return textTable(from: nsTable)
      } else {
        result = TextBlock()
      }

      Self.copyProperties(from: nsBlock, to: result)
      blocksByNSBlock[ObjectIdentifier(nsBlock)] = result

      return result
    }

    /// Converts an `NSTextTable` to a ``TextTable``.
    ///
    /// Repeated calls with the same instance return the same output instance.
    @objc public func textTable(from nsTable: NSTextTable) -> TextTable {
      if let existing = tablesByNSTable[ObjectIdentifier(nsTable)] {
        return existing
      }

      let result = TextTable()
      result.numberOfColumns = nsTable.numberOfColumns
      result.layoutAlgorithm =
        TextTable.LayoutAlgorithm(rawValue: nsTable.layoutAlgorithm.rawValue)
        ?? .automaticLayoutAlgorithm
      result.collapsesBorders = nsTable.collapsesBorders
      result.hidesEmptyCells = nsTable.hidesEmptyCells

      Self.copyProperties(from: nsTable, to: result)
      tablesByNSTable[ObjectIdentifier(nsTable)] = result

      return result
    }

    /// Converts an array of blocks, e.g. the `textBlocks` of one `NSParagraphStyle`.
    @objc public func textBlocks(from nsBlocks: [NSTextBlock]) -> [TextBlock] {
      return nsBlocks.map { textBlock(from: $0) }
    }

    // MARK: - Property Copying

    private static func nsEdge(for edge: CGRectEdge) -> NSRectEdge {
      return NSRectEdge(rawValue: UInt(edge.rawValue))!
    }

    private static func copyProperties(from block: TextBlock, to nsBlock: NSTextBlock) {
      for dimension in allDimensions {
        let nsDimension = NSTextBlock.Dimension(rawValue: dimension.rawValue)!
        let nsType = NSTextBlock.ValueType(rawValue: block.valueType(for: dimension).rawValue)!
        nsBlock.setValue(block.value(for: dimension), type: nsType, for: nsDimension)
      }

      for layer in allLayers {
        let nsLayer = NSTextBlock.Layer(rawValue: layer.rawValue)!

        for edge in allEdges {
          let nsType = NSTextBlock.ValueType(
            rawValue: block.widthValueType(for: layer, edge: edge).rawValue)!
          nsBlock.setWidth(
            block.width(for: layer, edge: edge), type: nsType, for: nsLayer, edge: nsEdge(for: edge)
          )
        }
      }

      for edge in allEdges {
        nsBlock.setBorderColor(block.borderColor(for: edge), for: nsEdge(for: edge))
      }

      nsBlock.backgroundColor = block.backgroundColor
      nsBlock.verticalAlignment =
        NSTextBlock.VerticalAlignment(rawValue: block.verticalAlignment.rawValue) ?? .topAlignment
    }

    private static func copyProperties(from nsBlock: NSTextBlock, to block: TextBlock) {
      for dimension in allDimensions {
        let nsDimension = NSTextBlock.Dimension(rawValue: dimension.rawValue)!
        let type = TextBlock.ValueType(rawValue: nsBlock.valueType(for: nsDimension).rawValue)!
        block.setValue(nsBlock.value(for: nsDimension), type: type, for: dimension)
      }

      for layer in allLayers {
        let nsLayer = NSTextBlock.Layer(rawValue: layer.rawValue)!

        for edge in allEdges {
          let type = TextBlock.ValueType(
            rawValue: nsBlock.widthValueType(for: nsLayer, edge: nsEdge(for: edge)).rawValue)!
          block.setWidth(
            nsBlock.width(for: nsLayer, edge: nsEdge(for: edge)), type: type, for: layer, edge: edge
          )
        }
      }

      for edge in allEdges {
        block.setBorderColor(nsBlock.borderColor(for: nsEdge(for: edge)), for: edge)
      }

      block.backgroundColor = nsBlock.backgroundColor
      block.verticalAlignment =
        TextBlock.VerticalAlignment(rawValue: nsBlock.verticalAlignment.rawValue) ?? .topAlignment
    }
  }

#endif
