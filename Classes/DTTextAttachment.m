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

@synthesize size;
@synthesize contents;
@synthesize contentType;

@end
