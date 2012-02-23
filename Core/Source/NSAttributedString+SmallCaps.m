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
	CTFontRef normalFont = (__bridge CTFontRef)[attributes objectForKey:(id)kCTFontAttributeName];
	
	DTCoreTextFontDescriptor *smallerFontDesc = [DTCoreTextFontDescriptor fontDescriptorForCTFont:normalFont];
	smallerFontDesc.pointSize *= 0.7;
	CTFontRef smallerFont = [smallerFontDesc newMatchingFont];
	
	NSMutableDictionary *smallAttributes = [attributes mutableCopy];
	[smallAttributes setObject:CFBridgingRelease(smallerFont) forKey:(id)kCTFontAttributeName];
	
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
	
	return 	tmpString;
}

@end
