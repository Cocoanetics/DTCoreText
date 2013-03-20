//
//  DTCoreTextFunctions.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTCoreTextFunctions.h"

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
	return roundf(value*contentScale)/contentScale;
}

CGFloat DTCeilWithContentScale(CGFloat value, CGFloat contentScale)
{
	return ceilf(value*contentScale)/contentScale;
}

CGFloat DTFloorWithContentScale(CGFloat value, CGFloat contentScale)
{
	return floorf(value*contentScale)/contentScale;
}


