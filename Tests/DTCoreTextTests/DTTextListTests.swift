import Foundation
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

@Suite("DTTextList", .serialized)
struct DTTextListTests {
  @Test("NSSecureCoding round-trip preserves equality")
  func secureCodingEqual() throws {
    let styles: [String: String] = ["list-style-type": "none", "list-style-position": "inherit"]
    let list = DTTextList(styles: styles)

    let data = try NSKeyedArchiver.archivedData(withRootObject: list, requiringSecureCoding: true)
    let unarchived = try #require(
      try NSKeyedUnarchiver.unarchivedObject(ofClass: DTTextList.self, from: data))

    #expect(list.isEqualTo(unarchived))
  }

  @Test("NSSecureCoding round-trip preserves inequality")
  func secureCodingNotEqual() throws {
    let styles1: [String: String] = ["list-style-type": "none", "list-style-position": "inherit"]
    let list1 = DTTextList(styles: styles1)

    let styles2: [String: String] = ["list-style-type": "circle", "list-style-position": "inherit"]
    let list2 = DTTextList(styles: styles2)

    #expect(!list1.isEqualTo(list2))

    let data = try NSKeyedArchiver.archivedData(withRootObject: list1, requiringSecureCoding: true)
    let unarchived = try #require(
      try NSKeyedUnarchiver.unarchivedObject(ofClass: DTTextList.self, from: data))

    #expect(!unarchived.isEqualTo(list2))
  }

  @Test("NSSecureCoding preserves all DTTextList-specific fields")
  func secureCodingPreservesFields() throws {
    let list = DTTextList(styles: ["list-style-image": "url('bullet.png')"])
    list.position = .inside
    list.startingItemNumber = 7

    let data = try NSKeyedArchiver.archivedData(withRootObject: list, requiringSecureCoding: true)
    let unarchived = try #require(
      try NSKeyedUnarchiver.unarchivedObject(ofClass: DTTextList.self, from: data))

    #expect(unarchived.imageName == "bullet.png")
    #expect(unarchived.position == .inside)
    #expect(unarchived.startingItemNumber == 7)
  }

  // MARK: - Marker formatting

  @Test("Decimal marker uses native format with period suffix")
  func decimalMarker() {
    let list = DTTextList(styles: ["list-style-type": "decimal"])
    #expect(list.formattedMarker(forItemNumber: 1) == "\t1.\t")
    #expect(list.formattedMarker(forItemNumber: 42) == "\t42.\t")
    #expect(list.isOrdered)
  }

  @Test("Decimal-leading-zero uses custom marker fallback")
  func decimalLeadingZero() {
    let list = DTTextList(styles: ["list-style-type": "decimal-leading-zero"])
    #expect(list.customMarker == .decimalLeadingZero)
    #expect(list.formattedMarker(forItemNumber: 1) == "\t01.\t")
    #expect(list.formattedMarker(forItemNumber: 12) == "\t12.\t")
    #expect(list.isOrdered)
  }

  @Test("Plus custom marker")
  func plusMarker() {
    let list = DTTextList(styles: ["list-style-type": "plus"])
    #expect(list.customMarker == .plus)
    #expect(list.formattedMarker(forItemNumber: 1) == "\t+\t")
    #expect(!list.isOrdered)
  }

  @Test("Underscore custom marker")
  func underscoreMarker() {
    let list = DTTextList(styles: ["list-style-type": "underscore"])
    #expect(list.customMarker == .underscore)
    #expect(list.formattedMarker(forItemNumber: 1) == "\t_\t")
  }

  @Test("Disc bullet")
  func disc() {
    let list = DTTextList(styles: ["list-style-type": "disc"])
    #expect(list.formattedMarker(forItemNumber: 1) == "\t\u{2022}\t")
  }

  @Test("None type emits no marker")
  func noneType() {
    let list = DTTextList(styles: ["list-style-type": "none"])
    #expect(list.customMarker == DTTextListCustomMarker.none)
    #expect(!list.hasMarker)
    #expect(list.formattedMarker(forItemNumber: 1) == nil)
  }

  @Test("Lowercase roman numerals")
  func lowercaseRoman() {
    let list = DTTextList(styles: ["list-style-type": "lower-roman"])
    #expect(list.formattedMarker(forItemNumber: 4) == "\tiv.\t")
    #expect(list.isOrdered)
  }

  // MARK: - CSS parsing

  @Test("Shorthand `list-style` parses type, position, and image")
  func shorthand() {
    let list = DTTextList(styles: ["list-style": "square inside url('b.png')"])
    #expect(list.cssListStyleTypeString == "square")
    #expect(list.position == .inside)
    #expect(list.imageName == "b.png")
  }

  @Test("`list-style: inherit` sets inheritStyle flag")
  func inheritShorthand() {
    let list = DTTextList(styles: ["list-style": "inherit"])
    #expect(list.inheritStyle)
  }

  // MARK: - applyingStyles overrides

  @Test("applyingStyles changes marker type")
  func applyingType() {
    let base = DTTextList(styles: ["list-style-type": "disc"])
    let overridden = base.applyingStyles(["list-style-type": "square"])
    #expect(overridden.cssListStyleTypeString == "square")
    // base unchanged
    #expect(base.cssListStyleTypeString == "disc")
  }

  @Test("applyingStyles without overlapping keys returns the receiver unchanged")
  func applyingNoOverlap() {
    let base = DTTextList(styles: ["list-style-type": "disc"])
    let result = base.applyingStyles(["color": "red"])
    #expect(result === base)
  }
}
