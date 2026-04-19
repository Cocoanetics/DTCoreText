import Foundation

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

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
//
// On AppKit, .baseURL / .textEncodingName / .textSizeMultiplier are provided
// by the system.  On UIKit and other platforms they don't exist, so we add
// them with matching raw values for cross-platform consistency.

#if !canImport(AppKit) || targetEnvironment(macCatalyst)
extension NSAttributedString.DocumentReadingOptionKey {
  /// Base URL used to resolve relative links and resources when parsing HTML.
  public static let baseURL = NSAttributedString.DocumentReadingOptionKey("BaseURL")

  /// IANA text encoding name used when decoding HTML data.
  public static let textEncodingName = NSAttributedString.DocumentReadingOptionKey(
    "TextEncodingName")

  /// Scale factor applied to HTML font sizes on import.
  public static let textSizeMultiplier = NSAttributedString.DocumentReadingOptionKey(
    "TextSizeMultiplier")
}
#endif

public let NSBaseURLDocumentOption: String =
  NSAttributedString.DocumentReadingOptionKey.baseURL.rawValue
public let NSTextEncodingNameDocumentOption: String =
  NSAttributedString.DocumentReadingOptionKey.textEncodingName.rawValue
public let NSTextSizeMultiplierDocumentOption: String =
  NSAttributedString.DocumentReadingOptionKey.textSizeMultiplier.rawValue

// MARK: - Custom Options

extension NSAttributedString.DocumentReadingOptionKey {
  /// Maximum image size (`NSValue` wrapping a `CGSize`).
  public static let maxImageSize = NSAttributedString.DocumentReadingOptionKey("DTMaxImageSize")

  /// Default font family name (`String`).
  public static let defaultFontFamily = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultFontFamily")

  /// Default font name (`String`).
  public static let defaultFontName = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultFontName")

  /// Default font size in points (`Double`).
  public static let defaultFontSize = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultFontSize")

  /// Default font descriptor (`CoreTextFontDescriptor`).
  public static let defaultFontDescriptor = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultFontDescriptor")

  /// Default text color (`DTColor`).
  public static let defaultTextColor = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultTextColor")

  /// Default link color (`DTColor`).
  public static let defaultLinkColor = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultLinkColor")

  /// Default link highlight color (`DTColor`).
  public static let defaultLinkHighlightColor = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultLinkHighlightColor")

  /// Whether links should be decorated with underline (`Bool`).
  public static let defaultLinkDecoration = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultLinkDecoration")

  /// Default text alignment (`Int` from `CTTextAlignment`).
  public static let defaultTextAlignment = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultTextAlignment")

  /// Default line-height multiplier (`Double`).
  public static let defaultLineHeightMultiplier = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultLineHeightMultiplier")

  /// Default first-line head indent in pixels (`Int`).
  public static let defaultFirstLineHeadIndent = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultFirstLineHeadIndent")

  /// Default head indent in pixels (`Int`).
  public static let defaultHeadIndent = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultHeadIndent")

  /// Default CSS stylesheet (`CSSStylesheet`).
  public static let defaultStyleSheet = NSAttributedString.DocumentReadingOptionKey(
    "DTDefaultStyleSheet")

  /// Whether to use iOS 6-era attributes (`Bool`).
  public static let useiOS6Attributes = NSAttributedString.DocumentReadingOptionKey(
    "DTUseiOS6Attributes")

  /// Whether to process custom HTML attributes (`Bool`).
  public static let processCustomHTMLAttributes = NSAttributedString.DocumentReadingOptionKey(
    "DTProcessCustomHTMLAttributes")

  /// Whether to ignore inline CSS styles (`Bool`).
  public static let ignoreInlineStyles = NSAttributedString.DocumentReadingOptionKey(
    "DTIgnoreInlineStyles")

  /// Whether to preserve trailing whitespace in the document (`Bool`).
  public static let documentPreserveTrailingSpaces = NSAttributedString.DocumentReadingOptionKey(
    "DTDocumentPreserveTrailingSpaces")

  /// A callback block executed whenever content is about to be flushed to
  /// the output string during HTML parsing. The block receives the
  /// `HTMLElement` that is about to be flushed and may modify it before
  /// it is converted to an attributed string.
  public static let willFlushBlockCallBack = NSAttributedString.DocumentReadingOptionKey(
    "DTWillFlushBlockCallBack")
}

