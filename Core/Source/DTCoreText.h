#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

// global constants
#import "DTCoreTextMacros.h"
#import "DTCoreTextConstants.h"
#import "DTCompatibility.h"

#import "DTColor+Compatibility.h"
#import "DTImage+HTML.h"

// common utilities
#if TARGET_OS_IPHONE
#import "DTCoreTextFunctions.h"
#endif

#import "DTColorFunctions.h"

// common classes
#import "DTCSSListStyle.h"
#import "DTTextBlock.h"
#import "DTCSSStylesheet.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTHTMLAttributedStringBuilder.h"
#import "DTHTMLElement.h"
#import "DTAnchorHTMLElement.h"
#import "DTBreakHTMLElement.h"
#import "DTListItemHTMLElement.h"
#import "DTHorizontalRuleHTMLElement.h"
#import "DTStyleSheetHTMLElement.h"
#import "DTTextAttachmentHTMLElement.h"
#import "DTTextHTMLElement.h"
#import "DTHTMLWriter.h"
#import "NSCharacterSet+HTML.h"
#import "NSCoder+DTCompatibility.h"
#import "NSDictionary+DTCoreText.h"
#import "NSAttributedString+HTML.h"
#import "NSAttributedString+SmallCaps.h"
#import "NSAttributedString+DTCoreText.h"
#import "NSMutableAttributedString+HTML.h"
#import "NSMutableString+HTML.h"
#import "NSScanner+HTML.h"
#import "NSString+CSS.h"
#import "NSString+HTML.h"
#import "NSString+Paragraphs.h"

// parsing classes
#import "DTHTMLParserNode.h"
#import "DTHTMLParserTextNode.h"

// text attachment cluster
#import "DTTextAttachment.h"
#import "DTDictationPlaceholderTextAttachment.h"
#import "DTIframeTextAttachment.h"
#import "DTImageTextAttachment.h"
#import "DTObjectTextAttachment.h"
#import "DTVideoTextAttachment.h"

// These classes only work with UIKit on iOS
#if TARGET_OS_IPHONE

#import "DTLazyImageView.h"
#import "DTLinkButton.h"
#import "DTWebVideoView.h"
#import "NSAttributedStringRunDelegates.h"

#import "DTAttributedLabel.h"
#import "DTAttributedTextCell.h"
#import "DTAttributedTextContentView.h"
#import "DTAttributedTextView.h"
#import "DTCoreTextFontCollection.h"
#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayoutFrame+Cursor.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextLayouter.h"

#import "DTDictationPlaceholderView.h"

#import "UIFont+DTCoreText.h"

#import "DTAccessibilityElement.h"
#import "DTAccessibilityViewProxy.h"
#import "DTCoreTextLayoutFrameAccessibilityElementGenerator.h"

#endif

