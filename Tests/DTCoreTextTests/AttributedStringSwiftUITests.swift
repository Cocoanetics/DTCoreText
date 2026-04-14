import Foundation
import Testing

@testable import DTCoreTextSwift

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

    var foundBlocks: NSArray?
    for run in attrStr.runs {
      if let blocks = run[DTTextBlocksKey.self] {
        foundBlocks = blocks
        break
      }
    }
    #expect(foundBlocks != nil)
    #expect((foundBlocks?.count ?? 0) > 0)
    #expect(foundBlocks?.firstObject is TextBlock)
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
    // Font should be present via UIKit scope
    #if canImport(UIKit)
      #expect(run?[AttributeScopes.UIKitAttributes.FontAttribute.self] != nil)
    #elseif canImport(AppKit)
      #expect(run?[AttributeScopes.AppKitAttributes.FontAttribute.self] != nil)
    #endif
  }
}
