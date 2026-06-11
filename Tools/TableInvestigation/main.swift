#!/usr/bin/env swift
//
//  main.swift
//  TableInvestigation
//
//  Investigates how the macOS system HTML importer (NSAttributedString with
//  NSHTMLTextDocumentType) represents HTML tables in attributed strings:
//  NSTextTable, NSTextTableBlock and plain NSTextBlock instances inside
//  NSParagraphStyle.textBlocks.
//
//  This is the empirical basis for the DT* compatibility layer that mirrors
//  these classes on iOS (pre iOS 27). See GitHub issue #1317.
//
//  Run with: swift Tools/TableInvestigation/main.swift
//

import AppKit

// MARK: - Identity registries (to observe instance sharing)

var tableIDs: [ObjectIdentifier: String] = [:]
var blockIDs: [ObjectIdentifier: String] = [:]
var orderedTables: [NSTextTable] = []
var orderedBlocks: [NSTextBlock] = []

func register(_ block: NSTextBlock) -> String {
  let oid = ObjectIdentifier(block)

  if let table = block as? NSTextTable {
    if let existing = tableIDs[oid] { return existing }
    let name = "T\(orderedTables.count + 1)"
    tableIDs[oid] = name
    orderedTables.append(table)
    return name
  }

  if let existing = blockIDs[oid] { return existing }
  let name = "B\(orderedBlocks.count + 1)"
  blockIDs[oid] = name
  orderedBlocks.append(block)
  return name
}

func resetRegistries() {
  tableIDs.removeAll()
  blockIDs.removeAll()
  orderedTables.removeAll()
  orderedBlocks.removeAll()
}

// MARK: - Formatting helpers

func fmt(_ value: CGFloat) -> String {
  return String(format: "%g", Double(value))
}

func escaped(_ string: String) -> String {
  var result = ""
  for character in string.unicodeScalars {
    switch character {
    case "\n": result += "\\n"
    case "\r": result += "\\r"
    case "\t": result += "\\t"
    case "\u{FFFC}": result += "[OBJ]"
    case "\u{00A0}": result += "[NBSP]"
    case "\u{2028}": result += "[LSEP]"
    case "\u{2029}": result += "[PSEP]"
    default: result.unicodeScalars.append(character)
    }
  }
  return result
}

func describe(_ color: NSColor?) -> String {
  guard let color = color else { return "nil" }
  guard let rgb = color.usingColorSpace(.sRGB) else { return "\(color)" }
  return String(
    format: "#%02X%02X%02X a=%.2f",
    Int(round(rgb.redComponent * 255)),
    Int(round(rgb.greenComponent * 255)),
    Int(round(rgb.blueComponent * 255)),
    Double(rgb.alphaComponent))
}

func name(of valueType: NSTextBlock.ValueType) -> String {
  switch valueType {
  case .absoluteValueType: return "abs"
  case .percentageValueType: return "%"
  @unknown default: return "?(\(valueType.rawValue))"
  }
}

func name(of alignment: NSTextBlock.VerticalAlignment) -> String {
  switch alignment {
  case .topAlignment: return "top"
  case .middleAlignment: return "middle"
  case .bottomAlignment: return "bottom"
  case .baselineAlignment: return "baseline"
  @unknown default: return "?(\(alignment.rawValue))"
  }
}

func name(of algorithm: NSTextTable.LayoutAlgorithm) -> String {
  switch algorithm {
  case .automaticLayoutAlgorithm: return "automatic"
  case .fixedLayoutAlgorithm: return "fixed"
  @unknown default: return "?(\(algorithm.rawValue))"
  }
}

func name(of textAlignment: NSTextAlignment) -> String {
  switch textAlignment {
  case .left: return "left"
  case .right: return "right"
  case .center: return "center"
  case .justified: return "justified"
  case .natural: return "natural"
  @unknown default: return "?(\(textAlignment.rawValue))"
  }
}

let allDimensions: [(NSTextBlock.Dimension, String)] = [
  (.width, "width"),
  (.minimumWidth, "minWidth"),
  (.maximumWidth, "maxWidth"),
  (.height, "height"),
  (.minimumHeight, "minHeight"),
  (.maximumHeight, "maxHeight"),
]

let allLayers: [(NSTextBlock.Layer, String)] = [
  (.padding, "padding"),
  (.border, "border"),
  (.margin, "margin"),
]

let allEdges: [(NSRectEdge, String)] = [
  (.minX, "minX"),
  (.minY, "minY"),
  (.maxX, "maxX"),
  (.maxY, "maxY"),
]

