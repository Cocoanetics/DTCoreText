import Foundation

// MARK: - Unicode Characters

public let UNICODE_OBJECT_PLACEHOLDER = "\u{fffc}"
public let UNICODE_LINE_FEED = "\u{2028}"

// MARK: - Unicode Spaces

public let UNICODE_NON_BREAKING_SPACE = "\u{00a0}"
public let UNICODE_OGHAM_SPACE_MARK = "\u{1680}"
public let UNICODE_MONGOLIAN_VOWEL_SEPARATOR = "\u{180e}"
public let UNICODE_EN_QUAD = "\u{2000}"
public let UNICODE_EM_QUAD = "\u{2001}"
public let UNICODE_EN_SPACE = "\u{2002}"
public let UNICODE_EM_SPACE = "\u{2003}"
public let UNICODE_THREE_PER_EM_SPACE = "\u{2004}"
public let UNICODE_FOUR_PER_EM_SPACE = "\u{2005}"
public let UNICODE_SIX_PER_EM_SPACE = "\u{2006}"
public let UNICODE_FIGURE_SPACE = "\u{2007}"
public let UNICODE_PUNCTUATION_SPACE = "\u{2008}"
public let UNICODE_THIN_SPACE = "\u{2009}"
public let UNICODE_HAIR_SPACE = "\u{200a}"
public let UNICODE_ZERO_WIDTH_SPACE = "\u{200b}"
public let UNICODE_NARROW_NO_BREAK_SPACE = "\u{202f}"
public let UNICODE_MEDIUM_MATHEMATICAL_SPACE = "\u{205f}"
public let UNICODE_IDEOGRAPHIC_SPACE = "\u{3000}"
public let UNICODE_ZERO_WIDTH_NO_BREAK_SPACE = "\u{feff}"

// MARK: - Standard Options

public let NSBaseURLDocumentOption: String = "NSBaseURLDocumentOption"
public let NSTextEncodingNameDocumentOption: String = "NSTextEncodingNameDocumentOption"
public let NSTextSizeMultiplierDocumentOption: String = "NSTextSizeMultiplierDocumentOption"

// MARK: - Custom Options

public let DTMaxImageSize: String = "DTMaxImageSize"
public let DTDefaultFontFamily: String = "DTDefaultFontFamily"
public let DTDefaultFontName: String = "DTDefaultFontName"
public let DTDefaultFontSize: String = "DTDefaultFontSize"
public let DTDefaultFontDescriptor: String = "DTDefaultFontDescriptor"
public let DTDefaultTextColor: String = "DTDefaultTextColor"
public let DTDefaultLinkColor: String = "DTDefaultLinkColor"
public let DTDefaultLinkHighlightColor: String = "DTDefaultLinkHighlightColor"
public let DTDefaultLinkDecoration: String = "DTDefaultLinkDecoration"
public let DTDefaultTextAlignment: String = "DTDefaultTextAlignment"
public let DTDefaultLineHeightMultiplier: String = "DTDefaultLineHeightMultiplier"
public let DTDefaultFirstLineHeadIndent: String = "DTDefaultFirstLineHeadIndent"
public let DTDefaultHeadIndent: String = "DTDefaultHeadIndent"
public let DTDefaultStyleSheet: String = "DTDefaultStyleSheet"
public let DTUseiOS6Attributes: String = "DTUseiOS6Attributes"
public let DTWillFlushBlockCallBack: String = "DTWillFlushBlockCallBack"
public let DTProcessCustomHTMLAttributes: String = "DTProcessCustomHTMLAttributes"
public let DTIgnoreInlineStylesOption: String = "DTIgnoreInlineStyles"
public let DTDocumentPreserveTrailingSpaces: String = "DTDocumentPreserveTrailingSpaces"

// MARK: - Attributed String Attribute Constants

public let DTTextListsAttribute: String = "DTTextLists"
public let DTAttachmentParagraphSpacingAttribute: String = "DTAttachmentParagraphSpacing"
public let DTLinkAttribute: String = "NSLink"
public let DTLinkHighlightColorAttribute: String = "DTLinkHighlightColor"
public let DTAnchorAttribute: String = "DTAnchor"
public let DTGUIDAttribute: String = "DTGUID"
public let DTHeaderLevelAttribute: String = "DTHeaderLevel"
public let DTStrikeOutAttribute: String = "DTStrikethrough"
public let DTBackgroundColorAttribute: String = "DTBackgroundColor"
public let DTShadowsAttribute: String = "DTShadows"
public let DTHorizontalRuleStyleAttribute: String = "DTHorizontalRuleStyle"
public let DTTextBlocksAttribute: String = "DTTextBlocks"
public let DTFieldAttribute: String = "DTField"
public let DTCustomAttributesAttribute: String = "DTCustomAttributes"
public let DTAscentMultiplierAttribute: String = "DTAscentMultiplierAttribute"
public let DTBackgroundStrokeColorAttribute: String = "DTBackgroundStrokeColor"
public let DTBackgroundStrokeWidthAttribute: String = "DTBackgroundStrokeWidth"
public let DTBackgroundCornerRadiusAttribute: String = "DTBackgroundCornerRadius"
public let DTArchivingAttribute: String = "DTArchivingAttribute"

// MARK: - Field Constants

public let DTListPrefixField: String = "{listprefix}"

// MARK: - Exceptions

public let DTCoreTextFontDescriptorException: String = "DTCoreTextFontDescriptorException"

// MARK: - Enums

@objc public enum DTHTMLElementDisplayStyle: UInt {
  /// The element is inline text
  case inline = 0
  /// The element is not displayed
  case none
  /// The element is a block
  case block
  /// The element is an item in a list
  case listItem
  /// The element is a table
  case table
}

@objc public enum DTHTMLElementFloatStyle: UInt {
  /// The element does not float
  case none = 0
  /// The element should float left-aligned
  case left
  /// The element should float right-aligned
  case right
}

@objc public enum DTHTMLElementFontVariant: UInt {
  /// The element inherits the font variant
  case inherit = 0
  /// The element uses the normal font variant
  case normal
  /// The element should display in small caps
  case smallCaps
}

@objc public enum DTCoreTextLayoutFrameLinePositioningOptions: UInt {
  /// The line positioning algorithm is similar to how Safari positions lines
  case algorithmWebKit = 1
  /// The line positioning algorithm is how it was before the implementation of algorithmWebKit
  case algorithmLegacy = 2
}

// MARK: - Layouting Constants

public let CGFLOAT_WIDTH_UNKNOWN: CGFloat = 16777215.0
public let CGFLOAT_HEIGHT_UNKNOWN: CGFloat = 16777215.0

// MARK: - Macros as Functions

/// Checks if a character is whitespace (space, tab, or line ending)
public func IS_WHITESPACE(_ c: unichar) -> Bool {
  return c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0B || c == 0x0C || c == 0x0D || c == 0x85
}
