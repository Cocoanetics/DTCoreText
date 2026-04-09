//
//  NSAttributedString+SmallCaps.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSAttributedString+SmallCaps.h"
#import "DTCoreTextFontDescriptor.h"
#import "NSDictionary+DTCoreText.h"
#import "DTCoreTextConstants.h"


#if TARGET_OS_IPHONE
#import "UIFont+DTCoreText.h"
#endif

@implementation NSAttributedString (SmallCaps)

+ (NSAttributedString *)synthesizedSmallCapsAttributedStringWithText:(NSString *)text attributes:(NSDictionary *)attributes
{
	DTCoreTextFontDescriptor *fontDescriptor = [attributes fontDescriptor];
	
	if (!fontDescriptor)
	{
		return nil;
	}
	
	DTCoreTextFontDescriptor *smallerFontDesc = [fontDescriptor copy];
	smallerFontDesc.pointSize *= (CGFloat)0.7;
	
	CTFontRef smallerFont = [smallerFontDesc newMatchingFont];
	
	if (!smallerFont)
	{
		return nil;
	}
	
	NSMutableDictionary *smallAttributes = [attributes mutableCopy];

#if TARGET_OS_IPHONE
	UIFont *uiFont = [UIFont fontWithCTFont:smallerFont];
	[smallAttributes setObject:uiFont forKey:NSFontAttributeName];
	CFRelease(smallerFont);
#else
	[smallAttributes setObject:(__bridge id)(smallerFont) forKey:NSFontAttributeName];
	CFRelease(smallerFont);
#endif
	
	NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
	NSScanner *scanner = [NSScanner scannerWithString:text];
	[scanner setCharactersToBeSkipped:nil];
	
	NSCharacterSet *lowerCaseChars = [NSCharacterSet lowercaseLetterCharacterSet];
	
	while (![scanner isAtEnd])
	{
		NSString *part;
		
		if ([scanner scanCharactersFromSet:lowerCaseChars intoString:&part])
		{
			part = [part uppercaseString];
			NSAttributedString *partString = [[NSAttributedString alloc] initWithString:part attributes:smallAttributes];
			[tmpString appendAttributedString:partString];
		}
		
		if ([scanner scanUpToCharactersFromSet:lowerCaseChars intoString:&part])
		{
			NSAttributedString *partString = [[NSAttributedString alloc] initWithString:part attributes:attributes];
			[tmpString appendAttributedString:partString];
		}
	}
	
	return tmpString;
}

@end
