//
//  NSAttributedString+DTDebug.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "NSAttributedString+DTDebug.h"


@implementation NSAttributedString (DTDebug)

- (void)dumpRangesOfAttribute:(id)attribute
{
	NSMutableString *tmpString = [NSMutableString string];
	
	NSRange entireRange = NSMakeRange(0, [self length]);
	[self enumerateAttribute:attribute inRange:entireRange options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
		NSString *rangeString = [[self string] substringWithRange:range];
		NSString *valueString;
		
		if ([value isKindOfClass:[NSArray class]])
		{
			valueString = [(NSArray *)value componentsJoinedByString:@", "];
		}
		else
		{
			valueString = [value debugDescription];
		}
		
		[tmpString appendFormat:@"%@ %@ '%@'\n", NSStringFromRange(range), valueString, [rangeString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
	}];
	
	printf("%s", [tmpString UTF8String]);
}


@end