/// Dumps all NSTextBlock-level properties (dimensions, layer widths, colors,
/// vertical alignment). When `includingDefaults` is false only values that
/// differ from 0/nil are printed.
func describeBlockProperties(_ block: NSTextBlock, indent: String, includingDefaults: Bool = false)
{
  var dimensionParts: [String] = []
  for (dimension, dimensionName) in allDimensions {
    let value = block.value(for: dimension)
    let type = block.valueType(for: dimension)
    if includingDefaults || value != 0 {
      dimensionParts.append("\(dimensionName)=\(fmt(value))(\(name(of: type)))")
    }
  }
  if !dimensionParts.isEmpty {
    print("\(indent)dimensions: \(dimensionParts.joined(separator: " "))")
  }

  for (layer, layerName) in allLayers {
    var parts: [String] = []
    var allZero = true
    for (edge, edgeName) in allEdges {
      let width = block.width(for: layer, edge: edge)
      let type = block.widthValueType(for: layer, edge: edge)
      if width != 0 { allZero = false }
      parts.append("\(edgeName)=\(fmt(width))(\(name(of: type)))")
    }
    if includingDefaults || !allZero {
      print("\(indent)\(layerName): \(parts.joined(separator: " "))")
    }
  }

  var borderColorParts: [String] = []
  var anyBorderColor = false
  for (edge, edgeName) in allEdges {
    let color = block.borderColor(for: edge)
    if color != nil { anyBorderColor = true }
    borderColorParts.append("\(edgeName)=\(describe(color))")
  }
  if includingDefaults || anyBorderColor {
    print("\(indent)borderColor: \(borderColorParts.joined(separator: " "))")
  }

  if includingDefaults || block.backgroundColor != nil {
    print("\(indent)backgroundColor: \(describe(block.backgroundColor))")
  }

  if includingDefaults || block.verticalAlignment != .topAlignment {
    print("\(indent)verticalAlignment: \(name(of: block.verticalAlignment))")
  }
}

// MARK: - HTML conversion

func attributedString(fromHTML html: String) -> NSAttributedString? {
  let data = Data(html.utf8)
  let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
    .documentType: NSAttributedString.DocumentType.html,
    .characterEncoding: String.Encoding.utf8.rawValue,
  ]
  return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
}

// MARK: - Dumping

func shortLabel(for block: NSTextBlock) -> String {
  if let tableBlock = block as? NSTextTableBlock {
    let blockName = register(tableBlock)
    let tableName = register(tableBlock.table)
    var label = "\(blockName)→\(tableName) r\(tableBlock.startingRow)c\(tableBlock.startingColumn)"
    if tableBlock.rowSpan != 1 { label += " rowSpan=\(tableBlock.rowSpan)" }
    if tableBlock.columnSpan != 1 { label += " colSpan=\(tableBlock.columnSpan)" }
    return label
  }
  if block is NSTextTable {
    return register(block)
  }
  return "\(register(block)) (plain NSTextBlock)"
}

