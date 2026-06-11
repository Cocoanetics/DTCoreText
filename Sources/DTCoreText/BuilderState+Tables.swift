//
//  BuilderState+Tables.swift
//  DTCoreText
//
//  Created by Oliver Drobnik on 11.06.26.
//  Copyright (c) 2026 Drobnik.com. All rights reserved.
//

import CoreGraphics
import Foundation

/// Per-`<table>` state while building, kept on a stack to support nested tables.
internal final class TableBuildContext {

  /// The shared table instance that all cell blocks of this table reference.
  let table: TextTable

  /// The `<table>` element this context belongs to.
  let tableElement: HTMLElement

  /// The current row index; -1 before the first `<tr>`.
  var currentRowIndex = -1

  /// The next free column in the current row, before rowspan occupancy is considered.
  var nextColumnInRow = 0

  /// The highest grid column count seen so far.
  var maxColumns = 0

  /// Grid occupancy from rowspans: column index → last row index covered.
  var occupiedUntilRow = [Int: Int]()

  /// All cell blocks of this table, in document order.
  var cells = [TextTableBlock]()

  /// Raw width attribute strings from `<col>` elements, by column index.
  var columnWidths = [String]()

  /// Cell padding from the `cellpadding` attribute, when present.
  var cellPaddingAttribute: CGFloat?

  /// Margin to apply to every cell edge (half of the cell spacing).
  var cellMargin: CGFloat = 0.5

  /// Border width each cell gets when the table has a `border` attribute.
  var impliedCellBorderWidth: CGFloat = 0

  init(table: TextTable, tableElement: HTMLElement) {
    self.table = table
    self.tableElement = tableElement
  }
}

// MARK: - Table Tag Handling

extension BuilderState {

  private static let cssBorderStyleKeywords: Set<String> = [
    "none", "hidden", "dotted", "dashed", "solid", "double", "groove", "ridge", "inset", "outset",
  ]

  // MARK: Tag Handlers

  /// Handles the start of a `<table>` element: creates the shared ``TextTable`` and
  /// pushes a build context.
  func handleTableStart(_ tag: HTMLElement) {
    let table = TextTable()
    let styles = tag.currentStyles ?? [:]

    // the system importer always sets black border colors, even at zero width
    table.setBorderColor(DTColor.black)

    // background color: CSS background-color was already interpreted into the element;
    // legacy bgcolor attribute is the fallback. It lives on the table block, not on
    // text runs, so take it off the element before children inherit it.
    if let backgroundColor = tag.backgroundColor {
      table.backgroundColor = backgroundColor
      tag.backgroundColor = nil
    } else if let bgColorName = tag.attributeForKey("bgcolor"),
      let color = DTColorCreateWithHTMLName(bgColorName)
    {
      table.backgroundColor = color
    }

    // border attribute: N pt border on the table itself plus a 1 pt border on each cell
    var impliedCellBorderWidth: CGFloat = 0
    if let borderString = tag.attributeForKey("border") {
      let borderWidth = CGFloat(Double(borderString) ?? 1)
      if borderWidth > 0 {
        table.setWidth(borderWidth, type: .absoluteValueType, for: .border)
        impliedCellBorderWidth = 1
      }
    }

    // CSS borders, padding and margins on the table element
    applyCSSBorders(from: styles, to: table, element: tag)

    // border CSS was consumed into the block model; clear the background stroke
    // properties so descendants do not inherit them and create spurious blocks
    clearBackgroundStrokeProperties(of: tag)

    if stylesContainKey(styles, prefix: "padding") {
      table.padding = tag.padding
    }

    if stylesContainKey(styles, prefix: "margin") {
      let margins = tag.margins
      table.setWidth(margins.top, type: .absoluteValueType, for: .margin, edge: .minYEdge)
      table.setWidth(margins.left, type: .absoluteValueType, for: .margin, edge: .minXEdge)
      table.setWidth(margins.bottom, type: .absoluteValueType, for: .margin, edge: .maxYEdge)
      table.setWidth(margins.right, type: .absoluteValueType, for: .margin, edge: .maxXEdge)
    }

    // width from CSS or the legacy attribute
    applyWidthDimensions(to: table, element: tag, styles: styles)

    if (styles["border-collapse"] as? String)?.lowercased() == "collapse" {
      table.collapsesBorders = true
    }
    if (styles["empty-cells"] as? String)?.lowercased() == "hide" {
      table.hidesEmptyCells = true
    }
    if (styles["table-layout"] as? String)?.lowercased() == "fixed" {
      table.layoutAlgorithm = .fixedLayoutAlgorithm
    }

    let context = TableBuildContext(table: table, tableElement: tag)
    context.impliedCellBorderWidth = impliedCellBorderWidth

    if let cellPaddingString = tag.attributeForKey("cellpadding"),
      let cellPadding = Double(cellPaddingString)
    {
      context.cellPaddingAttribute = CGFloat(cellPadding)
    }

    if table.collapsesBorders {
      // collapsed tables have no spacing between cells
      context.cellMargin = 0
    } else if let cellSpacingString = tag.attributeForKey("cellspacing"),
      let cellSpacing = Double(cellSpacingString)
    {
      // the spacing is split between the two adjacent cells
      context.cellMargin = CGFloat(cellSpacing) / 2
    }

    tableStack.append(context)
  }

