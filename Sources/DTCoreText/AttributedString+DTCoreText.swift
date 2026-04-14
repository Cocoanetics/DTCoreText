import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

#if canImport(SwiftUI)
  import SwiftUI
#endif

// MARK: - Attribute Keys

/// Attribute keys for DTCoreText custom attributes, bridging them into Swift's
/// `AttributedString` system so they survive an `NSAttributedString` → `AttributedString`
/// conversion.

public enum DTAttachmentParagraphSpacingKey: AttributedStringKey {
  public typealias Value = Double
  public static let name = DTAttachmentParagraphSpacingAttribute
}

public enum DTLinkHighlightColorKey: AttributedStringKey {
  public typealias Value = DTColor
  public static let name = DTLinkHighlightColorAttribute
}

public enum DTAnchorKey: AttributedStringKey {
  public typealias Value = String
  public static let name = DTAnchorAttribute
}

public enum DTGUIDKey: AttributedStringKey {
  public typealias Value = String
  public static let name = DTGUIDAttribute
}

public enum DTHeaderLevelKey: AttributedStringKey {
  public typealias Value = Int
  public static let name = DTHeaderLevelAttribute
}

public enum DTShadowsKey: AttributedStringKey {
  public typealias Value = NSArray
  public static let name = DTShadowsAttribute
}

public enum DTHorizontalRuleStyleKey: AttributedStringKey {
  public typealias Value = Bool
  public static let name = DTHorizontalRuleStyleAttribute
}

public enum DTTextBlocksKey: AttributedStringKey {
  public typealias Value = NSArray
  public static let name = DTTextBlocksAttribute
}

public enum DTFieldKey: AttributedStringKey {
  public typealias Value = String
  public static let name = DTFieldAttribute
}

public enum DTCustomAttributesKey: AttributedStringKey {
  public typealias Value = NSDictionary
  public static let name = DTCustomAttributesAttribute
}

public enum DTAscentMultiplierKey: AttributedStringKey {
  public typealias Value = Double
  public static let name = DTAscentMultiplierAttribute
}

public enum DTBackgroundStrokeColorKey: AttributedStringKey {
  public typealias Value = DTColor
  public static let name = DTBackgroundStrokeColorAttribute
}

public enum DTBackgroundStrokeWidthKey: AttributedStringKey {
  public typealias Value = Double
  public static let name = DTBackgroundStrokeWidthAttribute
}

public enum DTBackgroundCornerRadiusKey: AttributedStringKey {
  public typealias Value = Double
  public static let name = DTBackgroundCornerRadiusAttribute
}

// MARK: - Attribute Scope

/// The DTCoreText attribute scope, containing all custom attributes plus the
/// standard UIKit (or AppKit) and SwiftUI scopes.
public struct DTCoreTextAttributes: AttributeScope {
  public let attachmentParagraphSpacing: DTAttachmentParagraphSpacingKey
  public let linkHighlightColor: DTLinkHighlightColorKey
  public let anchor: DTAnchorKey
  public let guid: DTGUIDKey
  public let headerLevel: DTHeaderLevelKey
  public let shadows: DTShadowsKey
  public let horizontalRuleStyle: DTHorizontalRuleStyleKey
  public let textBlocks: DTTextBlocksKey
  public let field: DTFieldKey
  public let customAttributes: DTCustomAttributesKey
  public let ascentMultiplier: DTAscentMultiplierKey
  public let backgroundStrokeColor: DTBackgroundStrokeColorKey
  public let backgroundStrokeWidth: DTBackgroundStrokeWidthKey
  public let backgroundCornerRadius: DTBackgroundCornerRadiusKey

  #if canImport(UIKit)
    public let uiKit: AttributeScopes.UIKitAttributes
  #elseif canImport(AppKit)
    public let appKit: AttributeScopes.AppKitAttributes
  #endif

  #if canImport(SwiftUI)
    public let swiftUI: AttributeScopes.SwiftUIAttributes
  #endif
}

public extension AttributeScopes {
  /// DTCoreText custom attributes, including standard UIKit/AppKit and SwiftUI scopes.
  var dtCoreText: DTCoreTextAttributes.Type { DTCoreTextAttributes.self }
}

public extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(
    dynamicMember keyPath: KeyPath<DTCoreTextAttributes, T>
  ) -> T {
    self[T.self]
  }
}

// MARK: - Convenience Initializers

public extension AttributedString {

  /// Creates an `AttributedString` from HTML data, preserving all DTCoreText custom attributes.
  ///
  /// Basic text styling (fonts, colors, links) renders natively in SwiftUI `Text`.
  /// DTCoreText-specific attributes (text blocks, header levels, anchors, etc.) are preserved
  /// in the attribute runs for custom view implementations.
  ///
  /// - Parameters:
  ///   - htmlData: The HTML content as `Data`.
  ///   - options: DTCoreText builder options (e.g. base URL, default font, stylesheet).
  /// - Throws: `CocoaError(.fileReadCorruptFile)` if parsing fails.
  init(htmlData data: Data, options: [String: Any] = [:]) throws {
    guard let nsAttributedString = NSAttributedString(
      htmlData: data, options: options, documentAttributes: nil)
    else {
      throw CocoaError(.fileReadCorruptFile)
    }

    self = try AttributedString(nsAttributedString, including: \.dtCoreText)
  }

  /// Creates an `AttributedString` from HTML data asynchronously, with cancellation support.
  ///
  /// - Parameters:
  ///   - htmlData: The HTML content as `Data`.
  ///   - options: DTCoreText builder options.
  /// - Throws: `CocoaError(.fileReadCorruptFile)` if parsing fails, `CancellationError` if cancelled.
  init(htmlData data: Data, options: [String: Any] = [:]) async throws {
    guard let builder = HTMLAttributedStringBuilder(html: data, options: options) else {
      throw CocoaError(.fileReadCorruptFile)
    }

    guard let nsAttributedString = await builder.generatedAttributedString() else {
      throw CocoaError(.fileReadCorruptFile)
    }

    self = try AttributedString(nsAttributedString, including: \.dtCoreText)
  }
}
