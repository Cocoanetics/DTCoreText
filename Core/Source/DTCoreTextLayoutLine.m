//
//  DTCoreTextLayoutLine.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayouter.h"
#import "DTTextAttachment.h"
#import "DTCoreTextConstants.h"
#import <UIKit/UIKit.h>

@interface DTCoreTextLayoutLine ()

@property (nonatomic, strong) NSArray *glyphRuns;

@end

@implementation DTCoreTextLayoutLine
{
	CGRect _frame;
	CTLineRef _line;
	
	CGPoint _baselineOrigin;
	
	CGFloat _ascent;
	CGFloat _descent;
	CGFloat _leading;
	CGFloat _width;
	CGFloat _trailingWhitespaceWidth;
	
	NSArray *_glyphRuns;
	
	BOOL _didCalculateMetrics;
	
	BOOL _writingDirectionIsRightToLeft;
	BOOL _needsToDetectWritingDirection;
}

- (id)initWithLine:(CTLineRef)line
{
	if ((self = [super init]))
	{
		_line = line;
		CFRetain(_line);
		
		// writing direction
		_needsToDetectWritingDirection = YES;
	}
	return self;
}

- (void)dealloc
{
	CFRelease(_line);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ origin=%@ frame=%@ range=%@", [self class], NSStringFromCGPoint(_baselineOrigin), NSStringFromCGRect(self.frame), NSStringFromRange([self stringRange])];
}

- (NSRange)stringRange
{
	CFRange range = CTLineGetStringRange(_line);
	
	// add offset if there is one, i.e. from merged lines
	range.location += _stringLocationOffset;
	
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

#pragma mark - Drawing

- (void)drawInContext:(CGContextRef)context
{
	CTLineDraw(_line, context);
}

- (CGPathRef)newPathWithGlyphs
{
	// mutable path for the line
	CGMutablePathRef mutablePath = CGPathCreateMutable();
	
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		CGPathRef glyphPath = [oneRun newPathWithGlyphs];
		
		CGAffineTransform posTransform = CGAffineTransformMakeTranslation(_baselineOrigin.x, _baselineOrigin.y);
		CGPathAddPath(mutablePath, &posTransform, glyphPath);
		
		CGPathRelease(glyphPath);
	}
	
	return mutablePath;
}

#pragma mark - Creating Variants

- (DTCoreTextLayoutLine *)justifiedLineWithFactor:(CGFloat)justificationFactor justificationWidth:(CGFloat)justificationWidth
{
	// make this line justified
	CTLineRef justifiedLine = CTLineCreateJustifiedLine(_line, justificationFactor, justificationWidth);
	
	DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:justifiedLine];
	
	CFRelease(justifiedLine);
	
	return newLine;
}


#pragma mark - Calculations
- (NSArray *)stringIndices
{
	NSMutableArray *array = [NSMutableArray array];
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
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
		
		// intersect these ranges
		NSRange intersectionRange = NSIntersectionRange(range, runRange);
		
		// if intersection is longer than zero length they intersect
		if (intersectionRange.length)
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
	
	CGFloat maxX = CGRectGetMaxX(self.frame) - _trailingWhitespaceWidth;
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
	// subtract offset if there is one, i.e. from merged lines
	index -= _stringLocationOffset;
	
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
	
	// add offset if there is one, i.e. from merged lines
	index += _stringLocationOffset;
	
	return index;
}

- (void)_calculateMetrics
{
	@synchronized(self)
	{
		if (!_didCalculateMetrics)
		{
			_width = (CGFloat)CTLineGetTypographicBounds(_line, &_ascent, &_descent, &_leading);
			_trailingWhitespaceWidth = (CGFloat)CTLineGetTrailingWhitespaceWidth(_line);
			
			_didCalculateMetrics = YES;
		}
	}
}

