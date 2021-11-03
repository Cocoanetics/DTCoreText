#import "DTCoreTextConstants.h"

// standard options

#if TARGET_OS_IPHONE
NSString * const NSBaseURLDocumentOption = @"NSBaseURLDocumentOption";
NSString * const NSTextEncodingNameDocumentOption = @"NSTextEncodingNameDocumentOption";
NSString * const NSTextSizeMultiplierDocumentOption = @"NSTextSizeMultiplierDocumentOption";

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_7_0
NSString * const NSAttachmentAttributeName = @"NSAttachmentAttributeName";
#endif

#endif

// custom options

NSString * const DTMaxImageSize = @"DTMaxImageSize";
NSString * const DTDefaultFontFamily = @"DTDefaultFontFamily";
NSString * const DTDefaultFontName = @"DTDefaultFontName";
NSString * const DTDefaultFontSize = @"DTDefaultFontSize";
NSString * const DTDefaultFontDescriptor = @"DTDefaultFontDescriptor";
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
NSString * const DTProcessCustomHTMLAttributes = @"DTProcessCustomHTMLAttributes";
NSString * const DTIgnoreInlineStylesOption = @"DTIgnoreInlineStyles";
NSString * const DTDocumentPreserveTrailingSpaces = @"DTDocumentPreserveTrailingSpaces";

// attributed string attribute constants

NSString * const DTTextListsAttribute = @"DTTextLists";
NSString * const DTAttachmentParagraphSpacingAttribute = @"DTAttachmentParagraphSpacing";
NSString * const DTLinkAttribute = @"NSLink";
NSString * const DTLinkHighlightColorAttribute = @"DTLinkHighlightColor";
NSString * const DTAnchorAttribute = @"DTAnchor";
NSString * const DTGUIDAttribute = @"DTGUID";
NSString * const DTHeaderLevelAttribute = @"DTHeaderLevel";
NSString * const DTStrikeOutAttribute = @"DTStrikethrough";
NSString * const DTBackgroundColorAttribute = @"DTBackgroundColor";
NSString * const DTShadowsAttribute = @"DTShadows";
NSString * const DTHorizontalRuleStyleAttribute = @"DTHorizontalRuleStyle";
NSString * const DTTextBlocksAttribute = @"DTTextBlocks";
NSString * const DTFieldAttribute = @"DTField";
NSString * const DTCustomAttributesAttribute = @"DTCustomAttributes";
NSString * const DTAscentMultiplierAttribute = @"DTAscentMultiplierAttribute";
NSString * const DTBackgroundStrokeColorAttribute = @"DTBackgroundStrokeColor";
NSString * const DTBackgroundStrokeWidthAttribute = @"DTBackgroundStrokeWidth";
NSString * const DTBackgroundCornerRadiusAttribute = @"DTBackgroundCornerRadius";
NSString * const DTArchivingAttribute = @"DTArchivingAttribute";

// field constants
NSString * const DTListPrefixField = @"{listprefix}";

// iOS 6 compatibility

BOOL ___useiOS6Attributes = NO; // this gets set globally by DTHTMLAttributedStringBuilder


// exceptions

NSString * const DTCoreTextFontDescriptorException = @"DTCoreTextFontDescriptorException";

