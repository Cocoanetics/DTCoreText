import Foundation
import Testing

@testable import DTCoreText

/// Foundation uniques value-equal attribute dictionaries globally, across attributed
/// strings. If table blocks compared by value, concurrent parses would bleed table
/// instances into each other's output (and equal-styled tables within one document
/// would merge). Identity-based equality on TextTable/TextTableBlock prevents this;
/// this test locks that behavior in.
@Suite("Table Identity Under Concurrency") struct TableIdentityStressTests {
  @Test("Concurrent parses keep distinct table identities")
  func stressParallelTableParsing() async throws {
    let html =
      "<table><tr><td>A1</td><td>B1</td></tr><tr><td>A2</td><td>B2</td></tr></table>"

    let failures = await withTaskGroup(of: String?.self, returning: [String].self) { group in
      for index in 0..<64 {
        group.addTask {
          guard let attributedString = TestHelpers.attributedString(fromHTML: html) else {
            return "run \(index): no result"
          }

          let nsString = attributedString.string as NSString
          var tables = [TextTable]()
          var cellCount = 0
          var location = 0

          while location < nsString.length {
            let paragraphRange = nsString.paragraphRange(
              for: NSRange(location: location, length: 0))
            if let blocks = attributedString.attribute(
              NSAttributedString.Key(rawValue: DTTextBlocksAttribute),
              at: paragraphRange.location, effectiveRange: nil) as? [TextBlock],
              let cell = blocks.first as? TextTableBlock
            {
              cellCount += 1
              if !tables.contains(where: { $0 === cell.table }) {
                tables.append(cell.table)
              }
            }
            location = NSMaxRange(paragraphRange)
          }

          if tables.count != 1 || cellCount != 4 {
            let coords = (0..<nsString.length).compactMap { _ in "" }
            _ = coords
            return
              "run \(index): string=\(attributedString.string.replacingOccurrences(of: "\n", with: "|")) tables=\(tables.count) cells=\(cellCount) columns=\(tables.map { $0.numberOfColumns })"
          }
          return nil
        }
      }

      var collected = [String]()
      for await failure in group {
        if let failure { collected.append(failure) }
      }
      return collected
    }

    for failure in failures {
      print("STRESS FAILURE: \(failure)")
    }
    #expect(failures.isEmpty, "\(failures.count) of 64 parses produced wrong structure")
  }
}
