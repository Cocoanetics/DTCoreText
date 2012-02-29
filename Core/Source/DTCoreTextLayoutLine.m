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
@property (nonatomic, copy) NSAttributedString *attributedString;

@end

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
	dispatch_queue_t _syncQueue;
}

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame
{
	if ((self = [super init]))
	{
		_line = line;
		CFRetain(_line);

		NSAttributedString *globalString = [layoutFrame attributedStringFragment];
		self.attributedString = [globalString attributedSubstringFromRange:[self stringRange]];
		
		// get a global queue
		_syncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	}
	return self;
}

- (void)dealloc
{
	CFRelease(_line);
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

#pragma mark Creating Variants

- (DTCoreTextLayoutLine *)justifiedLineWithFactor:(CGFloat)justificationFactor justificationWidth:(CGFloat)justificationWidth
{
	// make this line justified
	CTLineRef justifiedLine = CTLineCreateJustifiedLine(_line, justificationFactor, justificationWidth);

	DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:justifiedLine layoutFrame:nil];
	
	// we don't need the layout frame because we directly transfer a copy of the string
	newLine.attributedString = _attributedString;
	
	CFRelease(justifiedLine);
	
	return newLine;
}


#pragma mark Calculations
- (NSArray *)stringIndices 
{
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

- (void)_calculateMetrics
{
	dispatch_sync(_syncQueue, ^{
		if (!_didCalculateMetrics)
		{
			width = (CGFloat)CTLineGetTypographicBounds(_line, &ascent, &descent, &leading);
			trailingWhitespaceWidth = (CGFloat)CTLineGetTrailingWhitespaceWidth(_line);
			
			_didCalculateMetrics = YES;
		}
	});
}

// returns the maximum paragraph spacing for this line
- (CGFloat)paragraphSpacing:(BOOL)zeroNonLast
{
	// a paragraph spacing only is effective for last line in paragraph
	if (![[_attributedString string] hasSuffix:@"\n"] && zeroNonLast)
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

- (CGFloat)paragraphSpacing {
	return [self paragraphSpacing:YES];
}

// gets the line height multiplier used in this line
- (CGFloat)calculatedLineHeightMultiplier
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	// take lineHeightMultiple into account
	NSRange range = NSMakeRange(0, [_attributedString length]);
	__block float lineMultiplier = 1.;
	[_attributedString enumerateAttribute:(id)kCTParagraphStyleAttributeName inRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
							   usingBlock:^(id value, NSRange range, BOOL *stop) {
								   CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)value;
								   								   
								   CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineMultiplier), &lineMultiplier);
																
								   *stop = YES;
							   }];
	

	if (lineMultiplier == 0.) lineMultiplier = 1.;
	return lineMultiplier;
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


// returns line height if it is specified in any paragraph style in this line, zero if not specified
- (CGFloat)calculatedLineHeight
{
	NSRange range = NSMakeRange(0, [_attributedString length]);
	
	__block float lineHeight = 0;
	
	[_attributedString enumerateAttribute:(id)kCTParagraphStyleAttributeName inRange:range options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
							   usingBlock:^(id value, NSRange range, BOOL *stop) {
								   CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)value;
								   
								   CGFloat minimumLineHeight = 0;
								   CGFloat maximumLineHeight = 0;
								   
								   CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minimumLineHeight), &minimumLineHeight);
								   CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maximumLineHeight), &maximumLineHeight);
								   
								   if (lineHeight<minimumLineHeight)
								   {
									   lineHeight = minimumLineHeight;
								   }
								   
								   if (maximumLineHeight>0 && lineHeight>maximumLineHeight)
								   {
									   lineHeight = maximumLineHeight;
								   }
							   }];	
	return lineHeight;
}


- (CGPoint)baselineOriginToPositionAfterLine:(DTCoreTextLayoutLine *)previousLine
{
	CGPoint lineOrigin = previousLine.baselineOrigin;

	CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[_attributedString 
																		attribute:(id)kCTParagraphStyleAttributeName
																		atIndex:0 effectiveRange:NULL];
	
	// get line height in px if it is specified for this line
	CGFloat lineHeight = 0;
	CGFloat minLineHeight = 0;
	CGFloat maxLineHeight = 0;
	
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minLineHeight), &minLineHeight))
	{
		if (lineHeight<minLineHeight)
		{
			lineHeight = minLineHeight;
		}
	}
	
	if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maxLineHeight), &maxLineHeight))
	{
		if (maxLineHeight>0 && lineHeight>maxLineHeight)
		{
			lineHeight = maxLineHeight;
		}
	}
	
	// get the correct baseline origin
	if (lineHeight==0)
	{
		lineHeight = previousLine.descent + self.ascent;
	}
	
	lineHeight += [previousLine paragraphSpacing:YES];
	lineHeight += self.leading;
	
	lineOrigin.y += lineHeight;

	// preserve own baseline x
	lineOrigin.x = _baselineOrigin.x;
	
	return lineOrigin;
}

#pragma mark Properties
- (NSArray *)glyphRuns
{
	if (!_glyphRuns)
	{
		CFArrayRef runs = CTLineGetGlyphRuns(_line);
		
        if (runs) {
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
	}
	
	return _glyphRuns;
}

- (CGRect)frame
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return CGRectMake(_baselineOrigin.x, _baselineOrigin.y - ascent, width, ascent + descent);
}

- (CGFloat)width
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return width;
}

- (CGFloat)ascent
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return ascent;
}

- (CGFloat)descent
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return descent;
}

- (CGFloat)leading
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return leading;
}

- (CGFloat)trailingWhitespaceWidth
{
	if (!_didCalculateMetrics)
	{
		[self _calculateMetrics];
	}
	
	return trailingWhitespaceWidth;
}


@synthesize frame =_frame;
@synthesize glyphRuns = _glyphRuns;

@synthesize ascent;
@synthesize descent;
@synthesize leading;
@synthesize trailingWhitespaceWidth;

@synthesize baselineOrigin = _baselineOrigin;
@synthesize attributedString = _attributedString;

@end
