//
//  DTHTMLElementHR.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHorizontalRuleHTMLElement.h"

@implementation DTHorizontalRuleHTMLElement

- (NSDictionary *)attributesForAttributedStringRepresentationWithContext:(DTHTMLAttributedStringBuilderContext *)context
{
	NSMutableDictionary *dict = [[super attributesForAttributedStringRepresentationWithContext:context] mutableCopy];
	[dict setObject:[NSNumber numberWithBool:YES] forKey:DTHorizontalRuleStyleAttribute];
	
	return dict;
}

- (NSAttributedString *)attributedStringWithContext:(DTHTMLAttributedStringBuilderContext *)context
{
	@synchronized(self)
	{
		NSDictionary *attributes = [self attributesForAttributedStringRepresentationWithContext:context];
		return [[NSAttributedString alloc] initWithString:@"\n" attributes:attributes];
	}
}

@end
