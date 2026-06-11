//
//  TextTableBlock.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.06.26.
//  Copyright (c) 2026 Drobnik.com. All rights reserved.
//

import Foundation

/// Class that represents one cell of a ``TextTable``.
///
/// The API mirrors AppKit's `NSTextTableBlock` (which iOS gains natively with iOS 27).
/// All paragraphs belonging to the same cell share one instance; the cells of one table
/// all reference the same shared ``TextTable`` instance.
@objc(DTTextTableBlock)
public class TextTableBlock: TextBlock {

  /// The table that the cell belongs to.
  @objc public private(set) var table: TextTable

  /// The first row of the table grid that the cell covers (0-based).
  @objc public private(set) var startingRow: Int

  /// The number of rows that the cell covers.
  @objc public private(set) var rowSpan: Int

  /// The first column of the table grid that the cell covers (0-based).
  @objc public private(set) var startingColumn: Int

  /// The number of columns that the cell covers.
  @objc public private(set) var columnSpan: Int

  // MARK: - Initialization

  /// Creates a cell block covering the given grid area of the given table.
  @objc(initWithTable:startingRow:rowSpan:startingColumn:columnSpan:)
  public init(table: TextTable, startingRow: Int, rowSpan: Int, startingColumn: Int, columnSpan: Int) {
    self.table = table
    self.startingRow = startingRow
    self.rowSpan = rowSpan
    self.startingColumn = startingColumn
    self.columnSpan = columnSpan

    super.init()
  }

  // MARK: - NSCoding

  @objc public required init?(coder aDecoder: NSCoder) {
    guard let table = aDecoder.decodeObject(forKey: "table") as? TextTable else {
      return nil
    }

    self.table = table
    startingRow = aDecoder.decodeInteger(forKey: "startingRow")
    rowSpan = aDecoder.decodeInteger(forKey: "rowSpan")
    startingColumn = aDecoder.decodeInteger(forKey: "startingColumn")
    columnSpan = aDecoder.decodeInteger(forKey: "columnSpan")

    super.init(coder: aDecoder)
  }

  @objc public override func encode(with aCoder: NSCoder) {
    super.encode(with: aCoder)

    aCoder.encode(table, forKey: "table")
    aCoder.encode(startingRow, forKey: "startingRow")
    aCoder.encode(rowSpan, forKey: "rowSpan")
    aCoder.encode(startingColumn, forKey: "startingColumn")
    aCoder.encode(columnSpan, forKey: "columnSpan")
  }

  // MARK: - Equality

  // Identity equality, matching NSTextTableBlock. This is load-bearing: Foundation
  // uniques value-equal attribute dictionaries globally across attributed strings, so
  // two equal-by-value cell blocks (even from different documents!) would get merged
  // into one shared instance, destroying the identity grouping that defines which
  // paragraphs belong to which cell.
  public override func isEqual(_ object: Any?) -> Bool {
    return (object as AnyObject?) === self
  }

  public override var hash: Int {
    return ObjectIdentifier(self).hashValue
  }
}
