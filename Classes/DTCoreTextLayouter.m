//
//  DTCoreTextLayouter.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayouter.h"

@interface DTCoreTextLayouter ()

@property (nonatomic, retain) NSMutableArray *frames;

@property (nonatomic) CTFramesetterRef framesetter;

@end




@implementation DTCoreTextLayouter

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if (!attributedString)
	{
		return nil;
	}
	
	if (self = [super init])
	{
		self.attributedString = attributedString;
	}
	
	return self;
}

- (void)dealloc
{
	[_attributedString release];
	[frames release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [self.frames description];
}

- (NSInteger)numberOfFrames
{
	return [self.frames count];
}

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width
{
	CGSize neededSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, 0), NULL, 
																	 CGSizeMake(width, CGFLOAT_MAX),
																	 NULL);
	
	// for unknown reasons suddenly 1 needs to be added to fit
	neededSize.height = ceilf(neededSize.height)+1.0;
	neededSize.width = width;
	
	return neededSize;
}

- (void)addTextFrameWithFrame:(CGRect)frame
{
	DTCoreTextLayoutFrame *newFrame = [[[DTCoreTextLayoutFrame alloc] initWithFrame:frame layouter:self] autorelease];
	[self.frames addObject:newFrame];
}

- (DTCoreTextLayoutFrame *)layoutFrameAtIndex:(NSInteger)index
{
	return [self.frames objectAtIndex:index];
	
}

#pragma mark Properties
- (CTFramesetterRef) framesetter
{
	if (!framesetter)
	{
		framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);
	}
	
	return framesetter;
}


- (void)relayoutText
{
	// framesetter needs to go
	if (framesetter)
	{
		CFRelease(framesetter);
		framesetter = NULL;
	}
}


- (void)setAttributedString:(NSAttributedString *)string
{
	[_attributedString autorelease];
	
	_attributedString = [string copy];
	
	[self relayoutText];
}

- (NSMutableArray *)frames
{
	if (!frames)
	{
		frames = [[NSMutableArray alloc] init];
	}
	
	return frames;
}



@synthesize attributedString = _attributedString;
@synthesize frames;
@synthesize framesetter;



@end
