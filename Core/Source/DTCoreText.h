#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

// global constants
#import "DTCoreTextMacros.h"
#import "DTCoreTextConstants.h"
#import "DTCompatibility.h"

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
#import "DTHTMLElement.h"
#import "DTAnchorHTMLElement.h"
#import "DTBreakHTMLElement.h"
#import "DTListItemHTMLElement.h"
#import "DTHorizontalRuleHTMLElement.h"
#import "DTStylesheetHTMLElement.h"
#import "DTTextAttachmentHTMLElement.h"
#import "DTTextHTMLElement.h"
#import "NSCharacterSet+HTML.h"
#import "NSCoder+DTCompatibility.h"
#import "NSDictionary+DTCoreText.h"
#import "NSAttributedString+SmallCaps.h"
#import "NSMutableAttributedString+HTML.h"
#import "NSScanner+HTML.h"
#import "NSString+CSS.h"
#import "NSString+HTML.h"
#import "NSString+Paragraphs.h"
#import "NSNumber+RomanNumerals.h"

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

#import "NSAttributedStringRunDelegates.h"

#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextLayouter.h"

// TARGET_OS_IPHONE is both tvOS and iOS
#if TARGET_OS_IPHONE

#import "DTCoreTextFontCollection.h"

#import "UIFont+DTCoreText.h"


#endif

