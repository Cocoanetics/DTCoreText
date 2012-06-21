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
NSString * const DTDefaultTextColor = @"DTDefaultTextColor";
NSString * const DTDefaultLinkColor = @"DTDefaultLinkColor";
NSString * const DTDefaultLinkDecoration = @"DTDefaultLinkDecoration";
NSString * const DTDefaultTextAlignment = @"DTDefaultTextAlignment";
NSString * const DTDefaultLineHeightMultiplier = @"DTDefaultLineHeightMultiplier";
NSString * const DTDefaultFirstLineHeadIndent = @"DTDefaultFirstLineHeadIndent";
NSString * const DTDefaultHeadIndent = @"DTDefaultHeadIndent";
NSString * const DTDefaultListIndent = @"DTDefaultListIndent";
NSString * const DTDefaultStyleSheet = @"DTDefaultStyleSheet";
NSString * const DTWillFlushBlockCallBack = @"DTWillFlushBlockCallBack";

// attributed string attribute constants

NSString * const DTTextListsAttribute = @"DTTextLists";
NSString * const DTAttachmentParagraphSpacingAttribute = @"DTAttachmentParagraphSpacing";
NSString * const DTLinkAttribute = @"DTLink";
NSString * const DTAnchorAttribute = @"DTAnchor";
NSString * const DTGUIDAttribute = @"DTGUID";
NSString * const DTHeaderLevelAttribute = @"DTHeaderLevel";
NSString * const DTPreserveNewlinesAttribute = @"DTPreserveNewlines";
NSString * const DTStrikeOutAttribute = @"DTStrikeOut";
NSString * const DTBackgroundColorAttribute = @"DTBackgroundColor";
NSString * const DTShadowsAttribute = @"DTShadows";
NSString * const DTHorizontalRuleStyleAttribute = @"DTHorizontalRuleStyle";
NSString * const DTTextBlocksAttribute = @"DTTextBlocks";
NSString * const DTFieldAttribute = @"DTField";