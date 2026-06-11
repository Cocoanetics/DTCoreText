import CoreText
import Foundation
import ImageIO
import Testing

@testable import DTCoreText

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Renders representative tables into PNGs (under /tmp/table-renders on macOS, the
  /// process temporary directory elsewhere) for visual inspection. Also acts as a smoke
  /// test that none of the samples crash and all of them render.
  @Suite("Table Render Preview", .serialized)
  struct TableRenderPreviewTests {

    private static let samples: [(name: String, width: CGFloat, html: String)] = [
      (
        "01-simple", 420,
        "<table><tr><td>Alpha</td><td>Beta</td></tr><tr><td>Gamma</td><td>Delta</td></tr></table>"
      ),
      (
        "02-headers", 420,
        "<table border=\"1\" cellpadding=\"4\"><thead><tr><th>Name</th><th>Value</th></tr></thead>"
          + "<tbody><tr><td>Pi</td><td>3.14159</td></tr><tr><td>Euler</td><td>2.71828</td></tr></tbody></table>"
      ),
      (
        "03-spans", 420,
        "<table border=\"1\" cellpadding=\"4\"><tr><td colspan=\"2\" bgcolor=\"#FFD8A8\">Wide header</td><td bgcolor=\"#A8D8FF\" rowspan=\"2\">Tall<br>cell</td></tr>"
          + "<tr><td>A2</td><td>B2</td></tr><tr><td>A3</td><td>B3</td><td>C3</td></tr></table>"
      ),
      (
        "04-styled", 420,
        "<table bgcolor=\"#F4F4F4\" cellspacing=\"6\" cellpadding=\"6\"><tr>"
          + "<td style=\"border: 2px solid #CC0000; background-color: #FFEEEE\">red border</td>"
          + "<td style=\"border-left: 6px solid #0066CC; background-color: #EEF4FF\">left accent</td></tr>"
          + "<tr><td bgcolor=\"#EEFFEE\">plain</td><td>default</td></tr></table>"
      ),
      (
        "05-collapse", 420,
        "<table style=\"border-collapse: collapse\" border=\"1\"><tr><th>Q</th><th>Revenue</th></tr>"
          + "<tr><td>Q1</td><td>1.000</td></tr><tr><td>Q2</td><td>1.250</td></tr></table>"
      ),
      (
        "06-valign", 420,
        "<table border=\"1\" cellpadding=\"3\"><tr><td>first line<br>second line<br>third line</td>"
          + "<td valign=\"top\">top</td><td>middle</td><td valign=\"bottom\">bottom</td></tr></table>"
      ),
      (
        "07-nested", 420,
        "<table border=\"1\" cellpadding=\"4\" bgcolor=\"#F0F0F0\"><tr><td>Outer A"
          + "<table border=\"1\" bgcolor=\"#FFF4D8\"><tr><td>in 1</td><td>in 2</td></tr></table>"
          + "after inner</td><td bgcolor=\"#E8F8E8\">Outer B</td></tr></table>"
      ),
      (
        "08-widths", 420,
        "<table width=\"100%\" border=\"1\"><tr><td width=\"25%\" bgcolor=\"#FFE8E8\">25%</td>"
          + "<td width=\"50%\" bgcolor=\"#E8FFE8\">50%</td><td bgcolor=\"#E8E8FF\">rest</td></tr></table>"
      ),
      (
        "09-flow", 420,
        "<p>Text before the table flows normally and wraps when it gets long enough.</p>"
          + "<table border=\"1\" cellpadding=\"3\"><tr><td>A</td><td>B</td></tr></table>"
          + "<p>Text after the table continues below it.</p>"
      ),
      (
        "10-baseline", 420,
        "<table border=\"1\" cellpadding=\"3\"><tr>"
          + "<td style=\"vertical-align: baseline; font-size: 32px\">Large</td>"
          + "<td style=\"vertical-align: baseline\">baseline</td>"
          + "<td style=\"vertical-align: baseline; font-size: 9px\">tiny</td></tr></table>"
      ),
      (
        "12-border-styles", 420,
        "<table cellspacing=\"6\" cellpadding=\"6\"><tr>"
          + "<td style=\"border: 2px solid #333333\">solid</td>"
          + "<td style=\"border: 2px dashed #CC0000\">dashed</td>"
          + "<td style=\"border: 2px dotted #0066CC\">dotted</td>"
          + "<td style=\"border: 6px double #008800\">double</td></tr>"
          + "<tr><td colspan=\"4\" style=\"border-width: 1px 3px 5px 7px; border-style: solid dashed dotted double; border-color: #CC0000 #008800 #0066CC #CC8800\">mixed per edge: solid/dashed/dotted/double</td></tr></table>"
      ),
      (
        "11-alignment", 420,
        "<table border=\"1\" width=\"100%\" cellpadding=\"3\"><tr>"
          + "<td style=\"text-align: left\">left</td>"
          + "<td style=\"text-align: center\">center</td>"
          + "<td style=\"text-align: right\">right</td></tr>"
          + "<tr><td colspan=\"3\" style=\"text-align: justify\">Justified text in a table cell "
          + "stretches every full line to the cell width so both edges are flush with the padding box, "
          + "just like justified paragraphs outside of tables behave.</td></tr></table>"
      ),
    ]

    @Test("Render all samples to PNG", arguments: samples.map { $0.name })
    func renderSample(name: String) throws {
      let sample = try #require(Self.samples.first { $0.name == name })

      let attributedString = try #require(TestHelpers.attributedString(fromHTML: sample.html))
      let layouter = try #require(CoreTextLayouter(attributedString: attributedString))

      let maxRect = CGRect(
        x: 10, y: 10, width: sample.width - 20, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
      let entireString = NSRange(location: 0, length: attributedString.length)
      let layoutFrame = try #require(layouter.layoutFrame(with: maxRect, range: entireString))

      let contentHeight = ceil(layoutFrame.frame.maxY) + 10
      let scale: CGFloat = 2
      let pixelWidth = Int(sample.width * scale)
      let pixelHeight = Int(contentHeight * scale)

      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let context = try #require(
        CGContext(
          data: nil, width: pixelWidth, height: pixelHeight, bitsPerComponent: 8, bytesPerRow: 0,
          space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))

      // white background
      context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight)))

      // flip to the top-down coordinate system the layout frame draws in
      context.translateBy(x: 0, y: CGFloat(pixelHeight))
      context.scaleBy(x: scale, y: -scale)

      layoutFrame.draw(in: context, options: 0)

      // verify that something was painted
      let image = try #require(context.makeImage())

      // simulator test processes run on the host, so /tmp is the Mac's /tmp either way
      #if os(macOS)
        let outputDirectory = URL(fileURLWithPath: "/tmp/table-renders", isDirectory: true)
      #else
        let outputDirectory = URL(fileURLWithPath: "/tmp/table-renders-ios", isDirectory: true)
      #endif
      try FileManager.default.createDirectory(
        at: outputDirectory, withIntermediateDirectories: true)

      let outputURL = outputDirectory.appendingPathComponent("\(name).png")
      let destination = try #require(
        CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil))
      CGImageDestinationAddImage(destination, image, nil)
      #expect(CGImageDestinationFinalize(destination))
      print("RENDERED: \(outputURL.path)")
    }

    /// Renders the table demo files of the demo app at iPhone width, so the demo
    /// content is verified through the same pipeline the demo app uses.
    @Test(
      "Render demo app table files",
      arguments: ["Tables", "TableAlignment", "TableWidths", "TableBorders"])
    func renderDemoFile(name: String) throws {
      let demoResources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // DTCoreTextTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // package root
        .appendingPathComponent("Demo/Resources")

      let fileURL = demoResources.appendingPathComponent("\(name).html")
      let html = try String(contentsOf: fileURL, encoding: .utf8)

      let attributedString = try #require(TestHelpers.attributedString(fromHTML: html))
      let layouter = try #require(CoreTextLayouter(attributedString: attributedString))

      let width: CGFloat = 390  // iPhone point width, like the demo app
      let maxRect = CGRect(
        x: 10, y: 10, width: width - 20, height: CGFloat(CGFLOAT_HEIGHT_UNKNOWN))
      let entireString = NSRange(location: 0, length: attributedString.length)
      let layoutFrame = try #require(layouter.layoutFrame(with: maxRect, range: entireString))

      let contentHeight = ceil(layoutFrame.frame.maxY) + 10
      let scale: CGFloat = 2
      let pixelWidth = Int(width * scale)
      let pixelHeight = Int(contentHeight * scale)

      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let context = try #require(
        CGContext(
          data: nil, width: pixelWidth, height: pixelHeight, bitsPerComponent: 8, bytesPerRow: 0,
          space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))

      context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight)))
      context.translateBy(x: 0, y: CGFloat(pixelHeight))
      context.scaleBy(x: scale, y: -scale)

      layoutFrame.draw(in: context, options: 0)

      let image = try #require(context.makeImage())

      #if os(macOS)
        let outputDirectory = URL(fileURLWithPath: "/tmp/table-renders", isDirectory: true)
      #else
        let outputDirectory = URL(fileURLWithPath: "/tmp/table-renders-ios", isDirectory: true)
      #endif
      try FileManager.default.createDirectory(
        at: outputDirectory, withIntermediateDirectories: true)

      let outputURL = outputDirectory.appendingPathComponent("demo-\(name).png")
      let destination = try #require(
        CGImageDestinationCreateWithURL(outputURL as CFURL, "public.png" as CFString, 1, nil))
      CGImageDestinationAddImage(destination, image, nil)
      #expect(CGImageDestinationFinalize(destination))
    }
  }