  /// Handles the end of a `<table>` element: finalizes the column count and applies
  /// `<col>` widths.
  func handleTableEnd() {
    guard let context = tableStack.popLast() else { return }

    context.table.numberOfColumns = context.maxColumns

    // apply <col> widths to single-span cells that have no width of their own
    guard !context.columnWidths.isEmpty else { return }

    for cell in context.cells {
      guard cell.columnSpan == 1,
        cell.value(for: .width) == 0,
        cell.startingColumn < context.columnWidths.count
      else { continue }

      let widthString = context.columnWidths[cell.startingColumn]
      if !widthString.isEmpty {
        applyDimension(.width, value: widthString, to: cell, element: context.tableElement)
      }
    }
  }

  /// Handles the start of a `<tr>` element.
  func handleTableRowStart(_ tag: HTMLElement) {
    guard let context = tableStack.last else { return }

    context.currentRowIndex += 1
    context.nextColumnInRow = 0
  }

  /// Handles a `<col>` element, recording its width for the corresponding column.
  func handleTableColumnStart(_ tag: HTMLElement) {
    guard let context = tableStack.last else { return }

    let span = max(Int(tag.attributeForKey("span") ?? "") ?? 1, 1)
    let width = tag.attributeForKey("width") ?? ""

    for _ in 0..<span {
      context.columnWidths.append(width)
    }
  }

  /// Handles the start of a `<td>` or `<th>` element: determines the grid position,
  /// creates the cell block with all box properties and attaches it to the element's
  /// paragraph style so that all descendants inherit it.
  func handleTableCellStart(_ tag: HTMLElement) {
    guard let context = tableStack.last else { return }

    // tolerate a missing <tr>
    if context.currentRowIndex < 0 {
      context.currentRowIndex = 0
    }

    // find the next free grid column, skipping positions covered by rowspans
    var column = context.nextColumnInRow
    while let occupied = context.occupiedUntilRow[column], occupied >= context.currentRowIndex {
      column += 1
    }

    let columnSpan = max(Int(tag.attributeForKey("colspan") ?? "") ?? 1, 1)
    let rowSpan = max(Int(tag.attributeForKey("rowspan") ?? "") ?? 1, 1)

    let cell = TextTableBlock(
      table: context.table,
      startingRow: context.currentRowIndex,
      rowSpan: rowSpan,
      startingColumn: column,
      columnSpan: columnSpan)

    if rowSpan > 1 {
      for coveredColumn in column..<(column + columnSpan) {
        context.occupiedUntilRow[coveredColumn] = context.currentRowIndex + rowSpan - 1
      }
    }

    context.nextColumnInRow = column + columnSpan
    context.maxColumns = max(context.maxColumns, column + columnSpan)

    configureCellBlock(cell, for: tag, context: context)

    context.cells.append(cell)

    // attach to the paragraph style; descendants inherit the array (outermost first)
    var textBlocks = tag.paragraphStyle.textBlocks ?? []
    textBlocks.append(cell)
    tag.paragraphStyle.textBlocks = textBlocks
  }

