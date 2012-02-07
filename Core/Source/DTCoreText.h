
#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#endif

// global constants
#import "DTCoreTextConstants.h"

// common utilities
#import "CGUtils.h"

// common classes
#import "DTCSSListStyle.h"
#import "DTCSSStylesheet.h"
#import "DTCoreText.h"
#import "DTCoreTextFontDescriptor.h"
#import "DTHTMLElement.h"
#import "DTTextAttachment.h"
#import "NSCharacterSet+HTML.h"
#import "NSData+DTBase64.h"
#import "NSScanner+HTML.h"
#import "NSString+CSS.h"
#import "NSString+HTML.h"
#import "NSString+Paragraphs.h"
#import "NSString+UTF8Cleaner.h"
#import "NSURL+HTML.h"
#import "DTCoreTextParagraphStyle.h"
#import "NSMutableAttributedString+HTML.h"
#import "NSAttributedString+SmallCaps.h"
#import "NSAttributedString+DTCoreText.h"

// DTColor is UIColor on iOS, NSColor on Mac
#import "DTColor+HTML.h"

// DTImage is UIImage on iOS, NSImage on Mac
#import "DTImage+HTML.h"

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