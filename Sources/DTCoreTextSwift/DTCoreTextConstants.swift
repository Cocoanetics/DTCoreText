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

// MARK: - Standard Options (iOS)

#if canImport(UIKit)
@objc public let NSBaseURLDocumentOption: NSString = "NSBaseURLDocumentOption"
@objc public let NSTextEncodingNameDocumentOption: NSString = "NSTextEncodingNameDocumentOption"
@objc public let NSTextSizeMultiplierDocumentOption: NSString = "NSTextSizeMultiplierDocumentOption"
#endif

// MARK: - Custom Options

@objc public let DTMaxImageSize: NSString = "DTMaxImageSize"
@objc public let DTDefaultFontFamily: NSString = "DTDefaultFontFamily"
@objc public let DTDefaultFontName: NSString = "DTDefaultFontName"
@objc public let DTDefaultFontSize: NSString = "DTDefaultFontSize"
@objc public let DTDefaultFontDescriptor: NSString = "DTDefaultFontDescriptor"
@objc public let DTDefaultTextColor: NSString = "DTDefaultTextColor"
@objc public let DTDefaultLinkColor: NSString = "DTDefaultLinkColor"
@objc public let DTDefaultLinkHighlightColor: NSString = "DTDefaultLinkHighlightColor"
@objc public let DTDefaultLinkDecoration: NSString = "DTDefaultLinkDecoration"
@objc public let DTDefaultTextAlignment: NSString = "DTDefaultTextAlignment"
@objc public let DTDefaultLineHeightMultiplier: NSString = "DTDefaultLineHeightMultiplier"
@objc public let DTDefaultFirstLineHeadIndent: NSString = "DTDefaultFirstLineHeadIndent"
@objc public let DTDefaultHeadIndent: NSString = "DTDefaultHeadIndent"
@objc public let DTDefaultStyleSheet: NSString = "DTDefaultStyleSheet"
@objc public let DTUseiOS6Attributes: NSString = "DTUseiOS6Attributes"
@objc public let DTWillFlushBlockCallBack: NSString = "DTWillFlushBlockCallBack"
@objc public let DTProcessCustomHTMLAttributes: NSString = "DTProcessCustomHTMLAttributes"
@objc public let DTIgnoreInlineStylesOption: NSString = "DTIgnoreInlineStyles"
@objc public let DTDocumentPreserveTrailingSpaces: NSString = "DTDocumentPreserveTrailingSpaces"

// MARK: - Attributed String Attribute Constants

@objc public let DTTextListsAttribute: NSString = "DTTextLists"
@objc public let DTAttachmentParagraphSpacingAttribute: NSString = "DTAttachmentParagraphSpacing"
@objc public let DTLinkAttribute: NSString = "NSLink"
@objc public let DTLinkHighlightColorAttribute: NSString = "DTLinkHighlightColor"
@objc public let DTAnchorAttribute: NSString = "DTAnchor"
@objc public let DTGUIDAttribute: NSString = "DTGUID"
@objc public let DTHeaderLevelAttribute: NSString = "DTHeaderLevel"
@objc public let DTStrikeOutAttribute: NSString = "DTStrikethrough"
@objc public let DTBackgroundColorAttribute: NSString = "DTBackgroundColor"
@objc public let DTShadowsAttribute: NSString = "DTShadows"
@objc public let DTHorizontalRuleStyleAttribute: NSString = "DTHorizontalRuleStyle"
@objc public let DTTextBlocksAttribute: NSString = "DTTextBlocks"
@objc public let DTFieldAttribute: NSString = "DTField"
@objc public let DTCustomAttributesAttribute: NSString = "DTCustomAttributes"
@objc public let DTAscentMultiplierAttribute: NSString = "DTAscentMultiplierAttribute"
@objc public let DTBackgroundStrokeColorAttribute: NSString = "DTBackgroundStrokeColor"
@objc public let DTBackgroundStrokeWidthAttribute: NSString = "DTBackgroundStrokeWidth"
@objc public let DTBackgroundCornerRadiusAttribute: NSString = "DTBackgroundCornerRadius"
@objc public let DTArchivingAttribute: NSString = "DTArchivingAttribute"

// MARK: - Field Constants

@objc public let DTListPrefixField: NSString = "{listprefix}"

// MARK: - Exceptions

@objc public let DTCoreTextFontDescriptorException: NSString = "DTCoreTextFontDescriptorException"

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