  // MARK: Cell Configuration

  private func configureCellBlock(
    _ cell: TextTableBlock, for tag: HTMLElement, context: TableBuildContext
  ) {
    let styles = tag.currentStyles ?? [:]

    // padding: own CSS > cellpadding attribute > 1 pt importer default
    if stylesContainKey(styles, prefix: "padding") {
      cell.padding = tag.padding
    } else if let cellPadding = context.cellPaddingAttribute {
      cell.setWidth(cellPadding, type: .absoluteValueType, for: .padding)
    } else {
      cell.setWidth(1, type: .absoluteValueType, for: .padding)
    }

    // margins express the cell spacing, split between neighbors
    if context.cellMargin > 0 {
      cell.setWidth(context.cellMargin, type: .absoluteValueType, for: .margin)
    }

    // borders: black by default, 1 pt when the table has a border attribute, CSS overrides
    cell.setBorderColor(DTColor.black)

    if context.impliedCellBorderWidth > 0 {
      cell.setWidth(context.impliedCellBorderWidth, type: .absoluteValueType, for: .border)
    }

    applyCSSBorders(from: styles, to: cell, element: tag)
    clearBackgroundStrokeProperties(of: tag)

    // background: CSS (own or inherited from the row) is already on the element;
    // legacy bgcolor attributes on the cell or an ancestor row are the fallback.
    // It lives on the block, so take it off the element before children inherit it.
    if let backgroundColor = tag.backgroundColor {
      cell.backgroundColor = backgroundColor
      tag.backgroundColor = nil
    } else if let attributeColor = legacyBackgroundColor(for: tag, context: context) {
      cell.backgroundColor = attributeColor
    }

    // vertical alignment: CSS > valign attribute (own or row) > middle importer default
    cell.verticalAlignment = .middleAlignment

    if let valign = legacyVerticalAlignment(for: tag, context: context) {
      cell.verticalAlignment = valign
    }

    if let cssAlignment = (styles["vertical-align"] as? String)?.lowercased() {
      switch cssAlignment {
      case "top": cell.verticalAlignment = .topAlignment
      case "middle": cell.verticalAlignment = .middleAlignment
      case "bottom": cell.verticalAlignment = .bottomAlignment
      case "baseline": cell.verticalAlignment = .baselineAlignment
      default: break
      }
    }

    // width, min-width, max-width
    applyWidthDimensions(to: cell, element: tag, styles: styles)
  }

  /// The background color from legacy `bgcolor` attributes: the cell's own, or the
  /// nearest ancestor row/row group within the same table.
  private func legacyBackgroundColor(for tag: HTMLElement, context: TableBuildContext) -> DTColor?
  {
    var element: HTMLElement? = tag

    while let currentElement = element, currentElement !== context.tableElement {
      if let colorName = currentElement.attributeForKey("bgcolor"),
        let color = DTColorCreateWithHTMLName(colorName)
      {
        return color
      }
      element = currentElement.parentElement()
    }

    return nil
  }

  /// The vertical alignment from legacy `valign` attributes: the cell's own, or the
  /// nearest ancestor row within the same table.
  private func legacyVerticalAlignment(for tag: HTMLElement, context: TableBuildContext)
    -> TextBlock.VerticalAlignment?
  {
    var element: HTMLElement? = tag

    while let currentElement = element, currentElement !== context.tableElement {
      if let valign = currentElement.attributeForKey("valign")?.lowercased() {
        switch valign {
        case "top": return .topAlignment
        case "middle", "center": return .middleAlignment
        case "bottom": return .bottomAlignment
        case "baseline": return .baselineAlignment
        default: break
        }
      }
      element = currentElement.parentElement()
    }

    return nil
  }

