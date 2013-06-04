#import "DTCoreTextConstants.h"

// standard options

#if TARGET_OS_IPHONE
NSString * const NSBaseURLDocumentOption = @"NSBaseURLDocumentOption";
NSString * const NSTextEncodingNameDocumentOption = @"NSTextEncodingNameDocumentOption";
NSString * const NSTextSizeMultiplierDocumentOption = @"NSTextSizeMultiplierDocumentOption";
NSString * const NSAttachmentAttributeName = @"NSAttachmentAttributeName";
#endif

// custom options

NSString * const DTMaxImageSize = @"DTMaxImageSize";
NSString * const DTDefaultFontFamily = @"DTDefaultFontFamily";
NSString * const DTDefaultFontSize = @"DTDefaultFontSize";
NSString * const DTDefaultTextColor = @"DTDefaultTextColor";
NSString * const DTDefaultLinkColor = @"DTDefaultLinkColor";
NSString * const DTDefaultLinkHighlightColor = @"DTDefaultLinkHighlightColor";
NSString * const DTDefaultLinkDecoration = @"DTDefaultLinkDecoration";
NSString * const DTDefaultTextAlignment = @"DTDefaultTextAlignment";
NSString * const DTDefaultLineHeightMultiplier = @"DTDefaultLineHeightMultiplier";
NSString * const DTDefaultFirstLineHeadIndent = @"DTDefaultFirstLineHeadIndent";
NSString * const DTDefaultHeadIndent = @"DTDefaultHeadIndent";
NSString * const DTDefaultStyleSheet = @"DTDefaultStyleSheet";
NSString * const DTUseiOS6Attributes = @"DTUseiOS6Attributes";
NSString * const DTWillFlushBlockCallBack = @"DTWillFlushBlockCallBack";

// attributed string attribute constants

NSString * const DTTextListsAttribute = @"DTTextLists";
NSString * const DTAttachmentParagraphSpacingAttribute = @"DTAttachmentParagraphSpacing";
NSString * const DTLinkAttribute = @"NSLinkAttributeName";
NSString * const DTLinkHighlightColorAttribute = @"DTLinkHighlightColor";
NSString * const DTAnchorAttribute = @"DTAnchor";
NSString * const DTGUIDAttribute = @"DTGUID";
NSString * const DTHeaderLevelAttribute = @"DTHeaderLevel";
NSString * const DTStrikeOutAttribute = @"NSStrikethrough";
NSString * const DTBackgroundColorAttribute = @"DTBackgroundColor";
NSString * const DTShadowsAttribute = @"DTShadows";
NSString * const DTHorizontalRuleStyleAttribute = @"DTHorizontalRuleStyle";
NSString * const DTTextBlocksAttribute = @"DTTextBlocks";
NSString * const DTFieldAttribute = @"DTField";

// field constants
NSString * const DTListPrefixField = @"{listprefix}";

// iOS 6 compatibility

BOOL ___useiOS6Attributes = NO; // this gets set globally by DTHTMLAttributedStringBuilder