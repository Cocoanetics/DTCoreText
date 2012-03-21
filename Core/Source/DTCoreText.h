#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#endif

// global constants
#import "DTCoreTextConstants.h"

// DTColor is UIColor on iOS, NSColor on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTColor UIColor;
#else
@compatibility_alias DTColor NSColor;
#endif

#import "DTColor+HTML.h"

// DTImage is UIImage on iOS, NSImage on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTImage UIImage;
#else
@compatibility_alias DTImage NSImage;
#endif

#import "DTImage+HTML.h"

// DTEdgeInsets is UIEdgeInsets on iOS, NSEdgeInsets on Mac
#if TARGET_OS_IPHONE
#define DTEdgeInsets UIEdgeInsets
#define DTEdgeInsetsMake(a, b, c, d) UIEdgeInsetsMake(a, b, c, d)
#else
#define DTEdgeInsets NSEdgeInsets
#define DTEdgeInsetsMake(a, b, c, d) NSEdgeInsetsMake(a, b, c, d)
#endif

// common utilities
#import "CGUtils.h"

// common classes
#import "DTCSSListStyle.h"
#import "DTTextBlock.h"
#import "DTCSSStylesheet.h"
#import "DTCoreText.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTHTMLElement.h"
#import "DTTextAttachment.h"
#import "NSCharacterSet+HTML.h"
#import "NSData+DTBase64.h"
#import "NSScanner+HTML.h"
#import "NSMutableString+HTML.h"
#import "NSString+CSS.h"
#import "NSString+HTML.h"
#import "NSString+Paragraphs.h"
#import "NSString+UTF8Cleaner.h"
#import "DTCoreTextParagraphStyle.h"
#import "NSMutableAttributedString+HTML.h"
#import "NSAttributedString+SmallCaps.h"
#import "NSAttributedString+DTCoreText.h"


// These classes only work with UIKit on iOS
#if TARGET_OS_IPHONE

#import "NSAttributedString+HTML.h"

#import "DTLazyImageView.h"
#import "DTLinkButton.h"
#import "DTWebVideoView.h"
#import "NSAttributedStringRunDelegates.h"

#import "UIDevice+DTVersion.h"

#import "DTAttributedTextCell.h"
#import "DTAttributedTextContentView.h"
#import "DTAttributedTextView.h"
#import "DTCoreTextFontCollection.h"
#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextLayouter.h"

#endif


#define DT_ADD_FONT_ON_ATTACHMENTS
