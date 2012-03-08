// unicode characters

#define UNICODE_OBJECT_PLACEHOLDER @"\ufffc"
#define UNICODE_LINE_FEED @"\u2028"

// standard options

extern NSString *NSBaseURLDocumentOption;
extern NSString *NSTextEncodingNameDocumentOption;
extern NSString *NSTextSizeMultiplierDocumentOption;
extern NSString *NSAttachmentAttributeName; 

// custom options

extern NSString *DTMaxImageSize;
extern NSString *DTDefaultFontFamily;
extern NSString *DTDefaultTextColor;
extern NSString *DTDefaultLinkColor;
extern NSString *DTDefaultLinkDecoration;
extern NSString *DTDefaultTextAlignment;
extern NSString *DTDefaultLineHeightMultiplier;
extern NSString *DTDefaultLineHeightMultiplier;
extern NSString *DTDefaultFirstLineHeadIndent;
extern NSString *DTDefaultHeadIndent;
extern NSString *DTDefaultListIndent;
extern NSString *DTDefaultStyleSheet;

// attributed string attribute constants

extern NSString *DTTextListsAttribute;
extern NSString *DTAttachmentParagraphSpacingAttribute;
extern NSString *DTLinkAttribute;
extern NSString *DTGUIDAttribute;
extern NSString *DTHeaderLevelAttribute;
extern NSString *DTPreserveNewlinesAttribute;
extern NSString *DTStrikeOutAttribute;
extern NSString *DTBackgroundColorAttribute;
extern NSString *DTShadowsAttribute;
extern NSString *DTHorizontalRuleStyleAttribute;
extern NSString *DTTextBlocksAttribute;
extern NSString *DTFieldAttribute;

// macros

#define IS_WHITESPACE(_c) (_c == ' ' || _c == '\t' || _c == 0xA || _c == 0xB || _c == 0xC || _c == 0xD || _c == 0x85)