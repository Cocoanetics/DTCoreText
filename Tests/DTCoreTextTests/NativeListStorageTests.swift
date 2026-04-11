import Foundation
import Testing

@testable import DTCoreTextSwift

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Tests that list metadata lives on `NSParagraphStyle.textLists` (the canonical storage)
/// and that the legacy `DTTextListsAttribute` is only honored as a read-only migration input.
@Suite("Native list storage", .serialized)
struct NativeListStorageTests {

  // MARK: - textLists on paragraph style is populated

  @Test("<ul> parses with textLists on NSParagraphStyle")
  func simpleUnorderedListOnParagraphStyle() throws {
    let attr = try #require(
      TestHelpers.attributedString(fromHTML: "<ul><li>a</li><li>b</li><li>c</li></ul>"))

    let ps0 = attr.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
    let lists = ps0?.textLists as? [DTTextList]
    #expect(lists?.count == 1)
    #expect(lists?.first?.markerFormat == .disc)
    // Apple's convention for unordered lists: startingItemNumber = 0
    #expect(lists?.first?.startingItemNumber == 0)
    #expect(lists?.first?.isOrdered == false)
  }

  @Test("<ol> parses with decimal markerFormat and startingItemNumber = 1")
  func simpleOrderedListOnParagraphStyle() throws {
    let attr = try #require(
      TestHelpers.attributedString(fromHTML: "<ol><li>one</li><li>two</li></ol>"))

    let ps = attr.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
    let list = (ps?.textLists as? [DTTextList])?.first
    #expect(list?.markerFormat == .decimal)
    #expect(list?.startingItemNumber == 1)
    #expect(list?.isOrdered == true)
  }

  @Test("<ol start=\"5\"> records startingItemNumber = 5")
  func orderedListWithStart() throws {
    let attr = try #require(
      TestHelpers.attributedString(fromHTML: "<ol start=\"5\"><li>five</li><li>six</li></ol>"))

    let ps = attr.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
    let list = (ps?.textLists as? [DTTextList])?.first
    #expect(list?.startingItemNumber == 5)
  }

  // MARK: - List metadata is shared across a list's items (by value)

  @Test("Items of the same <ol> carry value-equal lists on every paragraph")
  func listSharedAcrossItems() throws {
    let attr = try #require(
      TestHelpers.attributedString(
        fromHTML: "<ol><li>alpha</li><li>beta</li><li>gamma</li></ol>"))

    var collected: [NSTextList] = []
    let fullRange = NSRange(location: 0, length: attr.length)
    (attr.string as NSString).enumerateSubstrings(in: fullRange, options: .byParagraphs) {
      _, substringRange, _, _ in
      guard substringRange.length > 0 else { return }
      let ps = attr.attribute(.paragraphStyle, at: substringRange.location, effectiveRange: nil)
        as? NSParagraphStyle
      if let first = ps?.textLists.first {
        collected.append(first)
      }
    }

    #expect(collected.count == 3, "Should see 3 list items")
    guard let first = collected.first else { return }
    for (i, list) in collected.enumerated() {
      // HTMLWriter's common-prefix algorithm and DTCoreText's range finders both use
      // value equality (not instance identity), because attribute coalescing may strip
      // instance identity when attributed strings are stored / re-serialized.
      let msg = "List on item \(i) should be value-equal to item 0"
      #expect(list.isEqual(first), Comment(rawValue: msg))
    }
  }

  // MARK: - Nesting

  @Test("3-level nested <ul><ol><ul> produces expected depths and value-distinct lists")
  func nestedListsProduceThreeValueDistinctLists() throws {
    let html =
      "<ul><li>L1<ol><li>L2<ul><li>L3a</li><li>L3b</li></ul></li></ol></li></ul>"
    let attr = try #require(TestHelpers.attributedString(fromHTML: html))

    var depths: [Int] = []
    var valueDistinct: [NSTextList] = []
    func addUnique(_ list: NSTextList) {
      if !valueDistinct.contains(where: { $0.isEqual(list) }) {
        valueDistinct.append(list)
      }
    }

    let fullRange = NSRange(location: 0, length: attr.length)
    (attr.string as NSString).enumerateSubstrings(in: fullRange, options: .byParagraphs) {
      _, substringRange, _, _ in
      guard substringRange.length > 0 else { return }
      let ps = attr.attribute(.paragraphStyle, at: substringRange.location, effectiveRange: nil)
        as? NSParagraphStyle
      let lists = ps?.textLists ?? []
      depths.append(lists.count)
      for list in lists {
        addUnique(list)
      }
    }

    // Expected depth progression: 1 (L1) → 2 (L2) → 3 (L3a) → 3 (L3b)
    #expect(depths == [1, 2, 3, 3], Comment(rawValue: "Got depths=\(depths)"))
    #expect(valueDistinct.count == 3)
    let formats: Set<String> = Set(valueDistinct.map { $0.markerFormat.rawValue })
    let expected: Set<String> = [
      NSTextList.MarkerFormat.disc.rawValue,
      NSTextList.MarkerFormat.decimal.rawValue,
      NSTextList.MarkerFormat.square.rawValue,
    ]
    #expect(formats == expected)
  }

  // MARK: - Legacy attribute migration

  @Test("dtct_migrateLegacyListAttribute copies legacy key onto NSParagraphStyle.textLists")
  func migrateLegacyAttribute() {
    // Hand-build an attributed string that looks like the pre-migration scheme:
    // list stored under DTTextListsAttribute, not on the paragraph style.
    let list = DTTextList(styles: ["list-style-type": "disc"])
    let mutable = NSMutableAttributedString(string: "item\n")
    let fullRange = NSRange(location: 0, length: mutable.length)

    let basePS = NSMutableParagraphStyle()
    basePS.headIndent = 36
    mutable.addAttribute(.paragraphStyle, value: basePS, range: fullRange)
    mutable.addAttribute(
      NSAttributedString.Key(rawValue: DTTextListsAttribute), value: [list], range: fullRange)

    // Pre-condition: paragraph style has no lists yet.
    let preLists =
      (mutable.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?
      .textLists
    #expect(preLists?.isEmpty ?? true)

    // Migrate.
    mutable.dtct_migrateLegacyListAttribute()

    // Post-condition: lists live on the paragraph style; old attribute is stripped.
    let postPS =
      mutable.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
    #expect(postPS?.textLists.count == 1)
    #expect((postPS?.textLists.first as? DTTextList)?.markerFormat == .disc)

    let oldAttr = mutable.attribute(
      NSAttributedString.Key(rawValue: DTTextListsAttribute), at: 0, effectiveRange: nil)
    #expect(oldAttr == nil, "Legacy attribute should be removed after migration")
  }

  @Test("HTMLWriter round-trips a legacy-encoded list via the migration path")
  func htmlWriterMigratesLegacyInput() {
    let list = DTTextList(styles: ["list-style-type": "disc"])
    let mutable = NSMutableAttributedString(string: "\t\u{2022}\titem\n")
    let fullRange = NSRange(location: 0, length: mutable.length)

    let ps = NSMutableParagraphStyle()
    ps.headIndent = 36
    ps.firstLineHeadIndent = 0
    mutable.addAttribute(.paragraphStyle, value: ps, range: fullRange)
    mutable.addAttribute(
      NSAttributedString.Key(rawValue: DTTextListsAttribute), value: [list], range: fullRange)

    let writer = HTMLWriter(attributedString: mutable)
    let html = writer.htmlFragment()

    // Should emit <ul>...</ul> wrapping the item — i.e., HTMLWriter read the list info
    // via the migration path.
    #expect(html.contains("<ul"))
    #expect(html.contains("</ul>"))
  }
}
