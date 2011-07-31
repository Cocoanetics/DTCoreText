//
//  DTRangedAttributes.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 7/31/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTRangedAttribute.h"

@implementation DTRangedAttribute

+ (DTRangedAttribute *)rangedAttribute:(id)key value:(id)value forRange:(NSRange)range;
{
	return [[[DTRangedAttribute alloc] initWithAttribute:key value:value forRange:range] autorelease];
}

- (id)initWithAttribute:(id)key value:(id)value forRange:(NSRange)range;
{
	self = [super init];
	
	if (self)
	{
		_key = [key copy];
		_value = [value retain];
		_range = range;
	}
	
	return self;
}

- (void)dealloc
{
	[_key release];
	[_value release];
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ range=%@ key='%@'>", NSStringFromClass([self class]), NSStringFromRange(_range), _key];
}

#pragma mark Properties
@synthesize range = _range;
@synthesize key = _key;
@synthesize value = _value;

@end
