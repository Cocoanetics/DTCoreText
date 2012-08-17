#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

// global constants
#import "DTCoreTextConstants.h"
#import "DTCompatibility.h"

#import "DTColor+HTML.h"
#import "DTImage+HTML.h"

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
#import "DTCoreTextParagraphStyle.h"
#import "NSMutableAttributedString+HTML.h"
#import "NSAttributedString+HTML.h"
#import "NSAttributedString+SmallCaps.h"
#import "NSAttributedString+DTCoreText.h"
#import "DTHTMLAttributedStringBuilder.h"


// These classes only work with UIKit on iOS
#if TARGET_OS_IPHONE


#import "DTLazyImageView.h"
#import "DTLinkButton.h"
#import "DTWebVideoView.h"
#import "NSAttributedStringRunDelegates.h"

#import "UIDevice+DTSimpleVersion.h"

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
