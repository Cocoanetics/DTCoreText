# How macOS Represents HTML Tables

Empirical documentation of how AppKit's HTML importer expresses tables in attributed strings, as the basis for table support in DTCoreText.

## Overview

On macOS, `NSAttributedString(data:options:documentAttributes:)` with `NSHTMLTextDocumentType` represents HTML tables with three AppKit classes that have existed since macOS 10.4 but were missing from iOS until iOS 27:

- `NSTextBlock` — the base class. Carries six dimensions (width, minimum/maximum width, height, minimum/maximum height, each with an absolute-or-percentage value type), per-edge widths for three box layers (padding, border, margin), per-edge border colors, a background color, and a vertical alignment.
- `NSTextTable` (subclass of `NSTextBlock`) — one instance per table. Adds `numberOfColumns`, `layoutAlgorithm` (automatic/fixed), `collapsesBorders`, and `hidesEmptyCells`.
- `NSTextTableBlock` (subclass of `NSTextBlock`) — one instance per cell. Adds a reference to its `table` plus the grid position: `startingRow`, `rowSpan`, `startingColumn`, `columnSpan`.

These objects live in `NSParagraphStyle.textBlocks`, an array on the paragraph style of every paragraph that is inside a table cell. DTCoreText mirrors this with ``CoreTextParagraphStyle/textBlocks`` holding ``TextBlock`` objects; table support requires extending that model to match the full `NSTextBlock` API (tracked in [issue #1317](https://github.com/Cocoanetics/DTCoreText/issues/1317)).

Everything below was determined by running representative HTML snippets through the system importer and dumping the result. The tool lives at `Tools/TableInvestigation/main.swift` (run with `swift Tools/TableInvestigation/main.swift`); a captured dump is checked in next to it as `sample-output.txt`. Findings were captured on macOS 26.6 (25G5028f).

## Characters and Paragraphs

A table contributes **no characters of its own** to the string — no tabs, no delimiters, no attachment characters. Each cell becomes one or more ordinary paragraphs terminated by `\n`:

```
<table><tr><td>A1</td><td>B1</td></tr>
       <tr><td>A2</td><td>B2</td></tr></table>
```

produces exactly `"A1\nB1\nA2\nB2\n"`. The table structure exists *only* in the `textBlocks` of the paragraph styles.

- An **empty cell** is a bare `"\n"` paragraph (still carrying its `NSTextTableBlock`).
- A **cell with multiple paragraphs** (e.g. two `<p>` elements) produces multiple paragraphs that all reference the *same* `NSTextTableBlock` instance.
- A `<caption>` is emitted as a plain, center-aligned paragraph *before* the cell paragraphs, with **no text block at all** — it is not structurally part of the table.

## The textBlocks Array

- The array contains only `NSTextTableBlock` instances. The `NSTextTable` itself never appears in the array; it is reachable through each cell block's `table` property.
- For **nested tables**, the order is outermost first, innermost last. With a table inside a cell of an outer table, the inner cell's paragraphs carry `[outerCellBlock, innerCellBlock]`, while outer-cell text before/after the inner table carries just `[outerCellBlock]`.
- **Object identity is the grouping mechanism.** All paragraphs of one cell share one `NSTextTableBlock` instance; all cells of one table point at one shared `NSTextTable` instance. Two cells with identical properties are still distinct instances. Any consumer (layout, HTML writer) must group by identity, not equality.

## Grid Geometry

- `startingRow` / `startingColumn` are 0-based grid coordinates; `numberOfColumns` on the table counts grid columns including spans.
- `colspan="2"` → `columnSpan = 2`; the next cell in the row starts at the skipped index (e.g. `startingColumn = 2`).
- `rowspan="2"` → `rowSpan = 2`; the covered grid positions in following rows simply have **no block** — there is no placeholder. Grid occupancy must be reconstructed from the spans.
- There is no object representing a row (`<tr>`); rows exist only through the `startingRow` indices. Row-level HTML attributes are pushed down onto the row's cells (see colors below).

## Dimensions

The importer **resolves every width to an absolute point value** — percentage value types never occur in imported strings, even when the HTML uses percentages:

- `<table width="80%">` resolved to `width = 627.19 pt` *absolute* — 80% of WebKit's default layout width of ~784 pt (800 pt minus 2 × 8 pt body margin).
- Cells always get a `width` dimension with the resolved content width, even when the HTML specifies no width at all (the importer measures the laid-out content, e.g. `width = 14.67 pt` for "A1").
- The stored width is the resolved **content width**: `<td style="width: 120px">` → `width = 120`; a `<col width="120">` constraint → cell `width = 118` (120 minus 2 × 1 pt default padding). Pixel values import 1:1 as points.
- `min-width` / `max-width` → `minimumWidth` / `maximumWidth` dimensions, set *in addition to* the resolved `width`.
- **Heights are never imported.** Legacy `height` attributes and CSS `height` on rows or cells are dropped; all height dimensions stay 0 and row heights come purely from content at layout time.
- Quirk: only the legacy `width` *attribute* on `<table>` produces a width dimension on the `NSTextTable` block. CSS `width` on the table influences the resolved cell widths but is not stored on the table block itself.
- `<col>`/`<colgroup>` have no dedicated representation; their widths only influence the resolved cell widths.

The percentage value type (`NSTextBlockPercentageValueType`) is therefore only relevant for programmatically built tables — a DT implementation may choose to *keep* percentages from HTML (richer, resizable layout) or resolve them like the system importer does.

## Box Layers and Edges

Each block has three layers — padding, border, margin — with a width per `NSRectEdge`. In the flipped text coordinate system the edges mean:

| NSRectEdge | Side   |
|------------|--------|
| `minX` (0) | left   |
| `minY` (1) | top    |
| `maxX` (2) | right  |
| `maxY` (3) | bottom |

(Verified with distinct per-edge CSS border widths and colors: `border-left: 4px #FF00FF` showed up as `border minX=4`, `borderColor minX=#FF00FF`, etc.)

Observed mappings:

- Default plain `<td>`: padding 1 pt on all edges, margin 0.5 pt on all edges, border 0.
- `cellpadding="5"` → padding 5 pt on every cell edge.
- `cellspacing="3"` → margin 1.5 pt on every cell edge — the spacing is split in half between adjacent cells.
- `border="2"` on the table → border 2 pt on all edges of the `NSTextTable` block itself, plus a 1 pt border on every cell (the HTML separated-borders look).
- CSS `padding`/`border-*` per edge on a cell → the corresponding layer/edge values; `border-*-color` → `borderColor(for:)` per edge.
- CSS `margin` on the table → margin layer on the `NSTextTable` block (e.g. `margin-left: 20px` → `margin minX=20`).
- `border-collapse: collapse` → `collapsesBorders = true` on the table, and the cells lose their default margins (no spacing).
- Border colors default to opaque black on **all four edges of every block** (table and cells), even when the border width is 0.

## Colors

- `bgcolor`/`background-color` on `<table>` → `backgroundColor` of the `NSTextTable` block.
- On `<td>`/`<th>` → `backgroundColor` of that cell's block.
- On `<tr>` → copied to each cell block of that row that has no own background (there is no row object to carry it).
- Cell and table backgrounds are **not** run-level `NSBackgroundColorAttributeName` attributes — they live exclusively on the blocks. (Contrast: a `<div>` background *does* become a run attribute, see below.)

## Vertical Alignment

- The importer's default for table cells is `.middleAlignment` — note that a freshly initialized `NSTextBlock` defaults to `.topAlignment` instead.
- `valign` attribute and CSS `vertical-align` map directly: `top` → `.topAlignment`, `middle` → `.middleAlignment`, `bottom` → `.bottomAlignment`, `baseline` → `.baselineAlignment`.

## Paragraph-Level Effects

Some table styling lands on the paragraph style or font rather than the blocks:

- `<th>` → bold font (Times-Bold with default settings) and paragraph alignment `.center`. No block-level difference to `<td>`.
- `align`/`text-align` on cells → paragraph `alignment`.
- `dir="rtl"` on the table → `baseWritingDirection = .rightToLeft` on the cell paragraphs. The grid indices remain in source order; visual mirroring is the layout engine's job.
- The importer always sets an explicit `baseWritingDirection` (`.leftToRight` by default) — never `.natural`.
- `<p>` inside a cell keeps its usual `paragraphSpacing` (12 pt); bare cell text has none.

## Layout Algorithm and Empty Cells

- `table-layout: fixed` → `layoutAlgorithm = .fixedLayoutAlgorithm`; everything else is `.automaticLayoutAlgorithm`. Since the importer bakes resolved absolute widths anyway, the distinction matters mainly for relayout after edits.
- `empty-cells: hide` → `hidesEmptyCells = true` on the table.

## What the System Importer Does *Not* Use Blocks For

Only table cells produce text blocks. A `<div>` with padding, border, and background gets **no** `NSTextBlock`: the background color becomes a run-level background attribute and the padding/border are dropped entirely. A `<blockquote>` becomes head/tail indents (±40 pt). DTCoreText's existing use of ``TextBlock`` for padded/background block elements is *richer* than what the system importer does — that behavior must be preserved when extending the class.

## Enum Raw Values and Defaults

For a binary/archival-compatible DT layer the raw values must match exactly. Verified on macOS 26.6:

| Enum | Values |
|------|--------|
| `NSTextBlock.Dimension` | width = 0, minimumWidth = 1, maximumWidth = 2, height = 4, minimumHeight = 5, maximumHeight = 6 — **note the gap at 3** |
| `NSTextBlock.ValueType` | absoluteValueType = 0, percentageValueType = 1 |
| `NSTextBlock.Layer` | **padding = −1**, border = 0, margin = 1 |
| `NSTextBlock.VerticalAlignment` | top = 0, middle = 1, bottom = 2, baseline = 3 |
| `NSTextTable.LayoutAlgorithm` | automatic = 0, fixed = 1 |
| `NSRectEdge` | minX = 0, minY = 1, maxX = 2, maxY = 3 |

Defaults of freshly initialized instances:

- `NSTextBlock()` — all six dimensions 0 (absolute), all layer widths 0 (absolute), no border colors, no background color, `verticalAlignment = .topAlignment`.
- `NSTextTable()` — `numberOfColumns = 0`, `layoutAlgorithm = .automaticLayoutAlgorithm`, `collapsesBorders = false`, `hidesEmptyCells = false`.

## The DT Compatibility Layer

The full stack — model, parsing, layout and writing — is implemented:

1. ``TextBlock`` (`DTTextBlock`) carries the full `NSTextBlock` API: dimensions with value types, per-layer/per-edge widths with value types, per-edge border colors, and vertical alignment. The pre-existing `padding`/`backgroundColor` convenience API remains intact — `padding` maps onto the `.padding` layer. Edges are identified by `CGRectEdge`, whose raw values match `NSRectEdge` (which does not exist on iOS).
2. ``TextTable`` (`DTTextTable`) and ``TextTableBlock`` (`DTTextTableBlock`) mirror their NS counterparts with identical enum raw values. ``TextBlockConverter`` converts in both directions on macOS, preserving instance identity through per-converter caches; it is the swap point for the native classes on iOS 27.
3. ``TextTable`` and ``TextTableBlock`` compare **by identity**, exactly like their NS counterparts — and this turned out to be load-bearing, not stylistic: Foundation uniques value-equal attribute dictionaries *globally*, across attributed strings. With value-based equality, two equal-styled tables — even from two different documents parsed concurrently — get their runs mapped onto one canonical attribute dictionary, bleeding block instances between documents and destroying the identity grouping. (Plain ``TextBlock`` keeps its historical value-based equality.)
4. ``HTMLAttributedStringBuilder`` parses `table`/`tr`/`td`/`th`/`thead`/`tbody`/`tfoot`/`caption`/`col` into this model, matching the documented importer behavior: defaults of padding 1 pt / margin 0.5 pt / middle alignment, `cellspacing` split onto cell margins, `border` attribute giving cells 1 pt borders, `tr` colors pushed down to cells, bold+centered `th`, caption as a centered paragraph outside the table, no placeholder blocks for `rowspan`-covered positions. One deliberate difference: percentage widths are **kept** as percentage value types instead of being resolved to absolute points, so layout can resolve them against the actual frame width.
5. `CoreTextLayoutFrame` lays tables out as grids: a simplified automatic algorithm (explicit widths win and make content wrap, otherwise single-line content measurement with natural widths propagating recursively out of nested tables; leftover width from an explicit table width goes to the flexible columns), the fixed algorithm from the first row, row heights grown by `rowspan` cells, vertical alignment within row slots — including true first-baseline alignment across a row, per the `NSTextBlock.VerticalAlignment.baselineAlignment` documentation — plus justified cell text and recursive layout of nested tables. Cell and table border-box frames feed background and per-edge border drawing. With `collapsesBorders`, each boundary draws only the winning (wider) border — interior boundaries between cells and, per perimeter side, the wider of the table border and the outer cell borders — producing a single-line grid like CSS `border-collapse: collapse`. Current limitations: no full min/max-content width negotiation, no RTL column mirroring, and table content bypasses `numberOfLines` truncation.
6. ``TextBlock`` additionally models a per-edge **border style** (solid, dashed, dotted, double) — a DTCoreText extension, since `NSTextBlock` only stores width and color per edge (the system importer drops `border-style` entirely). The parser understands the full CSS border grammar: `border`/`border-{edge}` shorthands in any component order, `border-width`/`border-style`/`border-color` with 1–4 value lists in top/right/bottom/left order, per-edge longhands, the `thin`/`medium`/`thick` width keywords, the CSS rule that a style without a width implies a medium (3 px) border, and `none`/`hidden` removing an edge. The 3D styles (groove/ridge/inset/outset) render as solid. Converting to the NS classes drops the style information.
7. `HTMLWriter` writes the model back out as `<table>`/`<tr>`/`<td>` markup with `colspan`/`rowspan` attributes and inline CSS for widths, backgrounds, borders, padding and vertical alignment — round-tripping structure and styling through the parser.

The demo app contains three table snippets (`Tables.html`, `TableAlignment.html`, `TableWidths.html`) exercising these scenarios, and `TableRenderPreviewTests` renders them (plus eleven focused samples) to PNGs on macOS and iOS for visual inspection.

The parity test suite (`TextBlockAppKitParityTests`) pins the model against AppKit: enum raw values, freshly-initialized defaults, identity-equality semantics, lossless round-trip conversion, and live system-importer fixtures for the structural findings above. `TableParsingTests` additionally compares DTCoreText's parser output structurally against the system importer for identical HTML.