func dumpCase(name caseName: String, html: String) {
  resetRegistries()

  print("================================================================================")
  print("CASE \(caseName)")
  print("HTML: \(html)")
  print("--------------------------------------------------------------------------------")

  guard let attributedString = attributedString(fromHTML: html) else {
    print("!! conversion FAILED")
    return
  }

  print("STRING: \"\(escaped(attributedString.string))\"")
  print("")

  let nsString = attributedString.string as NSString
  var location = 0
  var paragraphIndex = 0

  while location < nsString.length {
    let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
    let paragraphText = nsString.substring(with: paragraphRange)
    let attributes = attributedString.attributes(at: paragraphRange.location, effectiveRange: nil)

    var infoParts: [String] = []

    if let font = attributes[.font] as? NSFont {
      infoParts.append("font=\(font.fontName)@\(fmt(font.pointSize))")
    }

    if let backgroundColor = attributes[.backgroundColor] as? NSColor {
      infoParts.append("runBG=\(describe(backgroundColor))")
    }

    var blocksLabel = "[]"
    if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
      let blocks = paragraphStyle.textBlocks
      if !blocks.isEmpty {
        blocksLabel = "[" + blocks.map { shortLabel(for: $0) }.joined(separator: " | ") + "]"
      }
      if paragraphStyle.alignment != .natural {
        infoParts.append("align=\(name(of: paragraphStyle.alignment))")
      }
      if paragraphStyle.headIndent != 0 {
        infoParts.append("headIndent=\(fmt(paragraphStyle.headIndent))")
      }
      if paragraphStyle.firstLineHeadIndent != 0 {
        infoParts.append("firstLineHeadIndent=\(fmt(paragraphStyle.firstLineHeadIndent))")
      }
      if paragraphStyle.tailIndent != 0 {
        infoParts.append("tailIndent=\(fmt(paragraphStyle.tailIndent))")
      }
      if paragraphStyle.paragraphSpacing != 0 {
        infoParts.append("paraSpacing=\(fmt(paragraphStyle.paragraphSpacing))")
      }
      if paragraphStyle.paragraphSpacingBefore != 0 {
        infoParts.append("paraSpacingBefore=\(fmt(paragraphStyle.paragraphSpacingBefore))")
      }
      if !paragraphStyle.textLists.isEmpty {
        infoParts.append("textLists=\(paragraphStyle.textLists.count)")
      }
      if paragraphStyle.baseWritingDirection != .natural {
        infoParts.append(
          "writingDirection=\(paragraphStyle.baseWritingDirection == .rightToLeft ? "RTL" : "LTR")")
      }
    }

    print("P\(paragraphIndex) \"\(escaped(paragraphText))\"")
    print("   blocks=\(blocksLabel)")
    if !infoParts.isEmpty {
      print("   \(infoParts.joined(separator: " "))")
    }

    location = NSMaxRange(paragraphRange)
    paragraphIndex += 1
  }

  if !orderedTables.isEmpty {
    print("")
    print("TABLES:")
    for table in orderedTables {
      let tableName = tableIDs[ObjectIdentifier(table)] ?? "?"
      print(
        "  \(tableName): numberOfColumns=\(table.numberOfColumns) "
          + "layoutAlgorithm=\(name(of: table.layoutAlgorithm)) "
          + "collapsesBorders=\(table.collapsesBorders) "
          + "hidesEmptyCells=\(table.hidesEmptyCells)")
      describeBlockProperties(table, indent: "     ")
    }
  }

  if !orderedBlocks.isEmpty {
    print("")
    print("BLOCKS:")
    for block in orderedBlocks {
      let blockName = blockIDs[ObjectIdentifier(block)] ?? "?"
      if let tableBlock = block as? NSTextTableBlock {
        let tableName = register(tableBlock.table)
        print(
          "  \(blockName): NSTextTableBlock table=\(tableName) "
            + "startingRow=\(tableBlock.startingRow) rowSpan=\(tableBlock.rowSpan) "
            + "startingColumn=\(tableBlock.startingColumn) columnSpan=\(tableBlock.columnSpan)")
      } else {
        print("  \(blockName): \(type(of: block))")
      }
      describeBlockProperties(block, indent: "     ")
    }
  }

  print("")
}

// MARK: - Constants dump

func dumpConstants() {
  print("================================================================================")
  print("CONSTANTS (raw values of the AppKit enums, for DT* compatibility)")
  print("--------------------------------------------------------------------------------")

  print("NSTextBlock.Dimension:")
  for (dimension, dimensionName) in allDimensions {
    print("   .\(dimensionName) = \(dimension.rawValue)")
  }

  print("NSTextBlock.ValueType:")
  print("   .absoluteValueType = \(NSTextBlock.ValueType.absoluteValueType.rawValue)")
  print("   .percentageValueType = \(NSTextBlock.ValueType.percentageValueType.rawValue)")

  print("NSTextBlock.Layer:")
  for (layer, layerName) in allLayers {
    print("   .\(layerName) = \(layer.rawValue)")
  }

  print("NSTextBlock.VerticalAlignment:")
  print("   .topAlignment = \(NSTextBlock.VerticalAlignment.topAlignment.rawValue)")
  print("   .middleAlignment = \(NSTextBlock.VerticalAlignment.middleAlignment.rawValue)")
  print("   .bottomAlignment = \(NSTextBlock.VerticalAlignment.bottomAlignment.rawValue)")
  print("   .baselineAlignment = \(NSTextBlock.VerticalAlignment.baselineAlignment.rawValue)")

  print("NSTextTable.LayoutAlgorithm:")
  print(
    "   .automaticLayoutAlgorithm = \(NSTextTable.LayoutAlgorithm.automaticLayoutAlgorithm.rawValue)"
  )
  print("   .fixedLayoutAlgorithm = \(NSTextTable.LayoutAlgorithm.fixedLayoutAlgorithm.rawValue)")

  print("NSRectEdge:")
  for (edge, edgeName) in allEdges {
    print("   .\(edgeName) = \(edge.rawValue)")
  }

  print("")
  print("Defaults of freshly created NSTextBlock():")
  let freshBlock = NSTextBlock()
  describeBlockProperties(freshBlock, indent: "   ", includingDefaults: true)

  print("")
  print("Defaults of freshly created NSTextTable():")
  let freshTable = NSTextTable()
  print(
    "   numberOfColumns=\(freshTable.numberOfColumns) "
      + "layoutAlgorithm=\(name(of: freshTable.layoutAlgorithm)) "
      + "collapsesBorders=\(freshTable.collapsesBorders) "
      + "hidesEmptyCells=\(freshTable.hidesEmptyCells)")

  print("")
}

