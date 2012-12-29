// unicode characters

#define UNICODE_OBJECT_PLACEHOLDER @"\ufffc"
#define UNICODE_LINE_FEED @"\u2028"

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
extern NSString * const DTDefaultTextColor;
extern NSString * const DTDefaultLinkColor;
extern NSString * const DTDefaultLinkDecoration;
extern NSString * const DTDefaultTextAlignment;
extern NSString * const DTDefaultLineHeightMultiplier;
extern NSString * const DTDefaultLineHeightMultiplier;
extern NSString * const DTDefaultFirstLineHeadIndent;
extern NSString * const DTDefaultHeadIndent;
extern NSString * const DTDefaultListIndent;
extern NSString * const DTDefaultStyleSheet;
extern NSString * const DTUseiOS6Attributes;
extern NSString * const DTWillFlushBlockCallBack;

// attributed string attribute constants

extern NSString * const DTTextListsAttribute;
extern NSString * const DTAttachmentParagraphSpacingAttribute;
extern NSString * const DTLinkAttribute;
extern NSString * const DTAnchorAttribute;
extern NSString * const DTGUIDAttribute;
extern NSString * const DTHeaderLevelAttribute;
extern NSString * const DTPreserveNewlinesAttribute;
extern NSString * const DTStrikeOutAttribute;
extern NSString * const DTBackgroundColorAttribute;
extern NSString * const DTShadowsAttribute;
extern NSString * const DTHorizontalRuleStyleAttribute;
extern NSString * const DTTextBlocksAttribute;
extern NSString * const DTFieldAttribute;

// iOS 6 compatibility
extern BOOL ___useiOS6Attributes;

// macros

#define IS_WHITESPACE(_c) (_c == ' ' || _c == '\t' || _c == 0xA || _c == 0xB || _c == 0xC || _c == 0xD || _c == 0x85)

// types

typedef enum
{
	DTHTMLElementDisplayStyleInline = 0, // default
	DTHTMLElementDisplayStyleNone,
	DTHTMLElementDisplayStyleBlock,
	DTHTMLElementDisplayStyleListItem,
	DTHTMLElementDisplayStyleTable,
} DTHTMLElementDisplayStyle;

typedef enum
{
	DTHTMLElementFloatStyleNone = 0,
	DTHTMLElementFloatStyleLeft,
	DTHTMLElementFloatStyleRight
} DTHTMLElementFloatStyle;

typedef enum
{
	DTHTMLElementFontVariantInherit = 0,
	DTHTMLElementFontVariantNormal,
	DTHTMLElementFontVariantSmallCaps
} DTHTMLElementFontVariant;