// calculates the extra space that is before every line even though the leading is zero
// http://stackoverflow.com/questions/5511830/how-does-line-spacing-work-in-core-text-and-why-is-it-different-from-nslayoutm
- (CGFloat)calculatedLeading
{
	CGFloat maxLeading = 0;
	
	NSArray *glyphRuns = self.glyphRuns;
	DTCoreTextGlyphRun *lastRunInLine = [glyphRuns lastObject];
	
	for (DTCoreTextGlyphRun *oneRun in glyphRuns)
	{
		CGFloat runLeading = 0;
		
		if (oneRun.leading>0)
		{
			// take actual leading
			runLeading = oneRun.leading;
		}
		else
		{
			// calculate a run leading as 20% from line height
			
			// for attachments the ascent equals the image height
			// so we don't add the 20%
			if (!oneRun.attachment)
			{
				if (oneRun == lastRunInLine && (oneRun.width==self.trailingWhitespaceWidth))
				{
					// a whitespace glyph, e.g. \n
				}
				else
				{
					// calculate a leading as 20% of the line height
					CGFloat lineHeight = roundf(oneRun.ascent) + roundf(oneRun.descent);
					runLeading = roundf(0.2f * lineHeight);
				}
			}
		}
		
		// remember the max
		maxLeading = MAX(maxLeading, runLeading);
	}
	
	return maxLeading;
}


- (BOOL)isHorizontalRule
{
	// HR is only a single \n
	
	if (self.stringRange.length>1)
	{
		return NO;
	}
	
	NSArray *runs = self.glyphRuns;
	
	// thus only a single glyphRun
	
	if ([runs count]>1)
	{
		return NO;
	}
	
	DTCoreTextGlyphRun *singleRun = [runs lastObject];
	
	if ([singleRun.attributes objectForKey:DTHorizontalRuleStyleAttribute])
	{
		return YES;
	}
	
	return NO;
}

#pragma mark - Properties
- (NSArray *)glyphRuns
{
	@synchronized(self)
	{
		if (!_glyphRuns)
		{
			// run array is owned by line
			CFArrayRef runs = CTLineGetGlyphRuns(_line);
			CFIndex runCount = CFArrayGetCount(runs);
			
			if (runCount)
			{
				NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:runCount];

				for (CFIndex i=0; i<runCount; i++)
				{
					CTRunRef oneRun = CFArrayGetValueAtIndex(runs, i);
					
					// assumption: position of first glyph is also the correct offset of the entire run
					CGPoint position = *CTRunGetPositionsPtr(oneRun);
					
					DTCoreTextGlyphRun *glyphRun = [[DTCoreTextGlyphRun alloc] initWithRun:oneRun layoutLine:self offset:position.x];
					[tmpArray addObject:glyphRun];
				}
				
				_glyphRuns = tmpArray;
			}
		}
		
		return _glyphRuns;
	}
}

- (CGRect)frame
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	CGRect frame = CGRectMake(_baselineOrigin.x, _baselineOrigin.y - _ascent, _width, _ascent + _descent);
	
	// make sure that HR are extremely wide to be be picked up
	if ([self isHorizontalRule])
	{
		frame.size.width = CGFLOAT_MAX;
	}
	
	return frame;
}

- (CGFloat)width
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _width;
}

- (CGFloat)ascent
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _ascent;
}

- (void)setAscent:(CGFloat)ascent
{
	// need to get metrics because otherwise ascent gets overwritten
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	_ascent = ascent;
}


- (CGFloat)descent
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _descent;
}

- (CGFloat)leading
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _leading;
}

- (CGFloat)trailingWhitespaceWidth
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return _trailingWhitespaceWidth;
}

- (BOOL)writingDirectionIsRightToLeft
{
	if (_needsToDetectWritingDirection)
	{
		if ([self.glyphRuns count])
		{
			DTCoreTextGlyphRun *firstRun = [self.glyphRuns objectAtIndex:0];
			
			_writingDirectionIsRightToLeft = [firstRun writingDirectionIsRightToLeft];
		}
	}
	
	return _writingDirectionIsRightToLeft;
}

- (void)setWritingDirectionIsRightToLeft:(BOOL)writingDirectionIsRightToLeft
{
	_writingDirectionIsRightToLeft = writingDirectionIsRightToLeft;
	_needsToDetectWritingDirection = NO;
}

@synthesize frame =_frame;
@synthesize glyphRuns = _glyphRuns;

@synthesize ascent = _ascent;
@synthesize descent = _descent;
@synthesize leading = _leading;
@synthesize trailingWhitespaceWidth = _trailingWhitespaceWidth;

@synthesize baselineOrigin = _baselineOrigin;
@synthesize writingDirectionIsRightToLeft = _writingDirectionIsRightToLeft;

@end