// MARK: - Test cases

let testCases: [(String, String)] = [
  (
    "01-simple",
    "<p>Before</p><table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table><p>After</p>"
  ),
  (
    "02-th-thead",
    "<table><thead><tr><th>Name</th><th>Value</th></tr></thead><tbody><tr><td>Pi</td><td>3.14</td></tr></tbody></table>"
  ),
  (
    "03-colspan",
    "<table><tr><td colspan=\"2\">Wide</td><td>C1</td></tr><tr><td>A2</td><td>B2</td><td>C2</td></tr></table>"
  ),
  (
    "04-rowspan",
    "<table><tr><td rowspan=\"2\">Tall</td><td>B1</td></tr><tr><td>B2</td></tr></table>"
  ),
  (
    "05-widths",
    "<table width=\"80%\"><tr><td width=\"100\">fixed 100</td><td width=\"50%\">half</td></tr></table>"
  ),
  (
    "06-legacy-attrs",
    "<table border=\"2\" cellpadding=\"5\" cellspacing=\"3\" bgcolor=\"#FFEEDD\"><tr bgcolor=\"#DDEEFF\"><td bgcolor=\"#EEFFDD\">X</td><td>Y</td></tr></table>"
  ),
  (
    "07-css-box",
    "<table style=\"border-collapse: collapse;\"><tr>"
      + "<td style=\"padding: 1px 2px 3px 4px; border-top: 1px solid #FF0000; border-right: 2px solid #00FF00; border-bottom: 3px solid #0000FF; border-left: 4px solid #FF00FF; background-color: #ABCDEF; width: 120px;\">styled</td>"
      + "<td>plain</td></tr></table>"
  ),
  (
    "08-align-valign",
    "<table><tr style=\"height: 50px\"><td valign=\"top\">top</td><td valign=\"bottom\">bottom</td>"
      + "<td style=\"vertical-align: middle; text-align: right;\">mid right</td></tr></table>"
  ),
  (
    "09-nested",
    "<table><tr><td>Outer A<table><tr><td>Inner 1</td><td>Inner 2</td></tr></table>after inner</td><td>Outer B</td></tr></table>"
  ),
  (
    "10-empty-caption",
    "<table><caption>The Caption</caption><tr><td></td><td>B</td></tr></table>"
  ),
  (
    "11-multiparagraph",
    "<table><tr><td><p>One</p><p>Two</p></td><td>B</td></tr></table>"
  ),
  (
    "12-div-blockquote",
    "<div style=\"background-color: #FFFF00; padding: 10px; border: 1px solid #000000;\">styled div</div><blockquote>quoted text</blockquote>"
  ),
  (
    "13-fixed-layout",
    "<table style=\"table-layout: fixed; width: 300px;\"><tr><td>A</td><td>B</td></tr></table>"
  ),
  (
    "14-heights",
    "<table><tr><td height=\"50\">legacy 50</td><td style=\"height: 40px\">css 40</td></tr></table>"
  ),
  (
    "15-colgroup",
    "<table><colgroup><col width=\"120\"><col width=\"60\"></colgroup><tr><td>A</td><td>B</td></tr></table>"
  ),
  (
    "16-empty-cells-hide",
    "<table style=\"empty-cells: hide\"><tr><td>A</td><td></td></tr></table>"
  ),
  (
    "17-rtl",
    "<table dir=\"rtl\"><tr><td>one</td><td>two</td></tr></table>"
  ),
  (
    "18-table-margin",
    "<table style=\"margin-left: 20px; width: 200px\"><tr><td>A</td></tr></table>"
  ),
  (
    "19-min-max-width",
    "<table><tr><td style=\"min-width: 100px\">min</td><td style=\"max-width: 30px\">maxed</td></tr></table>"
  ),
  (
    "20-valign-baseline",
    "<table><tr><td style=\"vertical-align: baseline\">css bl</td><td valign=\"baseline\">legacy bl</td></tr></table>"
  ),
]

// MARK: - Main

dumpConstants()

for (caseName, html) in testCases {
  dumpCase(name: caseName, html: html)
}

print("DONE")
