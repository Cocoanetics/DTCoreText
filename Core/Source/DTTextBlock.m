//
//  DTTextBlock.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 04.03.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTTextBlock.h"
#import "DTCoreText.h"
#import "NSCoder+DTCompatibility.h"

@implementation DTTextBlock
{
	DTEdgeInsets _padding;
	DTColor *_backgroundColor;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	if (self) {
		_padding = [aDecoder decodeDTEdgeInsetsForKey:@"padding"];
		_backgroundColor = [aDecoder decodeObjectForKey:@"backgroundColor"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeDTEdgeInsets:_padding forKey:@"padding"];
	[aCoder encodeObject:_backgroundColor forKey:@"backgroundColor"];
}

- (NSUInteger)hash
{
	NSUInteger calcHash = 7;
	
	calcHash = calcHash*31 + [_backgroundColor hash];
	calcHash = calcHash*31 + (NSUInteger)_padding.left;
	calcHash = calcHash*31 + (NSUInteger)_padding.top;
	calcHash = calcHash*31 + (NSUInteger)_padding.right;
	calcHash = calcHash*31 + (NSUInteger)_padding.bottom;
	
	return calcHash;
}

- (BOOL)isEqual:(id)object
{
	if (!object)
	{
		return NO;
	}
	
	if (object == self)
	{
		return YES;
	}
	
	if (![object isKindOfClass:[DTTextBlock class]])
	{
		return NO;
	}
	
	DTTextBlock *other = object;
	
	if (_padding.left != other->_padding.left ||
		_padding.top != other->_padding.top ||
		_padding.right != other->_padding.right ||
		_padding.bottom != other->_padding.bottom)
	{
		return NO;
	}
	
	if (other->_backgroundColor == _backgroundColor)
	{
		return YES;
	}
	
	return [other->_backgroundColor isEqual:_backgroundColor];
}

#pragma mark Properties

@synthesize padding = _padding;
@synthesize backgroundColor = _backgroundColor;

@end