public let DTMaxImageSize: String =
  NSAttributedString.DocumentReadingOptionKey.maxImageSize.rawValue
public let DTDefaultFontFamily: String =
  NSAttributedString.DocumentReadingOptionKey.defaultFontFamily.rawValue
public let DTDefaultFontName: String =
  NSAttributedString.DocumentReadingOptionKey.defaultFontName.rawValue
public let DTDefaultFontSize: String =
  NSAttributedString.DocumentReadingOptionKey.defaultFontSize.rawValue
public let DTDefaultFontDescriptor: String =
  NSAttributedString.DocumentReadingOptionKey.defaultFontDescriptor.rawValue
public let DTDefaultTextColor: String =
  NSAttributedString.DocumentReadingOptionKey.defaultTextColor.rawValue
public let DTDefaultLinkColor: String =
  NSAttributedString.DocumentReadingOptionKey.defaultLinkColor.rawValue
public let DTDefaultLinkHighlightColor: String =
  NSAttributedString.DocumentReadingOptionKey.defaultLinkHighlightColor.rawValue
public let DTDefaultLinkDecoration: String =
  NSAttributedString.DocumentReadingOptionKey.defaultLinkDecoration.rawValue
public let DTDefaultTextAlignment: String =
  NSAttributedString.DocumentReadingOptionKey.defaultTextAlignment.rawValue
public let DTDefaultLineHeightMultiplier: String =
  NSAttributedString.DocumentReadingOptionKey.defaultLineHeightMultiplier.rawValue
public let DTDefaultFirstLineHeadIndent: String =
  NSAttributedString.DocumentReadingOptionKey.defaultFirstLineHeadIndent.rawValue
public let DTDefaultHeadIndent: String =
  NSAttributedString.DocumentReadingOptionKey.defaultHeadIndent.rawValue
public let DTDefaultStyleSheet: String =
  NSAttributedString.DocumentReadingOptionKey.defaultStyleSheet.rawValue
public let DTUseiOS6Attributes: String =
  NSAttributedString.DocumentReadingOptionKey.useiOS6Attributes.rawValue
public let DTProcessCustomHTMLAttributes: String =
  NSAttributedString.DocumentReadingOptionKey.processCustomHTMLAttributes.rawValue
public let DTIgnoreInlineStylesOption: String =
  NSAttributedString.DocumentReadingOptionKey.ignoreInlineStyles.rawValue
public let DTDocumentPreserveTrailingSpaces: String =
  NSAttributedString.DocumentReadingOptionKey.documentPreserveTrailingSpaces.rawValue
public let DTWillFlushBlockCallBack: String =
  NSAttributedString.DocumentReadingOptionKey.willFlushBlockCallBack.rawValue

// MARK: - Attributed String Attribute Constants

/// Legacy attribute key for the list-stack array. **Read-only / legacy.** New DTCoreText
/// output stores the list array on `NSParagraphStyle.textLists` instead. This key is kept
/// so that attributed strings persisted under the pre-migration scheme can still be read
/// (see `NSMutableAttributedString.dtct_migrateLegacyListAttribute()`), but DTCoreText no
/// longer writes it on emission.
public let DTTextListsAttribute: String = "DTTextLists"
public let DTAttachmentParagraphSpacingAttribute: String = "DTAttachmentParagraphSpacing"
public let DTLinkAttribute: String = "NSLink"
public let DTLinkHighlightColorAttribute: String = "DTLinkHighlightColor"
public let DTAnchorAttribute: String = "DTAnchor"
public let DTGUIDAttribute: String = "DTGUID"
public let DTHeaderLevelAttribute: String = "DTHeaderLevel"
public let DTStrikeOutAttribute: String = NSAttributedString.Key.strikethroughStyle.rawValue
public let DTBackgroundColorAttribute: String = NSAttributedString.Key.backgroundColor.rawValue
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

// MARK: - Layouting Constants

public let CGFLOAT_WIDTH_UNKNOWN: CGFloat = 16777215.0
public let CGFLOAT_HEIGHT_UNKNOWN: CGFloat = 16777215.0

// MARK: - Macros as Functions

/// Checks if a character is whitespace (space, tab, or line ending)
public func IS_WHITESPACE(_ c: unichar) -> Bool {
  return c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0B || c == 0x0C || c == 0x0D || c == 0x85
}
