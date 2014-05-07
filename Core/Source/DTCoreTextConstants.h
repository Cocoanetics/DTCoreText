// unicode characters

#define UNICODE_OBJECT_PLACEHOLDER @"\ufffc"
#define UNICODE_LINE_FEED @"\u2028"

// unicode spaces (see http://www.cs.tut.fi/~jkorpela/chars/spaces.html)

#define UNICODE_SPACE @"\u0020"
#define UNICODE_NON_BREAKING_SPACE @"\u00a0"
#define UNICODE_OGHAM_SPACE_MARK @"\u1680"
#define UNICODE_MONGOLIAN_VOWEL_SEPARATOR @"\u180e"
#define UNICODE_EN_QUAD @"\u2000"
#define UNICODE_EM_QUAD @"\u2001"
#define UNICODE_EN_SPACE @"\u2002"
#define UNICODE_EM_SPACE @"\u2003"
#define UNICODE_THREE_PER_EM_SPACE @"\u2004"
#define UNICODE_FOUR_PER_EM_SPACE @"\u2005"
#define UNICODE_SIX_PER_EM_SPACE @"\u2006"
#define UNICODE_FIGURE_SPACE @"\u2007"
#define UNICODE_PUNCTUATION_SPACE @"\u2008"
#define UNICODE_THIN_SPACE @"\u2009"
#define UNICODE_HAIR_SPACE @"\u200a"
#define UNICODE_ZERO_WIDTH_SPACE @"\u200b"
#define UNICODE_NARROW_NO_BREAK_SPACE @"\u202f"
#define UNICODE_MEDIUM_MATHEMATICAL_SPACE @"\u205f"
#define UNICODE_IDEOGRAPHIC_SPACE @"\u3000"
#define UNICODE_ZERO_WIDTH_NO_BREAK_SPACE @"\ufeff"

// standard options

#if TARGET_OS_IPHONE
extern NSString * const NSBaseURLDocumentOption;
extern NSString * const NSTextEncodingNameDocumentOption;
extern NSString * const NSTextSizeMultiplierDocumentOption;
extern NSString * const NSAttachmentAttributeName; 
#endif

// custom options

extern NSString * const DTMaxImageSize;
extern NSString * const DTDefaultFontFamily;
extern NSString * const DTDefaultFontName;
extern NSString * const DTDefaultFontSize;
extern NSString * const DTDefaultTextColor;
extern NSString * const DTDefaultLinkColor;
extern NSString * const DTDefaultLinkDecoration;
extern NSString * const DTDefaultLinkHighlightColor;
extern NSString * const DTDefaultTextAlignment;
extern NSString * const DTDefaultLineHeightMultiplier;
extern NSString * const DTDefaultLineHeightMultiplier;
extern NSString * const DTDefaultFirstLineHeadIndent;
extern NSString * const DTDefaultHeadIndent;
extern NSString * const DTDefaultStyleSheet;
extern NSString * const DTUseiOS6Attributes;
extern NSString * const DTWillFlushBlockCallBack;
extern NSString * const DTProcessCustomHTMLAttributes;
extern NSString * const DTIgnoreInlineStylesOption;


// attributed string attribute constants

extern NSString * const DTTextListsAttribute;
extern NSString * const DTAttachmentParagraphSpacingAttribute;
extern NSString * const DTLinkAttribute;
extern NSString * const DTLinkHighlightColorAttribute;
extern NSString * const DTAnchorAttribute;
extern NSString * const DTGUIDAttribute;
extern NSString * const DTHeaderLevelAttribute;
extern NSString * const DTStrikeOutAttribute;
extern NSString * const DTBackgroundColorAttribute;
extern NSString * const DTShadowsAttribute;
extern NSString * const DTHorizontalRuleStyleAttribute;
extern NSString * const DTTextBlocksAttribute;
extern NSString * const DTFieldAttribute;
extern NSString * const DTCustomAttributesAttribute;
extern NSString * const DTAscentMultiplierAttribute;
extern NSString * const DTBackgroundStrokeColorAttribute;
extern NSString * const DTBackgroundStrokeWidthAttribute;
extern NSString * const DTBackgroundCornerRadiusAttribute;

// field constants

extern NSString * const DTListPrefixField;

// iOS 6 compatibility
extern BOOL ___useiOS6Attributes;

// exceptions
extern NSString * const DTCoreTextFontDescriptorException;

// macros

#define IS_WHITESPACE(_c) (_c == ' ' || _c == '\t' || _c == 0xA || _c == 0xB || _c == 0xC || _c == 0xD || _c == 0x85)

// types

/**
 DTHTMLElement display style
 */
typedef NS_ENUM(NSUInteger, DTHTMLElementDisplayStyle)
{
	/**
	 The element is inline text
	 */
	DTHTMLElementDisplayStyleInline = 0, // default
	
	/**
	 The element is not displayed
	 */
	DTHTMLElementDisplayStyleNone,
	
	/**
	 The element is a block
	 */
	DTHTMLElementDisplayStyleBlock,
	
	/**
	 The element is an item in a list
	 */
	DTHTMLElementDisplayStyleListItem,
	
	/**
	 The element is a table
	 */
	DTHTMLElementDisplayStyleTable,
};

/**
 DTHTMLElement floating style
 */
typedef NS_ENUM(NSUInteger, DTHTMLElementFloatStyle)
{
	/**
	 The element does not float
	 */
	DTHTMLElementFloatStyleNone = 0,
	
	
	/**
	 The element should float left-aligned
	 */
	DTHTMLElementFloatStyleLeft,
	
	
	/**
	 The element should float right-aligned
	 */
	DTHTMLElementFloatStyleRight
};

/**
 DTHTMLElement font variants
 */
typedef NS_ENUM(NSUInteger, DTHTMLElementFontVariant)
{
	/**
	 The element inherts the font variant
	 */
	DTHTMLElementFontVariantInherit = 0,
	
	/**
	 The element uses the normal font variant
	 */
	DTHTMLElementFontVariantNormal,
	
	/**
	 The element should display in small caps
	 */
	DTHTMLElementFontVariantSmallCaps
};

/**
 The algorithm that DTCoreTextLayoutFrame uses for positioning lines
 */
typedef NS_ENUM(NSUInteger, DTCoreTextLayoutFrameLinePositioningOptions)
{
	/**
	 The line positioning algorithm is similar to how Safari positions lines
	 */
	DTCoreTextLayoutFrameLinePositioningOptionAlgorithmWebKit = 1,
	
	/**
	 The line positioning algorithm is how it was before the implementation of DTCoreTextLayoutFrameLinePositioningOptionAlgorithmWebKit
	 */
	DTCoreTextLayoutFrameLinePositioningOptionAlgorithmLegacy = 2
};

// layouting

// the value to use if the width is unknown
#define CGFLOAT_WIDTH_UNKNOWN 16777215.0f

// the value to use if the height is unknown
#define CGFLOAT_HEIGHT_UNKNOWN 16777215.0f

