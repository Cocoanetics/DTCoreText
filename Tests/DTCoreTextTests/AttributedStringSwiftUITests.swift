import Foundation
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Tests that DTCoreText custom attributes survive the NSAttributedString → AttributedString bridge.
@Suite("AttributedString DTCoreText Scope")
struct AttributedStringSwiftUITests {

  @Test("Header level attribute round-trips through AttributedString")
  func headerLevelRoundTrip() throws {
    let html = "<h3>Hello</h3>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    let run = attrStr.runs.first
    let level = run?[DTHeaderLevelKey.self]
    #expect(level == 3)
  }

  @Test("Anchor attribute round-trips through AttributedString")
  func anchorRoundTrip() throws {
    let html = "<a name=\"top\">Anchor</a>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    var foundAnchor: String?
    for run in attrStr.runs {
      if let anchor = run[DTAnchorKey.self] {
        foundAnchor = anchor
        break
      }
    }
    #expect(foundAnchor == "top")
  }

  @Test("Link highlight color round-trips through AttributedString")
  func linkHighlightColorRoundTrip() throws {
    let html = "<a href=\"https://example.com\">Link</a>"
    let options: [String: Any] = [
      DTDefaultLinkHighlightColor: "red"
    ]
    let attrStr = try AttributedString(htmlData: Data(html.utf8), options: options)

    var foundColor: DTColor?
    for run in attrStr.runs {
      if let color = run[DTLinkHighlightColorKey.self] {
        foundColor = color
        break
      }
    }
    #expect(foundColor != nil)
  }

  @Test("Text block attributes round-trip through AttributedString")
  func textBlockRoundTrip() throws {
    let html = "<div style=\"padding: 10px; background-color: red;\">Block text</div>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    var foundBlocks: [TextBlock]?
    for run in attrStr.runs {
      if let blocks = run[DTTextBlocksKey.self] {
        foundBlocks = blocks
        break
      }
    }
    #expect(foundBlocks != nil)
    #expect((foundBlocks?.count ?? 0) > 0)
  }

  @Test("Tables survive conversion to AttributedString with identity intact")
  func tableToAttributedString() throws {
    let html =
      "<table><tr><td><p>One</p><p>Two</p></td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    // collect distinct cells in run order via the typed key
    var cells = [TextTableBlock]()
    for run in attrStr.runs {
      guard let blocks = run[DTTextBlocksKey.self] else { continue }
      for case let cell as TextTableBlock in blocks
      where !cells.contains(where: { $0 === cell }) {
        cells.append(cell)
      }
    }

    try #require(cells.count == 4)

    // the shared table instance survives the conversion — this is what groups
    // the cells into one grid
    let table = cells[0].table
    #expect(cells.allSatisfy { $0.table === table })
    #expect(table.numberOfColumns == 2)
    #expect(cells.map { $0.startingRow } == [0, 0, 1, 1])
    #expect(cells.map { $0.startingColumn } == [0, 1, 0, 1])

    // the multi-paragraph cell appears as one instance across its runs
    let firstCellRuns = attrStr.runs.filter { run in
      run[DTTextBlocksKey.self]?.contains(where: { $0 === cells[0] }) ?? false
    }
    #expect(firstCellRuns.count >= 1)
  }

  @Test("Tables survive the round trip back to NSAttributedString and lay out")
  func tableRoundTripBackAndLayout() throws {
    let html = "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))
    let roundTripped = try NSAttributedString(attrStr, including: \.dtCoreText)

    #expect(roundTripped.string == "A1\nB1\nA2\nB2\n")

    // structure and identity intact after the round trip
    var cells = [TextTableBlock]()
    roundTripped.enumerateAttribute(
      NSAttributedString.Key(rawValue: DTTextBlocksAttribute),
      in: NSRange(location: 0, length: roundTripped.length)
    ) { value, _, _ in
      guard let blocks = value as? [TextBlock] else { return }
      for case let cell as TextTableBlock in blocks
      where !cells.contains(where: { $0 === cell }) {
        cells.append(cell)
      }
    }

    try #require(cells.count == 4)
    #expect(cells.allSatisfy { $0.table === cells[0].table })

    // the round-tripped string still lays out as a grid
    let layouter = try #require(CoreTextLayouter(attributedString: roundTripped))
    let maxRect = CGRect(x: 0, y: 0, width: 400, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
    let frame = try #require(
      layouter.layoutFrame(
        with: maxRect, range: NSRange(location: 0, length: roundTripped.length)))

    let nsString = roundTripped.string as NSString
    let lineA1 = try #require(
      frame.lineContaining(index: UInt(nsString.range(of: "A1").location)))
    let lineB1 = try #require(
      frame.lineContaining(index: UInt(nsString.range(of: "B1").location)))

    #expect(abs(lineA1.baselineOrigin.y - lineB1.baselineOrigin.y) < 1)
    #expect(lineB1.frame.minX > lineA1.frame.maxX - 1)
  }

  @Test("Field attribute round-trips through AttributedString")
  func fieldRoundTrip() throws {
    let html = "<ul><li>Item</li></ul>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    var foundField: String?
    for run in attrStr.runs {
      if let field = run[DTFieldKey.self] {
        foundField = field
        break
      }
    }
    #expect(foundField == DTListPrefixField)
  }

  @Test("Multiple DTCoreText attributes coexist on a single run")
  func multipleAttributesOnRun() throws {
    let html = "<h2><a name=\"section\">Section</a></h2>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    let run = attrStr.runs.first
    #expect(run?[DTHeaderLevelKey.self] == 2)
    #expect(run?[DTAnchorKey.self] == "section")
  }

  @Test("Async initializer produces same result")
  func asyncInitializer() async throws {
    let html = "<h1>Async</h1>"
    let attrStr = try await AttributedString(htmlData: Data(html.utf8))

    let run = attrStr.runs.first
    #expect(run?[DTHeaderLevelKey.self] == 1)
  }

  @Test("Standard UIKit attributes are preserved alongside custom ones")
  func uiKitAttributesPreserved() throws {
    let html = "<h3 style=\"color: red;\">Colored Header</h3>"
    let attrStr = try AttributedString(htmlData: Data(html.utf8))

    let run = attrStr.runs.first
    #expect(run?[DTHeaderLevelKey.self] == 3)
    // the font survives via the platform scope; checked through the NS conversion
    // because the typed font subscript trips the unavailable Sendable conformance
    // of UIFont/NSFont
    let nsAttributedString = try NSAttributedString(attrStr, including: \.dtCoreText)
    #expect(nsAttributedString.attribute(.font, at: 0, effectiveRange: nil) != nil)
  }
}
