//
//  DTTextBlock.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 04.03.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTTextBlock.h"
#import "DTCoreText.h"

@implementation DTTextBlock
{
	DTEdgeInsets _padding;
	DTColor *_backgroundColor;
}

- (id)initWithCoder: (NSCoder *) coder {
    self = [super init];
    if (self) {
        _backgroundColor = DTColorCreateWithHexString([coder decodeObjectForKey:@"backgroundColor"]);
        _padding = DTEdgeInsetsMake([[coder decodeObjectForKey:@"paddingTop"] floatValue],
                                    [[coder decodeObjectForKey:@"paddingLeft"] floatValue],
                                    [[coder decodeObjectForKey:@"paddingBottom"] floatValue],
                                    [[coder decodeObjectForKey:@"paddingRight"] floatValue]);
    }
    return self;
}

- (void)encodeWithCoder: (NSCoder *) coder {
    [coder encodeObject:DTHexStringFromDTColor(self.backgroundColor) forKey: @"backgroundColor"];
    [coder encodeObject:@(self.padding.top) forKey: @"paddingTop"];
    [coder encodeObject:@(self.padding.right) forKey: @"paddingRight"];
    [coder encodeObject:@(self.padding.bottom) forKey: @"paddingBottom"];
    [coder encodeObject:@(self.padding.left) forKey: @"paddingLeft"];
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