  // MARK: CSS Helpers

  /// Border CSS on table elements is represented in the block model; remove the
  /// background stroke interpretation so descendants don't inherit it.
  private func clearBackgroundStrokeProperties(of tag: HTMLElement) {
    tag.backgroundStrokeColor = nil
    tag.backgroundStrokeWidth = 0
    tag.backgroundCornerRadius = 0
  }

  private func stylesContainKey(_ styles: [String: Any], prefix: String) -> Bool {
    return styles.keys.contains { $0.hasPrefix(prefix) }
  }

  /// Applies width/min-width/max-width from CSS styles or the legacy `width` attribute
  /// as dimensions on the block. Percentages are preserved as percentage value types.
  private func applyWidthDimensions(
    to block: TextBlock, element: HTMLElement, styles: [String: Any]
  ) {
    if let widthString = styles["width"] as? String, widthString.lowercased() != "auto" {
      applyDimension(.width, value: widthString, to: block, element: element)
    } else if let widthAttribute = element.attributeForKey("width") {
      applyDimension(.width, value: widthAttribute, to: block, element: element)
    }

    if let minWidthString = styles["min-width"] as? String {
      applyDimension(.minimumWidth, value: minWidthString, to: block, element: element)
    }
    if let maxWidthString = styles["max-width"] as? String {
      applyDimension(.maximumWidth, value: maxWidthString, to: block, element: element)
    }
  }

  /// Sets a single dimension from a CSS measure or legacy attribute value, keeping
  /// percentages as percentage value types.
  func applyDimension(
    _ dimension: TextBlock.Dimension, value: String, to block: TextBlock, element: HTMLElement
  ) {
    let trimmed = value.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }

    if trimmed.hasSuffix("%") {
      if let percentage = Double(trimmed.dropLast().trimmingCharacters(in: .whitespaces)) {
        block.setValue(CGFloat(percentage), type: .percentageValueType, for: dimension)
      }
      return
    }

    let points = (trimmed as NSString).pixelSizeOfCSSMeasure(
      relativeToCurrentTextSize: element.fontDescriptor.pointSize, textScale: element.textScale)

