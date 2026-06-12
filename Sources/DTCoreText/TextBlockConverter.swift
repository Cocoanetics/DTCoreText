//
//  TextBlockConverter.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.06.26.
//  Copyright (c) 2026 Drobnik.com. All rights reserved.
//

// The system text block classes live in AppKit on macOS. UIKit publishes the same
// classes (NSTextBlock, NSTextTable, NSTextTableBlock) with the iOS/tvOS/visionOS/
// watchOS 27 SDKs, first shipped with Xcode 27 (Swift 6.4). The compiler condition
// keeps this file building with older SDKs whose UIKit lacks the declarations.
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  import AppKit
#elseif canImport(UIKit) && compiler(>=6.4)
  import UIKit
#endif

#if (canImport(AppKit) && !targetEnvironment(macCatalyst)) || (canImport(UIKit) && compiler(>=6.4))

  /// Converts between the DT text block model classes and their system counterparts.
  ///
  /// The system expresses table membership through shared instances: all paragraphs of one
  /// cell share one `NSTextTableBlock` and all cells of one table share one `NSTextTable`.
  /// A converter instance therefore caches every object it has converted and returns the
  /// same output instance for the same input instance. Use one converter per attributed
  /// string (or per document) so that this identity mapping is preserved across paragraphs.
  ///
  /// On macOS the system classes come from AppKit and the converter is available on all
  /// supported versions. UIKit gains the same classes with iOS 27 (and the aligned tvOS,
  /// watchOS, visionOS and Mac Catalyst releases), so on those platforms the converter
  /// requires the 27 SDK at build time and the corresponding OS version at runtime.
  @available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *)
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

    // MARK: - Converting to the System Classes

    /// Converts a ``TextBlock``, ``TextTable`` or ``TextTableBlock`` to its system counterpart.
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
      // raw values are identical by design; numericCast bridges the differing
      // signedness of the imported enums across SDK versions
      result.layoutAlgorithm =
        NSTextTable.LayoutAlgorithm(rawValue: numericCast(table.layoutAlgorithm.rawValue))!
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

    // MARK: - Converting from the System Classes

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
        TextTable.LayoutAlgorithm(rawValue: numericCast(nsTable.layoutAlgorithm.rawValue))
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

    // MARK: - Converting Attributed Strings

    /// Returns a copy of the attributed string where every paragraph carrying the
    /// DTCoreText text blocks attribute also carries the equivalent system blocks in
    /// its `NSParagraphStyle.textBlocks`, ready for TextKit table layout.
    ///
    /// The DTCoreText attribute is left in place, so the result still renders through
    /// the CoreText layout as before.
    @objc(attributedStringByAddingNativeTextBlocksTo:)
    public func addingNativeTextBlocks(to attributedString: NSAttributedString)
      -> NSAttributedString
    {
      let result = NSMutableAttributedString(attributedString: attributedString)
      let blocksKey = NSAttributedString.Key(rawValue: DTTextBlocksAttribute)
      var newStyles = [(NSParagraphStyle, NSRange)]()

      result.enumerateAttribute(
        blocksKey, in: NSRange(location: 0, length: result.length), options: []
      ) { value, range, _ in
        guard let blocks = value as? [TextBlock], !blocks.isEmpty else {
          return
        }

        let nativeBlocks = nsTextBlocks(from: blocks)

        result.enumerateAttribute(.paragraphStyle, in: range, options: []) {
          styleValue, styleRange, _ in
          let style = (styleValue as? NSParagraphStyle) ?? NSParagraphStyle.default
          let mutableStyle = style.mutableCopy() as! NSMutableParagraphStyle
          mutableStyle.textBlocks = nativeBlocks
          newStyles.append((mutableStyle.copy() as! NSParagraphStyle, styleRange))
        }
      }

      for (style, range) in newStyles {
        result.addAttribute(.paragraphStyle, value: style, range: range)
      }

      return result
    }

    /// Returns a copy of the attributed string where every paragraph whose
    /// `NSParagraphStyle.textBlocks` contains system text blocks also carries the
    /// equivalent DT blocks in the DTCoreText text blocks attribute, ready for the
    /// CoreText table layout.
    ///
    /// The system blocks are left in place on the paragraph styles.
    @objc(attributedStringByAddingTextBlocksAttributeTo:)
    public func addingTextBlocksAttribute(to attributedString: NSAttributedString)
      -> NSAttributedString
    {
      let result = NSMutableAttributedString(attributedString: attributedString)
      let blocksKey = NSAttributedString.Key(rawValue: DTTextBlocksAttribute)
      var newBlocks = [([TextBlock], NSRange)]()

      result.enumerateAttribute(
        .paragraphStyle, in: NSRange(location: 0, length: result.length), options: []
      ) { value, range, _ in
        guard let style = value as? NSParagraphStyle, !style.textBlocks.isEmpty else {
          return
        }

        newBlocks.append((textBlocks(from: style.textBlocks), range))
      }

      for (blocks, range) in newBlocks {
        result.addAttribute(blocksKey, value: blocks, range: range)
      }

      return result
    }

    // MARK: - Property Copying

    private static func copyProperties(from block: TextBlock, to nsBlock: NSTextBlock) {
      for dimension in allDimensions {
        let nsDimension = NSTextBlock.Dimension(rawValue: numericCast(dimension.rawValue))!
        let nsType = NSTextBlock.ValueType(
          rawValue: numericCast(block.valueType(for: dimension).rawValue))!
        nsBlock.setValue(block.value(for: dimension), type: nsType, for: nsDimension)
      }

      for layer in allLayers {
        let nsLayer = NSTextBlock.Layer(rawValue: numericCast(layer.rawValue))!

        for edge in allEdges {
          let nsType = NSTextBlock.ValueType(
            rawValue: numericCast(block.widthValueType(for: layer, edge: edge).rawValue))!
          nsBlock.dt_setWidth(
            block.width(for: layer, edge: edge), type: nsType, for: nsLayer, edge: edge)
        }
      }

      for edge in allEdges {
        nsBlock.dt_setBorderColor(block.borderColor(for: edge), edge: edge)
      }

      nsBlock.backgroundColor = block.backgroundColor
      nsBlock.verticalAlignment = NSTextBlock.VerticalAlignment(
        rawValue: numericCast(block.verticalAlignment.rawValue))!
    }

    private static func copyProperties(from nsBlock: NSTextBlock, to block: TextBlock) {
      for dimension in allDimensions {
        let nsDimension = NSTextBlock.Dimension(rawValue: numericCast(dimension.rawValue))!
        let type = TextBlock.ValueType(
          rawValue: numericCast(nsBlock.valueType(for: nsDimension).rawValue))!
        block.setValue(nsBlock.value(for: nsDimension), type: type, for: dimension)
      }

      for layer in allLayers {
        let nsLayer = NSTextBlock.Layer(rawValue: numericCast(layer.rawValue))!

        for edge in allEdges {
          let type = TextBlock.ValueType(
            rawValue: numericCast(nsBlock.dt_widthValueType(for: nsLayer, edge: edge).rawValue))!
          block.setWidth(nsBlock.dt_width(for: nsLayer, edge: edge), type: type, for: layer, edge: edge)
        }
      }

      for edge in allEdges {
        block.setBorderColor(nsBlock.dt_borderColor(edge: edge), for: edge)
      }

      block.backgroundColor = nsBlock.backgroundColor
      block.verticalAlignment =
        TextBlock.VerticalAlignment(rawValue: numericCast(nsBlock.verticalAlignment.rawValue))
        ?? .topAlignment
    }
  }

  // MARK: - Per-Edge Accessor Shims

  // AppKit identifies box edges with NSRectEdge while the cross-platform API added in
  // the 27 SDKs uses CGRectEdge (identical raw values). These shims give the converter
  // one CGRectEdge-based spelling for both.
  @available(iOS 27.0, tvOS 27.0, watchOS 27.0, visionOS 27.0, macCatalyst 27.0, *)
  extension NSTextBlock {

    fileprivate func dt_setWidth(
      _ width: CGFloat, type: NSTextBlock.ValueType, for layer: NSTextBlock.Layer,
      edge: CGRectEdge
    ) {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        setWidth(width, type: type, for: layer, edge: NSRectEdge(rawValue: UInt(edge.rawValue))!)
      #else
        setWidth(width, type: type, for: layer, rectEdge: edge)
      #endif
    }

    fileprivate func dt_width(for layer: NSTextBlock.Layer, edge: CGRectEdge) -> CGFloat {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return width(for: layer, edge: NSRectEdge(rawValue: UInt(edge.rawValue))!)
      #else
        return width(for: layer, rectEdge: edge)
      #endif
    }

    fileprivate func dt_widthValueType(for layer: NSTextBlock.Layer, edge: CGRectEdge)
      -> NSTextBlock.ValueType
    {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return widthValueType(for: layer, edge: NSRectEdge(rawValue: UInt(edge.rawValue))!)
      #else
        return widthValueType(for: layer, rectEdge: edge)
      #endif
    }

    fileprivate func dt_setBorderColor(_ color: DTColor?, edge: CGRectEdge) {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        setBorderColor(color, for: NSRectEdge(rawValue: UInt(edge.rawValue))!)
      #else
        setBorderColor(color, rectEdge: edge)
      #endif
    }

    fileprivate func dt_borderColor(edge: CGRectEdge) -> DTColor? {
      #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return borderColor(for: NSRectEdge(rawValue: UInt(edge.rawValue))!)
      #else
        return borderColor(for: edge)
      #endif
    }
  }

#endif
