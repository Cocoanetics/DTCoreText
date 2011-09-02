//
//  DTCoreTextLine.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayouter.h"
#import "DTTextAttachment.h"

@interface DTCoreTextLayoutLine ()

@property (nonatomic, retain) NSArray *glyphRuns;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
@property (nonatomic, assign) dispatch_semaphore_t layoutLock;
#endif

@end

#ifndef __IPHONE_4_3
	#define __IPHONE_4_3 40300
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
#define SYNCHRONIZE_START(obj) dispatch_semaphore_wait(layoutLock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(obj) dispatch_semaphore_signal(layoutLock);
#else
#define SYNCHRONIZE_START(obj) @synchronized(obj)
#define SYNCHRONIZE_END(obj)
#endif

@implementation DTCoreTextLayoutLine

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
@synthesize layoutLock;
#endif

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame origin:(CGPoint)origin;
{
	if ((self = [super init]))
	{
		_layoutFrame = layoutFrame;
		
		_line = line;
		CFRetain(line);
		
		_baselineOrigin = origin;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
		layoutLock = dispatch_semaphore_create(1);
#endif
	}
	return self;
}

- (void)dealloc
{
	if (_line)
	{
		CFRelease(_line);
	}
	[_glyphRuns release];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_3
	dispatch_release(layoutLock);
#endif
	
	[super dealloc];
}

- (NSString *)description
{
	NSString *extract = [[_layoutFrame.layouter.attributedString string] substringFromIndex:[self stringRange].location];
	
	if ([extract length]>20)
	{
		extract = [extract substringToIndex:20];
	}
	
	return [NSString stringWithFormat:@"<%@ '%@'>", [self class], extract];
}

//- (NSString *)description
//{
//	NSRange range = [self stringRange];
//	return [NSString stringWithFormat:@"<%@ loc=%d len=%d %@>", [self class], range.location, range.length, NSStringFromCGRect(_frame)];
//}

- (NSRange)stringRange
{
	CFRange range = CTLineGetStringRange(_line);
	
	return NSMakeRange(range.location, range.length);
}

- (NSInteger)numberOfGlyphs
{
	NSInteger ret = 0;
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		ret += [oneRun numberOfGlyphs];
	}
	
	return ret;
}


#pragma mark Calculations
- (NSArray *)stringIndices {
	NSMutableArray *array = [NSMutableArray array];
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns) {
		[array addObjectsFromArray:[oneRun stringIndices]];
	}
	return array;
}

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		NSInteger count = [oneRun numberOfGlyphs];
		if (index >= count)
		{
			index -= count;
		}
		else 
		{
			return [oneRun frameOfGlyphAtIndex:index];
		}
	}
	
	return CGRectZero;
}

- (NSArray *)glyphRunsWithRange:(NSRange)range
{
	NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[self numberOfGlyphs]];
	
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		NSRange runRange = [oneRun stringRange];
		
		// we only care about locations, assume that number of glyphs >= indexes
		if (NSLocationInRange(runRange.location, range))
		{
			[tmpArray addObject:oneRun];
		}
	}
	
	return tmpArray;
}

- (CGRect)frameOfGlyphsWithRange:(NSRange)range
{
	NSArray *glyphRuns = [self glyphRunsWithRange:range];
	
	CGRect tmpRect = CGRectMake(CGFLOAT_MAX, CGFLOAT_MAX, 0, 0);
	
	for (DTCoreTextGlyphRun *oneRun in glyphRuns)
	{
		CGRect glyphFrame = oneRun.frame;
		
		if (glyphFrame.origin.x < tmpRect.origin.x)
		{
			tmpRect.origin.x = glyphFrame.origin.x;
		}
		
		if (glyphFrame.origin.y < tmpRect.origin.y)
		{
			tmpRect.origin.y = glyphFrame.origin.y;
		}
		
		if (glyphFrame.size.height > tmpRect.size.height)
		{
			tmpRect.size.height = glyphFrame.size.height;
		}
		
		tmpRect.size.width = glyphFrame.origin.x + glyphFrame.size.width - tmpRect.origin.x;
	}
	
	CGFloat maxX = CGRectGetMaxX(self.frame) - trailingWhitespaceWidth;
	if (CGRectGetMaxX(tmpRect) > maxX)
	{
		tmpRect.size.width = maxX - tmpRect.origin.x;
	}
	
	return tmpRect;
}

