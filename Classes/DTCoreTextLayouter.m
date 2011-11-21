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
@property (nonatomic, assign) dispatch_semaphore_t selfLock;

- (CTFramesetterRef) framesetter;
- (void)discardFramesetter;

@end

#define SYNCHRONIZE_START(obj) dispatch_semaphore_wait(selfLock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(obj) dispatch_semaphore_signal(selfLock);

@implementation DTCoreTextLayouter
@synthesize selfLock;

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
	if ((self = [super init]))
	{
		if (!attributedString)
		{
			[self autorelease];
			return nil;
		}
		
		selfLock = dispatch_semaphore_create(1);
		self.attributedString = attributedString;
	}
	
	return self;
}

- (void)dealloc
{
	[_attributedString release];
	[frames release];
	
	[self discardFramesetter];

	dispatch_release(selfLock);
	
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
	// Note: this returns an unreliable measure prior to 4.2 for very long documents
	CGSize neededSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, CFRangeMake(0, 0), NULL, 
																	 CGSizeMake(width, CGFLOAT_MAX),
																	 NULL);
	return neededSize;
}


// a temporary frame
- (DTCoreTextLayoutFrame *)layoutFrameWithRect:(CGRect)frame range:(NSRange)range
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	DTCoreTextLayoutFrame *newFrame = [[DTCoreTextLayoutFrame alloc] initWithFrame:frame layouter:self range:range];
	[pool release]; pool = NULL;
	return [newFrame autorelease];
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
- (CTFramesetterRef)framesetter
{
	//    if (!framesetter)
	{
		SYNCHRONIZE_START(self)
		{
			if (!framesetter)
			{
				framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
			}
		}
		SYNCHRONIZE_END(self)
	}
	return framesetter;
}


- (void)discardFramesetter
{
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
	SYNCHRONIZE_START(self)
	{
		if (_attributedString != attributedString)
		{
			[_attributedString release];
			
			_attributedString = [attributedString retain];
			
			[self discardFramesetter];
		}
	}
	SYNCHRONIZE_END(self)
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
