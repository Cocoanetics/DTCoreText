//
//  DTRangedAttributesOptimizer.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 7/31/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTRangedAttributesOptimizer.h"

@implementation DTRangedAttributesOptimizer

- (id)init
{
    self = [super init];
    if (self) {
		_attributes = [[NSMutableArray alloc] init];
		_attributeIndex = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
	[_attributes release];
	[_attributeIndex release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [_attributeIndex description];
}

- (void)addAttribute:(DTRangedAttribute *)attribute
{
	NSMutableArray *keyArray = [_attributeIndex objectForKey:attribute.key];
	if (keyArray)
	{
		DTRangedAttribute *previousAttribute = [keyArray lastObject];

		// if it's identical attribute and continues right after it
		NSInteger lastPreviousIndex = NSMaxRange(previousAttribute.range);
		if (previousAttribute.value == attribute.value && (lastPreviousIndex == attribute.range.location))
		{
			NSRange extendedRange = previousAttribute.range;
			extendedRange.length += attribute.range.length;
			previousAttribute.range = extendedRange;
			
			_didMerge = YES;
			
			return;
		}
	}
	else
	{
		keyArray = [NSMutableArray array];
	}
	
	// below this line this is not an extension of existing attribute

	// store it in all attributes
	[_attributes addObject:attribute];

	// add it to index
	[_attributeIndex setObject:keyArray forKey:(NSString *)attribute.key];
	
	[keyArray addObject:attribute];
}

- (void)addAttributes:(NSDictionary *)attributes range:(NSRange)range
{
	for (id key in [attributes allKeys])
	{
		id value = [attributes objectForKey:key];
		DTRangedAttribute *attribute = [DTRangedAttribute rangedAttribute:key value:value forRange:range];
		
		[self addAttribute:attribute];
	}
}


- (NSArray *)allKeys
{
	return [_attributeIndex allKeys];
}

- (NSArray *)rangedAttributesForKey:(id)key
{
	NSMutableArray *keyArray = [_attributeIndex objectForKey:key];
	
	return keyArray;
}

#pragma mark Properties
@synthesize didMerge = _didMerge;
@end
