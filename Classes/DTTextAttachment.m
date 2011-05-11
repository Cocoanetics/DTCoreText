//
//  DTTextAttachment.m
//  CoreTextExtensions
//
//  Created by Oliver on 14.01.11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTTextAttachment.h"


@implementation DTTextAttachment

- (void) dealloc
{
	[contents release];
	[super dealloc];
}


#pragma mark Properties

- (void)setOriginalSize:(CGSize)originalSize
{
	_originalSize = originalSize;
	self.displaySize = _originalSize;
}

@synthesize originalSize = _originalSize;
@synthesize displaySize = _displaySize;
@synthesize contents;
@synthesize contentType;

@end
