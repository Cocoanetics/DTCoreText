//
//  NSNumber+RomanNumerals.m
//  DTCoreText
//
//  Created by Kai Maschke on 26.07.16.
//  Copyright © 2016 Drobnik.com. All rights reserved.
//

#import "NSNumber+RomanNumerals.h"

@implementation NSNumber (RomanNumerals)

static NSArray<NSString*> *romanNumerals;
static NSUInteger const romanValues[] = {1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1};
static NSInteger const romanValueCount = 13;

- (NSString *)romanNumeral
{
	if (!romanNumerals) {
		romanNumerals = @[@"M", @"CM", @"D", @"CD", @"C", @"XC", @"L", @"XL", @"X", @"IX", @"V", @"IV", @"I"];
	}
	
	NSInteger n = [self integerValue];
	
	NSMutableString *numeralString = [NSMutableString string];
	
	for (NSUInteger i = 0; i < romanValueCount; i++)
	{
		while (n >= romanValues[i])
		{
			n -= romanValues[i];
			[numeralString appendString:[romanNumerals objectAtIndex:i]];
		}
	}
	
	return numeralString;
}

@end
