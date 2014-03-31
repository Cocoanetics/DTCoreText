//
//  DTHTMLElementHR.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHorizontalRuleHTMLElement.h"

@implementation DTHorizontalRuleHTMLElement

- (NSDictionary *)attributesForAttributedStringRepresentation
{
	NSMutableDictionary *dict = [[super attributesForAttributedStringRepresentation] mutableCopy];
	[dict setObject:[NSNumber numberWithBool:YES] forKey:DTHorizontalRuleStyleAttribute];
	
	return dict;
}

- (NSAttributedString *)attributedString
{
	@synchronized(self)
	{
		NSDictionary *attributes = [self attributesForAttributedStringRepresentation];
		return [[NSAttributedString alloc] initWithString:@"\n" attributes:attributes];
	}
}

@end
