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

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ padding=%@>", NSStringFromClass([self class]), NSStringFromUIEdgeInsets(_padding)];
}


#pragma mark Properties

@synthesize padding = _padding;
@synthesize backgroundColor = _backgroundColor;

@end
