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

- (CTFramesetterRef) framesetter;

@end




@implementation DTCoreTextLayouter

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if ((self = [super init]))
	{
		if (!attributedString)
		{
			[self autorelease];
			return nil;
		}
		
		self.attributedString = attributedString;
	}
	
	return self;
}

- (void)dealloc
{
	[_attributedString release];
	[frames release];
	
	[self discardFramesetter];
	
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


// a temporary frame
- (DTCoreTextLayoutFrame *)layoutFrameWithRect:(CGRect)frame range:(NSRange)range
{
	DTCoreTextLayoutFrame *newFrame = [[[DTCoreTextLayoutFrame alloc] initWithFrame:frame layouter:self range:range] autorelease];
	return newFrame;
}

// reusable frame
- (void)addTextFrameWithFrame:(CGRect)frame
{
	DTCoreTextLayoutFrame *newFrame = [self layoutFrameWithRect:frame range:NSMakeRange(0, 0)];
	[self.frames addObject:newFrame];
}

- (DTCoreTextLayoutFrame *)layoutFrameAtIndex:(NSInteger)index
{
	return [self.frames objectAtIndex:index];
	
}

#pragma mark Properties
- (CTFramesetterRef) framesetter
{
	//    if (!framesetter)
	{
		@synchronized(self)
		{
			if (!framesetter)
			{
				framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
				
				if (!framesetter)
				{
					NSLog(@"No Framesetter!");
				}
			}
		}
	}
	
	return framesetter;
}


- (void)discardFramesetter
{
	@synchronized(self)
	{
		// framesetter needs to go
		if (framesetter)
		{
			CFRelease(framesetter);
			framesetter = NULL;
		}
	}
}


- (void)setAttributedString:(NSAttributedString *)attributedString
{
	@synchronized(self)
	{
		if (_attributedString != attributedString)
		{
			[_attributedString release];
			
			_attributedString = [attributedString retain];
			
			[self discardFramesetter];
		}
	}
}

- (NSAttributedString *)attributedString
{
	return _attributedString;
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