    if points > 0 {
      block.setValue(points, type: .absoluteValueType, for: dimension)
    }
  }

  /// Maps a CSS border style keyword to the block model. `none`/`hidden` return nil
  /// (the border is removed); the 3D styles render as solid.
  private func borderStyle(forKeyword keyword: String) -> TextBlock.BorderStyle? {
    switch keyword {
    case "dashed": return .dashed
    case "dotted": return .dotted
    case "double": return .double
    case "solid", "groove", "ridge", "inset", "outset": return .solid
    default: return nil  // none, hidden
    }
  }

  /// Resolves a CSS border width component, including the keyword widths.
  private func borderWidth(fromComponent component: String, element: HTMLElement) -> CGFloat? {
    switch component {
    case "thin": return 1
    case "medium": return 3
    case "thick": return 5
    default:
      guard let firstCharacter = component.first, firstCharacter.isNumber || firstCharacter == "."
      else { return nil }
      return (component as NSString).pixelSizeOfCSSMeasure(
        relativeToCurrentTextSize: element.fontDescriptor.pointSize,
        textScale: element.textScale)
    }
  }

  /// Expands a 1–4 value CSS list to exactly four values in top/right/bottom/left order.
  private func expandFourValues(_ value: String) -> [String] {
    let parts = value.lowercased().components(separatedBy: .whitespaces).filter { !$0.isEmpty }

    switch parts.count {
    case 1: return [parts[0], parts[0], parts[0], parts[0]]
    case 2: return [parts[0], parts[1], parts[0], parts[1]]
    case 3: return [parts[0], parts[1], parts[2], parts[1]]
    case 4...: return Array(parts[0..<4])
    default: return []
    }
  }

  /// Applies CSS border properties (shorthands, 1–4 value lists and per-edge longhands)
  /// to the block's border layer, border colors and border styles.
  private func applyCSSBorders(from styles: [String: Any], to block: TextBlock, element: HTMLElement) {
    // CSS list order: top, right, bottom, left
    let edges: [(CGRectEdge, String)] = [
      (.minYEdge, "top"), (.maxXEdge, "right"), (.maxYEdge, "bottom"), (.minXEdge, "left"),
    ]

    func applyShorthand(_ value: String, to edgesToApply: [CGRectEdge]) {
      var width: CGFloat?
      var color: DTColor?
      var style: TextBlock.BorderStyle?
      var isHidden = false

      for component in value.lowercased().components(separatedBy: .whitespaces)
      where !component.isEmpty {
        if Self.cssBorderStyleKeywords.contains(component) {
          if let mappedStyle = borderStyle(forKeyword: component) {
            style = mappedStyle
          } else {
            isHidden = true
          }
          continue
        }

        if let parsedWidth = borderWidth(fromComponent: component, element: element) {
          width = parsedWidth
        } else if let parsedColor = DTColorCreateWithHTMLName(component) {
          color = parsedColor
        }
      }

      // CSS draws a medium (3px) border when a style is given without a width
      if width == nil && style != nil {
        width = 3
      }

      for edge in edgesToApply {
        if isHidden {
          block.setWidth(0, type: .absoluteValueType, for: .border, edge: edge)
          continue
        }
        if let width {
          block.setWidth(width, type: .absoluteValueType, for: .border, edge: edge)
        }
        if let color {
          block.setBorderColor(color, for: edge)
        }
        if let style {
          block.setBorderStyle(style, for: edge)
        }
      }
    }

    if let allBorders = styles["border"] as? String {
      applyShorthand(allBorders, to: edges.map { $0.0 })
    }

    // 1–4 value lists in top/right/bottom/left order
    if let widthList = styles["border-width"] as? String {
      for (index, component) in expandFourValues(widthList).enumerated() {
        if let width = borderWidth(fromComponent: component, element: element) {
          block.setWidth(width, type: .absoluteValueType, for: .border, edge: edges[index].0)
        }
      }
    }
    if let styleList = styles["border-style"] as? String {
      for (index, component) in expandFourValues(styleList).enumerated() {
        if let style = borderStyle(forKeyword: component) {
          block.setBorderStyle(style, for: edges[index].0)
          if block.width(for: .border, edge: edges[index].0) == 0 {
            block.setWidth(3, type: .absoluteValueType, for: .border, edge: edges[index].0)
          }
        } else if component == "none" || component == "hidden" {
          block.setWidth(0, type: .absoluteValueType, for: .border, edge: edges[index].0)
        }
      }
    }
    if let colorList = styles["border-color"] as? String {
      for (index, component) in expandFourValues(colorList).enumerated() {
        if let color = DTColorCreateWithHTMLName(component) {
          block.setBorderColor(color, for: edges[index].0)
        }
      }
    }

    for (edge, edgeName) in edges {
      if let edgeShorthand = styles["border-\(edgeName)"] as? String {
        applyShorthand(edgeShorthand, to: [edge])
      }
      if let edgeWidth = styles["border-\(edgeName)-width"] as? String,
        let width = borderWidth(fromComponent: edgeWidth.lowercased(), element: element)
      {
        block.setWidth(width, type: .absoluteValueType, for: .border, edge: edge)
      }
      if let edgeStyle = styles["border-\(edgeName)-style"] as? String {
        applyShorthand(edgeStyle, to: [edge])
      }
      if let edgeColor = styles["border-\(edgeName)-color"] as? String,
        let color = DTColorCreateWithHTMLName(edgeColor.lowercased())
      {
        block.setBorderColor(color, for: edge)
      }
    }
  }
}
