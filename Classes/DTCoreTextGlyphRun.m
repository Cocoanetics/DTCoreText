//
//  DTCoreTextGlyphRun.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutLine.h"
#import "DTTextAttachment.h"

#ifndef __IPHONE_4_3
	#define __IPHONE_4_3 40300
#endif

#define SYNCHRONIZE_START(obj) dispatch_semaphore_wait(runLock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(obj) dispatch_semaphore_signal(runLock);

@interface DTCoreTextGlyphRun ()
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSInteger numberOfGlyphs;
@property (nonatomic, assign) NSDictionary *attributes;
@property (nonatomic, assign) dispatch_semaphore_t runLock;

@end


@implementation DTCoreTextGlyphRun
@synthesize runLock;

- (id)initWithRun:(CTRunRef)run layoutLine:(DTCoreTextLayoutLine *)layoutLine offset:(CGFloat)offset
{
	self = [super init];
	
	if (self)
	{
		_run = run;
		CFRetain(_run);
		
		_offset = offset;
		_line = layoutLine;
		runLock = dispatch_semaphore_create(1);
	}
	
	return self;
}

- (void)dealloc
{
	if (_run)
	{
		CFRelease(_run);
	}
	
	[_attachment release];
	[stringIndices release];

	dispatch_release(runLock);

	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ glyphs=%d %@>", [self class], [self numberOfGlyphs], NSStringFromCGRect(_frame)];
}

#pragma mark Calculations
- (void)calculateMetrics
{
	// calculate metrics
	SYNCHRONIZE_START(self)
	{
		if (!_didCalculateMetrics)
		{
			width = CTRunGetTypographicBounds((CTRunRef)_run, CFRangeMake(0, 0), &ascent, &descent, &leading);
			_didCalculateMetrics = YES;
		}
	}
	SYNCHRONIZE_END(self)
}

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	if (!_didCalculateMetrics) {
		[self calculateMetrics];
	}
	if (!glyphPositionPoints)
	{
		// this is a pointer to the points inside the run, thus no retain necessary
		glyphPositionPoints = CTRunGetPositionsPtr(_run);
	}
	
	if (!glyphPositionPoints || index >= self.numberOfGlyphs)
	{
		return CGRectNull;
	}
	
	CGPoint glyphPosition = glyphPositionPoints[index];
	
	CGRect rect = CGRectMake(_line.baselineOrigin.x + glyphPosition.x, _line.baselineOrigin.y - ascent, _offset + width - glyphPosition.x, ascent + descent);
	if (index < self.numberOfGlyphs-1)
	{
		rect.size.width = glyphPositionPoints[index+1].x - glyphPosition.x;
	}
	
	return rect;
}

// TODO: fix indices if the stringRange is modified
- (NSArray *)stringIndices 
{
	if (!stringIndices) 
	{
		const CFIndex *indices = CTRunGetStringIndicesPtr(_run);
		NSInteger count = self.numberOfGlyphs;
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
		NSInteger i;
		for (i = 0; i < count; i++) 
		{
			[array addObject:[NSNumber numberWithInteger:indices[i]]];
		}
		stringIndices = [array retain];
	}
	return stringIndices;
}

// bounds of an image encompassing the entire run
- (CGRect)imageBoundsInContext:(CGContextRef)context
{
	return CTRunGetImageBounds(_run, context, CFRangeMake(0, 0));
}

// range of the characters from the original string
- (NSRange)stringRange
{
	if (!_stringRange.length)
	{
		CFRange range = CTRunGetStringRange(_run);

		_stringRange = NSMakeRange(range.location, range.length);
	}
	
	return _stringRange;
}

- (void)drawInContext:(CGContextRef)context
{
	if (!_run || !context)
	{
		return;
	}
	
	CTRunDraw(_run, context, CFRangeMake(0, 0));
}

- (void)fixMetricsFromAttachment
{
	if (self.attachment)
	{
		if (!_didCalculateMetrics)
		{
			[self calculateMetrics];
		}
		
		descent = 0;
		ascent = self.attachment.displaySize.height;
	}
}

#pragma mark Properites
- (NSInteger)numberOfGlyphs
{
	if (!numberOfGlyphs)
	{
		numberOfGlyphs = CTRunGetGlyphCount(_run);
	}
	
	return numberOfGlyphs;
}

- (NSDictionary *)attributes
{
	if (!attributes)
	{
		attributes = (NSDictionary *)CTRunGetAttributes(_run);
	}
	
	return attributes;
}

- (DTTextAttachment *)attachment
{
	if (!_attachment)
	{
		if (!_didCheckForAttachmentInAttributes)
		{
			_attachment = [[self.attributes objectForKey:@"DTTextAttachment"] retain];
			
			_didCheckForAttachmentInAttributes = YES;
		}
	}
	
	return _attachment;
}

- (CGRect)frame
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return CGRectMake(_line.baselineOrigin.x + _offset, _line.baselineOrigin.y - ascent, width, ascent + descent);
}

- (CGFloat)width
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return width;
}

- (CGFloat)ascent
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return ascent;
}

- (CGFloat)descent
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return descent;
}

- (CGFloat)leading
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return leading;
}


@synthesize frame = _frame;
@synthesize numberOfGlyphs;
@synthesize attributes;

@synthesize ascent;
@synthesize descent;
@synthesize leading;
@synthesize attachment = _attachment;

@end
