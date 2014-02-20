//
//  DTDictationPlaceholderTextAttachment.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 06.02.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTDictationPlaceholderTextAttachment.h"

@implementation DTDictationPlaceholderTextAttachment
{
	NSAttributedString *_replacedAttributedString;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		_replacedAttributedString = [aDecoder decodeObjectForKey:@"replacedAttributedString"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:_replacedAttributedString forKey:@"replacedAttributedString"];
}

// if you change any of these then also make sure to adjust the sizes in DTDictationPlaceholderTextAttachment
#define DOT_WIDTH 10.0f
#define DOT_DISTANCE 2.5f
#define DOT_OUTSIDE_MARGIN 3.0f

// several hard-coded items
- (CGSize)displaySize
{
    return CGSizeMake(DOT_OUTSIDE_MARGIN*2.0f + DOT_WIDTH*3.0f + DOT_DISTANCE*2.0f, DOT_OUTSIDE_MARGIN*2.0f + DOT_WIDTH);
}

- (CGSize)originalSize
{
	return [self displaySize];
}

- (CGFloat)ascentForLayout
{
	return self.displaySize.height;
}

- (CGFloat)descentForLayout
{
	return 0.0f;
}

#pragma mark - Properties

@synthesize replacedAttributedString = _replacedAttributedString;

@end
