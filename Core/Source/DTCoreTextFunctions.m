//
//  DTCoreTextFunctions.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFunctions.h"
#import "DTLog.h"

#if TARGET_OS_IPHONE
CTFontRef DTCTFontCreateWithUIFont(UIFont *font)
{
	return CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
}
#endif

CTLineTruncationType DTCTLineTruncationTypeFromNSLineBreakMode(NSLineBreakMode lineBreakMode)
{
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
	switch (lineBreakMode)
	{
		case UILineBreakModeHeadTruncation:
			return kCTLineTruncationStart;
			
		case UILineBreakModeMiddleTruncation:
			return kCTLineTruncationMiddle;
			
		default:
			return kCTLineTruncationEnd;
	}
#else
	switch (lineBreakMode)
	{
		case NSLineBreakByTruncatingHead:
			return kCTLineTruncationStart;
			
		case NSLineBreakByTruncatingMiddle:
			return kCTLineTruncationMiddle;
			
		default:
			return kCTLineTruncationEnd;
	}
#endif
}

CGFloat DTRoundWithContentScale(CGFloat value, CGFloat contentScale)
{
	return round(value*contentScale)/contentScale;
}

CGFloat DTCeilWithContentScale(CGFloat value, CGFloat contentScale)
{
	return ceil(value*contentScale)/contentScale;
}

CGFloat DTFloorWithContentScale(CGFloat value, CGFloat contentScale)
{
	return floor(value*contentScale)/contentScale;
}

#pragma mark - Alignment Functions

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES

CTTextAlignment DTNSTextAlignmentToCTTextAlignment(NSTextAlignment nsTextAlignment)
{
	switch (nsTextAlignment)
	{
#if TARGET_OS_IPHONE
		case NSTextAlignmentLeft:
		{
			return kCTTextAlignmentLeft;
		}
			
		case NSTextAlignmentRight:
		{
			return kCTTextAlignmentRight;
		}
			
		case NSTextAlignmentCenter:
		{
			return kCTTextAlignmentCenter;
		}
			
		case NSTextAlignmentJustified:
		{
			return kCTTextAlignmentJustified;
		}
			
		case NSTextAlignmentNatural:
		{
			return kCTTextAlignmentNatural;
		}
#else
		case NSLeftTextAlignment:
		{
			return kCTTextAlignmentLeft;
		}
			
		case NSRightTextAlignment:
		{
			return kCTTextAlignmentRight;
		}
			
		case NSCenterTextAlignment:
		{
			return kCTTextAlignmentCenter;
		}
			
		case NSJustifiedTextAlignment:
		{
			return kCTTextAlignmentJustified;
		}

		case NSNaturalTextAlignment:
		{
			return kCTTextAlignmentNatural;
		}
#endif
			
		default:
		{
			DTLogError(@"Unknown alignment %d", (int)nsTextAlignment);
			return 0;
		}
	}
}

NSTextAlignment DTNSTextAlignmentFromCTTextAlignment(CTTextAlignment ctTextAlignment)
{
#if TARGET_OS_IPHONE
	switch (ctTextAlignment)
	{
		case kCTTextAlignmentLeft:
		{
			return NSTextAlignmentLeft;
		}
			
		case kCTTextAlignmentRight:
		{
			return NSTextAlignmentRight;
		}
			
		case kCTTextAlignmentCenter:
		{
			return NSTextAlignmentCenter;
		}
			
		case kCTTextAlignmentJustified:
		{
			return NSTextAlignmentJustified;
		}
			
		case kCTTextAlignmentNatural:
		{
			return NSTextAlignmentNatural;
		}
	}
#else
	switch (ctTextAlignment)
	{
		case kCTTextAlignmentLeft:
		{
			return NSLeftTextAlignment;
		}
			
		case kCTTextAlignmentRight:
		{
			return NSRightTextAlignment;
		}
			
		case kCTTextAlignmentCenter:
		{
			return NSCenterTextAlignment;
		}
			
		case kCTTextAlignmentJustified:
		{
			return NSJustifiedTextAlignment;
		}
			
		case kCTTextAlignmentNatural:
		{
			return NSNaturalTextAlignment;
		}
	}
#endif
}

#endif