// bounds of an image encompassing the entire run
- (CGRect)imageBoundsInContext:(CGContextRef)context
{
	return CTLineGetImageBounds(_line, context);
}

- (CGFloat)offsetForStringIndex:(NSInteger)index
{
	return CTLineGetOffsetForStringIndex(_line, index, NULL);
}

- (NSInteger)stringIndexForPosition:(CGPoint)position
{
	// position is in same coordinate system as frame
	CGPoint adjustedPosition = position;
	CGRect frame = self.frame;
	adjustedPosition.x -= frame.origin.x;
	adjustedPosition.y -= frame.origin.y;
	
	NSInteger index = CTLineGetStringIndexForPosition(_line, adjustedPosition);
	
	return index;
}

- (void)drawInContext:(CGContextRef)context
{
	CTLineDraw(_line, context);
}

// fix for image squishing bug < iOS 4.2
- (BOOL)correctAttachmentHeights:(CGFloat *)downShift
{
	// get the glyphRuns with attachments
	NSArray *glyphRuns = [self glyphRuns];
	
	CGFloat necessaryDownShift = 0;
	BOOL didShift = NO;
	
	NSMutableSet *correctedRuns = [[NSMutableSet alloc] init];
	
	
	for (DTCoreTextGlyphRun *oneRun in glyphRuns)
	{
		DTTextAttachment *attachment = oneRun.attachment;
		
		if (attachment)
		{
			CGFloat currentGlyphHeight = oneRun.ascent;
			CGFloat neededGlyphHeight = attachment.displaySize.height;
			
			if (neededGlyphHeight > currentGlyphHeight)
			{
				CGFloat downShift = neededGlyphHeight - currentGlyphHeight;
				
				if (downShift > necessaryDownShift)
				{
					necessaryDownShift = downShift;
					didShift = YES;
					
					[correctedRuns addObject:oneRun];
				}
			}
		}
	}
	
	// now fix the ascent of these runs
	for (DTCoreTextGlyphRun *oneRun in correctedRuns)
	{
		[oneRun fixMetricsFromAttachment];
	}
	
	[correctedRuns release];
	
	// return executed shift
	if (downShift)
	{
		*downShift = necessaryDownShift;
	}
	
	return didShift;
}

- (void)calculateMetrics
{
	// calculate metrics
	SYNCHRONIZE_START(self)
	{
		if (!_didCalculateMetrics)
		{
			width = CTLineGetTypographicBounds(_line, &ascent, &descent, &leading);
			trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(_line);
			
			_didCalculateMetrics = YES;
		}
	}
	SYNCHRONIZE_END(self);
}

#pragma mark Properties
- (NSArray *)glyphRuns
{
	if (!_glyphRuns)
	{
		CFArrayRef runs = CTLineGetGlyphRuns(_line);
		
		CGFloat offset = 0;
		
		NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(runs)];
		
		for (id oneRun in (NSArray *)runs)
		{
			//CGPoint runOrigin = CGPointMake(_baselineOrigin.x + offset, _baselineOrigin.y);
			
			DTCoreTextGlyphRun *glyphRun = [[DTCoreTextGlyphRun alloc] initWithRun:(CTRunRef)oneRun layoutLine:self offset:offset];
			[tmpArray addObject:glyphRun];
			[glyphRun release];
			
			offset += glyphRun.frame.size.width;
		}
		
		_glyphRuns = tmpArray;
	}
	
	return _glyphRuns;
}

- (CGRect)frame
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return CGRectMake(_baselineOrigin.x, _baselineOrigin.y - ascent, width, ascent + descent);
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


@synthesize frame =_frame;
@synthesize glyphRuns = _glyphRuns;

@synthesize ascent;
@synthesize descent;
@synthesize leading;
@synthesize trailingWhitespaceWidth;

@synthesize baselineOrigin = _baselineOrigin;

@end
