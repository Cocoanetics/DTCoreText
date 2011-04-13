//
//  DTCoreTextGlyphRun.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutLine.h"


@interface DTCoreTextGlyphRun ()

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) NSInteger numberOfGlyphs;
@property (nonatomic, assign) NSDictionary *attributes;

@end



@implementation DTCoreTextGlyphRun


- (id)initWithRun:(CTRunRef)run layoutLine:(DTCoreTextLayoutLine *)layoutLine origin:(CGPoint)origin
{
	self = [super init];
    
	if (self)
	{
    attributes = nil;
		_run = run;
		CFRetain(_run);
		
		_baselineOrigin = origin;	
		_line = layoutLine;
		
		// calculate metrics
		width = CTRunGetTypographicBounds((CTRunRef)_run, CFRangeMake(0, 0), &ascent, &descent, &leading);
		
		_frame = CGRectMake(origin.x, origin.y - ascent, width, ascent + descent);
	}
	
	return self;
}

- (void)dealloc
{
	
	CFRelease(_run);
	
	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ glyphs=%d %@>", [self class], [self numberOfGlyphs], NSStringFromCGRect(_frame)];
}

#pragma mark Calculations
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	if (!glyphPositionPoints)
	{
		glyphPositionPoints = CTRunGetPositionsPtr(_run);
	}
	
	if (index >= self.numberOfGlyphs)
	{
		return CGRectNull;
	}
	
	CGPoint glyphPosition = glyphPositionPoints[index];
	
	CGRect rect = CGRectMake(_line.frame.origin.x + glyphPosition.x, _line.frame.origin.y, 3, _line.frame.size.height);
    
    if (index < self.numberOfGlyphs-1)
    {
        rect.size.width = glyphPositionPoints[index+1].x - glyphPosition.x;
    }
	
	return rect;
}

// bounds of an image encompassing the entire run
- (CGRect)imageBoundsInContext:(CGContextRef)context
{
	return CTRunGetImageBounds(_run, context, CFRangeMake(0, 0));
}

// range of the characters from the original string
- (NSRange)stringRange
{
	CFRange range = CTRunGetStringRange(_run);
	
	return NSMakeRange(range.location, range.length);
}

- (void)drawInContext:(CGContextRef)context
{
	if (!_run || !context)
	{
		return;
	}
	
	CTRunDraw(_run, context, CFRangeMake(0, 0));
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


@synthesize frame = _frame;
@synthesize numberOfGlyphs;
@synthesize attributes;

@synthesize ascent;
@synthesize descent;
@synthesize leading;
@synthesize baselineOrigin = _baselineOrigin;

@end
