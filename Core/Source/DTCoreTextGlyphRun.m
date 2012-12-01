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
#import "DTCoreTextConstants.h"

#ifndef __IPHONE_4_3
	#define __IPHONE_4_3 40300
#endif

#define SYNCHRONIZE_START(obj) dispatch_semaphore_wait(runLock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(obj) dispatch_semaphore_signal(runLock);

@interface DTCoreTextGlyphRun ()
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSInteger numberOfGlyphs;
@property (nonatomic, unsafe_unretained, readwrite) NSDictionary *attributes;
@property (nonatomic, assign) dispatch_semaphore_t runLock;

@end


@implementation DTCoreTextGlyphRun
{
	CTRunRef _run;
	
	CGRect _frame;
	
	CGFloat _offset; // x distance from line origin 
	CGFloat _ascent;
	CGFloat _descent;
	CGFloat _leading;
	CGFloat _width;
	
	NSInteger _numberOfGlyphs;
	
	const CGPoint *_glyphPositionPoints;
	//BOOL needToFreeGlyphPositionPoints;
	
	__unsafe_unretained DTCoreTextLayoutLine *_line;	// retain cycle, since these objects are retained by the _line
	__unsafe_unretained NSDictionary *_attributes;
    NSArray *_stringIndices;
	
	DTTextAttachment *_attachment;
	BOOL _hyperlink;
	
	BOOL _didCheckForAttachmentInAttributes;
	BOOL _didCheckForHyperlinkInAttributes;
	BOOL _didCalculateMetrics;
}

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
	
	dispatch_release(runLock);
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
			_width = (CGFloat)CTRunGetTypographicBounds((CTRunRef)_run, CFRangeMake(0, 0), &_ascent, &_descent, &_leading);
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
	if (!_glyphPositionPoints)
	{
		// this is a pointer to the points inside the run, thus no retain necessary
		_glyphPositionPoints = CTRunGetPositionsPtr(_run);
	}
	
	if (!_glyphPositionPoints || index >= self.numberOfGlyphs)
	{
		return CGRectNull;
	}
	
	CGPoint glyphPosition = _glyphPositionPoints[index];
	
	CGRect rect = CGRectMake(_line.baselineOrigin.x + glyphPosition.x, _line.baselineOrigin.y - _ascent, _offset + _width - glyphPosition.x, _ascent + _descent);
	if (index < self.numberOfGlyphs-1)
	{
		rect.size.width = _glyphPositionPoints[index+1].x - glyphPosition.x;
	}
	
	return rect;
}

// TODO: fix indices if the stringRange is modified
- (NSArray *)stringIndices 
{
	if (!_stringIndices) 
	{
		const CFIndex *indices = CTRunGetStringIndicesPtr(_run);
		NSInteger count = self.numberOfGlyphs;
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
		NSInteger i;
		for (i = 0; i < count; i++) 
		{
			[array addObject:[NSNumber numberWithInteger:indices[i]]];
		}
		_stringIndices = array;
	}
	return _stringIndices;
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
	
	CGAffineTransform textMatrix = CTRunGetTextMatrix(_run);
	
	if (CGAffineTransformIsIdentity(textMatrix))
	{
		CTRunDraw(_run, context, CFRangeMake(0, 0));
	}
	else 
	{
		CGPoint pos = CGContextGetTextPosition(context);
		
		// set tx and ty to current text pos according to docs
		textMatrix.tx = pos.x;
		textMatrix.ty = pos.y;
		
		CGContextSetTextMatrix(context, textMatrix);
		
		CTRunDraw(_run, context, CFRangeMake(0, 0));

		// restore identity
		CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	}
}

- (void)fixMetricsFromAttachment
{
	if (self.attachment)
	{
		if (!_didCalculateMetrics)
		{
			[self calculateMetrics];
		}
		
		_descent = 0;
		_ascent = self.attachment.displaySize.height;
	}
}

#pragma mark Properites
- (NSInteger)numberOfGlyphs
{
	if (!_numberOfGlyphs)
	{
		_numberOfGlyphs = CTRunGetGlyphCount(_run);
	}
	
	return _numberOfGlyphs;
}

- (NSDictionary *)attributes
{
	if (!_attributes)
	{
		_attributes = (__bridge NSDictionary *)CTRunGetAttributes(_run);
	}
	
	return _attributes;
}

- (DTTextAttachment *)attachment
{
	if (!_attachment)
	{
		if (!_didCheckForAttachmentInAttributes)
		{
			_attachment = [self.attributes objectForKey:NSAttachmentAttributeName];
			
			_didCheckForAttachmentInAttributes = YES;
		}
	}
	
	return _attachment;
}

- (BOOL)isHyperlink
{
	if (!_hyperlink)
	{
		if (!_didCheckForHyperlinkInAttributes)
		{
			_hyperlink = [self.attributes objectForKey:DTLinkAttribute]!=nil;
			
			_didCheckForHyperlinkInAttributes = YES;
		}
	}
	
	return _hyperlink;
}

- (CGRect)frame
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return CGRectMake(_line.baselineOrigin.x + _offset, _line.baselineOrigin.y - _ascent, _width, _ascent + _descent);
}

- (CGFloat)width
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return _width;
}

- (CGFloat)ascent
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return _ascent;
}

- (CGFloat)descent
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return _descent;
}

- (CGFloat)leading
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	return _leading;
}

@synthesize frame = _frame;
@synthesize numberOfGlyphs = _numberOfGlyphs;
@synthesize attributes = _attributes;

@synthesize ascent = _ascent;
@synthesize descent = _descent;
@synthesize leading = _leading;
@synthesize attachment = _attachment;

@end
