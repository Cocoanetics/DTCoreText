//
//  DTHTMLElementBR.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTBreakHTMLElement.h"

@implementation DTBreakHTMLElement

- (NSAttributedString *)attributedStringWithContext:(DTHTMLAttributedStringBuilderContext *)context
{
	@synchronized(self)
	{
		NSDictionary *attributes = [self attributesForAttributedStringRepresentationWithContext:context];
		return [[NSAttributedString alloc] initWithString:UNICODE_LINE_FEED attributes:attributes];
	}
}

@end
