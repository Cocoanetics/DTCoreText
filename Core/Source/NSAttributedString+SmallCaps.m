//
//  NSAttributedString+SmallCaps.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 31.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "NSAttributedString+SmallCaps.h"
#import "DTCoreText.h"

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

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES && TARGET_OS_IPHONE
	if (___useiOS6Attributes)
	{
		UIFont *uiFont = [UIFont fontWithCTFont:smallerFont];
		
		[smallAttributes setObject:uiFont forKey:NSFontAttributeName];
		
		CFRelease(smallerFont);
	}
	else
#endif
	{
		[smallAttributes setObject:CFBridgingRelease(smallerFont) forKey:(id)kCTFontAttributeName];
	}
	
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
