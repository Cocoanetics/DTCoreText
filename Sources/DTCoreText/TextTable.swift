//
//  TextTable.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.06.26.
//  Copyright (c) 2026 Drobnik.com. All rights reserved.
//

import Foundation

/// Class that represents a table of text blocks.
///
/// The API mirrors AppKit's `NSTextTable` (which iOS gains natively with iOS 27). One
/// instance is shared by all cells (``TextTableBlock``) of the same table; the shared
/// instance is what groups cells into a table, so it must not be copied or deduplicated.
@objc(DTTextTable)
public class TextTable: TextBlock {

  /// The table layout algorithm. Mirrors `NSTextTable.LayoutAlgorithm`.
  @objc(DTTextTableLayoutAlgorithm)
  public enum LayoutAlgorithm: UInt, Sendable {
    /// Column widths are determined by the content of the cells.
    case automaticLayoutAlgorithm = 0
    /// Column widths are fixed, based on the first row of the table.
    case fixedLayoutAlgorithm = 1
  }

  /// The number of columns in the table, including columns covered by spans.
  @objc public var numberOfColumns: Int = 0

  /// The algorithm to use when distributing column widths.
  @objc public var layoutAlgorithm: LayoutAlgorithm = .automaticLayoutAlgorithm

  /// Whether the borders of adjacent cells collapse into a single border.
  @objc public var collapsesBorders: Bool = false

  /// Whether cells without content are rendered.
  @objc public var hidesEmptyCells: Bool = false

  // MARK: - Initialization

  @objc public override init() {
    super.init()
  }

  // MARK: - NSCoding

  @objc public required init?(coder aDecoder: NSCoder) {
    numberOfColumns = aDecoder.decodeInteger(forKey: "numberOfColumns")
    layoutAlgorithm =
      LayoutAlgorithm(rawValue: UInt(aDecoder.decodeInteger(forKey: "layoutAlgorithm")))
      ?? .automaticLayoutAlgorithm
    collapsesBorders = aDecoder.decodeBool(forKey: "collapsesBorders")
    hidesEmptyCells = aDecoder.decodeBool(forKey: "hidesEmptyCells")

    super.init(coder: aDecoder)
  }

  @objc public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)

    aCoder.encode(numberOfColumns, forKey: "numberOfColumns")
    aCoder.encode(Int(layoutAlgorithm.rawValue), forKey: "layoutAlgorithm")
    aCoder.encode(collapsesBorders, forKey: "collapsesBorders")
    aCoder.encode(hidesEmptyCells, forKey: "hidesEmptyCells")
  }

  // MARK: - Equality

  // Identity equality, matching NSTextTable. This is load-bearing: Foundation uniques
  // value-equal attribute dictionaries globally across attributed strings, so two
  // equal-by-value tables would get merged into one shared instance, destroying the
  // identity grouping that defines which cells belong to which table.
  public override func isEqual(_ object: Any?) -> Bool {
    return (object as AnyObject?) === self
  }

  public override var hash: Int {
    return ObjectIdentifier(self).hashValue
  }
}
