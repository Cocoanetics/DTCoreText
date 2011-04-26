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

@interface DTCoreTextLayoutLine ()

@property (nonatomic, retain) NSArray *glyphRuns;

@end



@implementation DTCoreTextLayoutLine

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame origin:(CGPoint)origin;
{
    self = [super init];
    
	if (self)
	{
		_layoutFrame = layoutFrame;
		
		_line = line;
		CFRetain(line);
		
		_baselineOrigin = origin;
		
		
		width = CTLineGetTypographicBounds(_line, &ascent, &descent, &leading);
		//CGRect lineImageBounds = CTLineGetImageBounds((CTLineRef)oneLine, context);
		
		trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(_line);

		_frame = CGRectMake(_baselineOrigin.x, _baselineOrigin.y - ascent, width, ascent + descent);
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



- (CGRect)frame
{
	return _frame;
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

- (void)drawInContext:(CGContextRef)context
{
    CTLineDraw(_line, context);
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
			CGPoint runOrigin = CGPointMake(_baselineOrigin.x + offset, _baselineOrigin.y);
			
			DTCoreTextGlyphRun *glyphRun = [[DTCoreTextGlyphRun alloc] initWithRun:(CTRunRef)oneRun layoutLine:self origin:runOrigin];
			[tmpArray addObject:glyphRun];
			[glyphRun release];
			
			offset += glyphRun.frame.size.width;
		}
		
		_glyphRuns = tmpArray;//[NSArray arrayWithArray:tmpArray];
	}
	
	return _glyphRuns;
}
	
	


@synthesize frame =_frame;
@synthesize glyphRuns = _glyphRuns;

@synthesize ascent;
@synthesize descent;
@synthesize leading;
@synthesize trailingWhitespaceWidth;

@synthesize baselineOrigin = _baselineOrigin;

@end
