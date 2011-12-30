//
//  DTCoreTextLayoutLine.m
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

@property (nonatomic, strong) NSArray *glyphRuns;
@property (nonatomic, assign) dispatch_semaphore_t layoutLock;

@end

#define SYNCHRONIZE_START(obj) dispatch_semaphore_wait(layoutLock, DISPATCH_TIME_FOREVER);
#define SYNCHRONIZE_END(obj) dispatch_semaphore_signal(layoutLock);


@implementation DTCoreTextLayoutLine
{
	CGRect _frame;
	CTLineRef _line;
	NSAttributedString *_attributedString;
	
	CGPoint _baselineOrigin;
	
	CGFloat ascent;
	CGFloat descent;
	CGFloat leading;
	CGFloat width;
	CGFloat trailingWhitespaceWidth;
	
	NSArray *_glyphRuns;

	BOOL _didCalculateMetrics;
	NSInteger _stringLocationOffset;
}
@synthesize layoutLock;

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame origin:(CGPoint)origin;
{
	if ((self = [super init]))
	{
		_line = line;
		CFRetain(_line);

		NSAttributedString *globalString = [layoutFrame attributedStringFragment];
		_attributedString = [[globalString attributedSubstringFromRange:[self stringRange]] copy];
		
		_baselineOrigin = origin;
		layoutLock = dispatch_semaphore_create(1);
	}
	return self;
}

- (void)dealloc
{
	CFRelease(_line);
	
	dispatch_release(layoutLock);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ origin=%@ frame=%@ %@ '%@'>", [self class], NSStringFromCGPoint(_baselineOrigin), NSStringFromCGRect(self.frame), NSStringFromRange([self stringRange]), [_attributedString string]];
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
				CGFloat ndownShift = neededGlyphHeight - currentGlyphHeight;
				
				if (ndownShift > necessaryDownShift)
				{
					necessaryDownShift = ndownShift;
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
			width = (CGFloat)CTLineGetTypographicBounds(_line, &ascent, &descent, &leading);
			trailingWhitespaceWidth = (CGFloat)CTLineGetTrailingWhitespaceWidth(_line);
			
			_didCalculateMetrics = YES;
		}
	}
	SYNCHRONIZE_END(self);
}

// returns the maximum paragraph spacing for this line
- (CGFloat)paragraphSpacing
{
	// a paragraph spacing only is effective for last line in paragraph
	if (![[_attributedString string] hasSuffix:@"\n"])
	{
		return 0;
	}

	__block CGFloat retSpacing = 0;

	NSRange allRange = NSMakeRange(0, [_attributedString length]);
	[_attributedString enumerateAttribute:(id)kCTParagraphStyleAttributeName inRange:allRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
					   usingBlock:^(id value, NSRange range, BOOL *stop) {
						   CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)value;
						   
						   float paraSpacing;
						   
						   CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paraSpacing), &paraSpacing);
						   
						   retSpacing = MAX(retSpacing, paraSpacing);
					   }];
	
	return retSpacing;
}


// returns the calculated line height
// http://stackoverflow.com/questions/5511830/how-does-line-spacing-work-in-core-text-and-why-is-it-different-from-nslayoutm
- (CGFloat)lineHeight
{
	if (!_didCalculateMetrics)
	{
		[self calculateMetrics];
	}
	
	CGFloat tmpLeading = roundf(MAX(0, leading));
	
	CGFloat lineHeight = roundf(ascent) + roundf(descent) + leading;
	CGFloat ascenderDelta = 0;
	
	if (tmpLeading > 0)
	{
		// we have not see a non-zero leading ever before, oh well ...
		ascenderDelta = 0;
	}
	else
	{
		// magically add an extra 20%
		ascenderDelta = roundf(0.2f * lineHeight);
	}
	
	return lineHeight + ascenderDelta;
}


// calculates the extra space that is before every line even though the leading is zero
- (CGFloat)calculatedLeading
{
	CGFloat maxAscenderDelta = 0;
	
	for (DTCoreTextGlyphRun *oneRun in self.glyphRuns)
	{
		CGFloat tmpLeading = roundf(MAX(0, oneRun.leading));

		if (tmpLeading <= 0)
		{
			// we have not see a non-zero leading ever before, oh well ...
			// for attachments the ascent equals the image height
			// so we don't add the 20%
			if (!oneRun.attachment)
			{
				CGFloat lineHeight = roundf(oneRun.ascent) + roundf(oneRun.descent) + tmpLeading;
				CGFloat ascenderDelta = roundf(0.2f * lineHeight);
				
				if (ascenderDelta > maxAscenderDelta)
				{
					maxAscenderDelta = ascenderDelta;
				}
			}
		}
	}
	
	return maxAscenderDelta;
}

#pragma mark Properties
- (NSArray *)glyphRuns
{
	if (!_glyphRuns)
	{
		CFArrayRef runs = CTLineGetGlyphRuns(_line);
		
		CGFloat offset = 0;
		
		NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(runs)];
		
		for (id oneRun in (__bridge NSArray *)runs)
		{
			//CGPoint runOrigin = CGPointMake(_baselineOrigin.x + offset, _baselineOrigin.y);
			
			DTCoreTextGlyphRun *glyphRun = [[DTCoreTextGlyphRun alloc] initWithRun:(__bridge CTRunRef)oneRun layoutLine:self offset:offset];
			[tmpArray addObject:glyphRun];
			
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
