//
//  DTCoreTextLayoutFrame.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayouter.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"

#import "DTTextAttachment.h"
#import "UIDevice+DTVersion.h"

#import "NSString+Paragraphs.h"

// global flag that shows debug frames
static BOOL _DTCoreTextLayoutFramesShouldDrawDebugFrames = NO;


@implementation DTCoreTextLayoutFrame
{
	CGRect _frame;
	CTFrameRef _textFrame;
    CTFramesetterRef _framesetter;
    
	NSArray *_lines;
	NSArray *_paragraphRanges;
	
    NSInteger tag;
	
	NSArray *_textAttachments;
	NSAttributedString *_attributedStringFragment;
}

+ (void)setShouldDrawDebugFrames:(BOOL)debugFrames
{
	_DTCoreTextLayoutFramesShouldDrawDebugFrames = debugFrames;
}

// makes a frame for a specific part of the attributed string of the layouter
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter range:(NSRange)range
{
	self = [super init];
	if (self)
	{
		_frame = frame;
		
		_attributedStringFragment = [layouter.attributedString mutableCopy];
		
		CFRange cfRange = CFRangeMake(range.location, range.length);
		_framesetter = layouter.framesetter;
		
		if (_framesetter)
		{
			CFRetain(_framesetter);
			
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathAddRect(path, NULL, frame);
			
			_textFrame = CTFramesetterCreateFrame(_framesetter, cfRange, path, NULL);
			
			CGPathRelease(path);
		}
		else
		{
			// Strange, should have gotten a valid framesetter
			return nil;
		}
		
	}
	
	return self;
}

// makes a frame for the entire attributed string of the layouter
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter
{
	return [self initWithFrame:frame layouter:layouter range:NSMakeRange(0, 0)];
}

- (void)dealloc
{
	if (_textFrame)
	{
		CFRelease(_textFrame);
	}

	if (_framesetter)
	{
		CFRelease(_framesetter);
	}
}

- (NSString *)description
{
	return [self.lines description];
}

- (void)buildLines
{
	// get lines (don't own it so no release)
	CFArrayRef cflines = CTFrameGetLines(_textFrame);
	
	if (!cflines)
	{
		// probably no string set
		return;
	}
	
	CGPoint *origins = malloc(sizeof(CGPoint)*CFArrayGetCount(cflines));
	CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), origins);
	
	NSMutableArray *tmpLines = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(cflines)];
	
	NSInteger lineIndex = 0;
	
	for (id oneLine in (__bridge NSArray *)cflines)
	{
		CGPoint lineOrigin = origins[lineIndex];
		
		lineOrigin.y = _frame.size.height - lineOrigin.y + _frame.origin.y;
		lineOrigin.x += _frame.origin.x;
		
		DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:(__bridge CTLineRef)oneLine layoutFrame:self origin:lineOrigin];
		
		[tmpLines addObject:newLine];
		
		lineIndex++;
	}
	free(origins);

	_lines = tmpLines;

	// line origins are wrong on last line of paragraphs
	[self correctLineOrigins];
	
	
	// --- begin workaround for image squishing bug in iOS < 4.2
	DTVersion version = [[UIDevice currentDevice] osVersion];
	
	if (version.major<4 || (version.major==4 && version.minor < 2))
	{
		[self correctAttachmentHeights];
	}
	
	// at this point we can correct the frame if it is open-ended
	if ([_lines count] && _frame.size.height == CGFLOAT_OPEN_HEIGHT)
	{
		// actual frame is spanned between first and last lines
		DTCoreTextLayoutLine *lastLine = [_lines lastObject];
		
		_frame.size.height = ceilf((CGRectGetMaxY(lastLine.frame) - _frame.origin.y + 1.5f));
	}
}

- (NSArray *)lines
{
	if (!_lines)
	{
		[self buildLines];
	}
	
	return _lines;
}

- (NSArray *)linesVisibleInRect:(CGRect)rect
{
	NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[self.lines count]];
	
	BOOL earlyBreakPossible = NO;
	
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
        CGRect lineFrame = oneLine.frame;
        // CGRectIntersectsRect returns false if the frame has 0 width, which
        // lines that consist only of line-breaks have. Set the min-width
        // to one to work-around.
        lineFrame.size.width = lineFrame.size.width>1?lineFrame.size.width:1;
		if (CGRectIntersectsRect(rect, lineFrame))
		{
			[tmpArray addObject:oneLine];
			earlyBreakPossible = YES;
		}
		else
		{
			if (earlyBreakPossible)
			{
				break;
			}
		}
	}
	
	return tmpArray;
}

#if 0 // appears to be unused
- (NSArray *)linesContainedInRect:(CGRect)rect
{
	NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[self.lines count]];
	
	BOOL earlyBreakPossible = NO;
	
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		if (CGRectContainsRect(rect, oneLine.frame))
		{
			[tmpArray addObject:oneLine];
			earlyBreakPossible = YES;
		}
		else
		{
			if (earlyBreakPossible)
			{
				break;
			}
		}
	}
	
	return tmpArray;
}
#endif

- (CGPathRef)path
{
	return CTFrameGetPath(_textFrame);
}

- (void)setShadowInContext:(CGContextRef)context fromDictionary:(NSDictionary *)dictionary
{
	UIColor *color = [dictionary objectForKey:@"Color"];
	CGSize offset = [[dictionary objectForKey:@"Offset"] CGSizeValue];
	CGFloat blur = [[dictionary objectForKey:@"Blur"] floatValue];
	
	CGFloat scaleFactor = 1.0;
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
	{
		scaleFactor = [[UIScreen mainScreen] scale];
	}
	
	
	// workaround for scale 1: strangely offset (1,1) with blur 0 does not draw any shadow, (1.01,1.01) does
	if (scaleFactor==1.0)
	{
		if (fabs(offset.width)==1.0)
		{
			offset.width *= 1.50;
		}
		
		if (fabs(offset.height)==1.0)
		{
			offset.height *= 1.50;
		}
	}
	
	CGContextSetShadowWithColor(context, offset, blur, color.CGColor);
}

- (void)drawInContext:(CGContextRef)context drawImages:(BOOL)drawImages
{
	CGContextSaveGState(context);
	
	CGRect rect = CGContextGetClipBoundingBox(context);
	
	if (!context)
	{
		return;
	}
	
	if (_textFrame)
	{
		CFRetain(_textFrame);
	}
	
	
	if (_DTCoreTextLayoutFramesShouldDrawDebugFrames)
	{
		// stroke the frame because the layout frame might be open ended
		CGContextSaveGState(context);
		CGFloat dashes[] = {10.0, 2.0};
		CGContextSetLineDash(context, 0, dashes, 2);
		CGContextStrokeRect(context, self.frame);
		CGContextRestoreGState(context);
	}
	
	NSArray *visibleLines = [self linesVisibleInRect:rect];
	
	
	for (DTCoreTextLayoutLine *oneLine in visibleLines)
	{
		if (_DTCoreTextLayoutFramesShouldDrawDebugFrames)
		{
			// draw line bounds
			CGContextSetRGBStrokeColor(context, 0, 0, 1.0f, 1.0f);
			CGContextStrokeRect(context, oneLine.frame);
			
			// draw baseline
			CGContextMoveToPoint(context, oneLine.baselineOrigin.x-5.0f, oneLine.baselineOrigin.y);
			CGContextAddLineToPoint(context, oneLine.baselineOrigin.x + oneLine.frame.size.width + 5.0f, oneLine.baselineOrigin.y);
			CGContextStrokePath(context);
		}
		
		NSInteger runIndex = 0;
		
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			if (_DTCoreTextLayoutFramesShouldDrawDebugFrames)
			{
				if (runIndex%2)
				{
					CGContextSetRGBFillColor(context, 1, 0, 0, 0.2f);
				}
				else 
				{
					CGContextSetRGBFillColor(context, 0, 1, 0, 0.2f);
				}
				
				CGContextFillRect(context, oneRun.frame);
				runIndex ++;
			}
			
			
			CGColorRef backgroundColor = (__bridge CGColorRef)[oneRun.attributes objectForKey:@"DTBackgroundColor"];
			
			
			NSDictionary *ruleStyle = [oneRun.attributes objectForKey:@"DTHorizontalRuleStyle"];
			
			if (ruleStyle)
			{
				if (backgroundColor)
				{
					CGContextSetStrokeColorWithColor(context, backgroundColor);
				}
				else
				{
					CGContextSetGrayStrokeColor(context, 0, 1.0f);
				}
				
				CGRect nrect = self.frame;
				nrect.origin = oneLine.frame.origin;
				nrect.size.height = oneRun.frame.size.height;
				nrect.origin.y = roundf(nrect.origin.y + oneRun.frame.size.height/2.0f)+0.5f;
				
				CGContextMoveToPoint(context, nrect.origin.x, nrect.origin.y);
				CGContextAddLineToPoint(context, nrect.origin.x + nrect.size.width, nrect.origin.y);
				
				CGContextStrokePath(context);
				
				continue;
			}
			
			// don't draw decorations on images
			if (oneRun.attachment)
			{
				continue;
			}
			
			// -------------- Line-Out, Underline, Background-Color
			BOOL lastRunInLine = (oneRun == [oneLine.glyphRuns lastObject]);
			
			BOOL drawStrikeOut = [[oneRun.attributes objectForKey:@"DTStrikeOut"] boolValue];
			BOOL drawUnderline = [[oneRun.attributes objectForKey:(id)kCTUnderlineStyleAttributeName] boolValue];
			
			if (drawStrikeOut||drawUnderline||backgroundColor)
			{
				// get text color or use black
				id color = [oneRun.attributes objectForKey:(id)kCTForegroundColorAttributeName];
				
				if (color)
				{
					CGContextSetStrokeColorWithColor(context, (__bridge CGColorRef)color);
				}
				else
				{
					CGContextSetGrayStrokeColor(context, 0, 1.0);
				}
				
				CGRect runStrokeBounds = oneRun.frame;
				
				NSInteger superscriptStyle = [[oneRun.attributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];
				
				switch (superscriptStyle) 
				{
					case 1:
					{
						runStrokeBounds.origin.y -= oneRun.ascent * 0.47f;
						break;
					}	
					case -1:
					{
						runStrokeBounds.origin.y += oneRun.ascent * 0.25f;
						break;
					}	
					default:
						break;
				}
				
				
				if (lastRunInLine)
				{
					runStrokeBounds.size.width -= [oneLine trailingWhitespaceWidth];
				}
				
				if (backgroundColor)
				{
					CGContextSetFillColorWithColor(context, backgroundColor);
					CGContextFillRect(context, runStrokeBounds);
				}
				
				if (drawStrikeOut)
				{
					runStrokeBounds.origin.y = roundf(runStrokeBounds.origin.y + oneRun.frame.size.height/2.0f + 1)+0.5f;
					
					CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
					CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
					
					CGContextStrokePath(context);
				}
				
				if (drawUnderline)
				{
					runStrokeBounds.origin.y = roundf(runStrokeBounds.origin.y + oneRun.frame.size.height - oneRun.descent + 1)+0.5f;
					
					CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
					CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
					
					CGContextStrokePath(context);
				}
			}
		}
	}
	
	// Flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextTranslateCTM(context, 0, -self.frame.size.height);
	
	// instead of using the convenience method to draw the entire frame, we draw individual glyph runs
	
	for (DTCoreTextLayoutLine *oneLine in visibleLines)
	{
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			CGPoint textPosition = CGPointMake(oneLine.frame.origin.x, self.frame.size.height - oneRun.frame.origin.y - oneRun.ascent);
			
			NSInteger superscriptStyle = [[oneRun.attributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];
			
			switch (superscriptStyle) 
			{
				case 1:
				{
					textPosition.y += oneRun.ascent * 0.47f;
					break;
				}	
				case -1:
				{
					textPosition.y -= oneRun.ascent * 0.25f;
					break;
				}	
				default:
					break;
			}
			
			CGContextSetTextPosition(context, textPosition.x, textPosition.y);
			
			NSArray *shadows = [oneRun.attributes objectForKey:@"DTShadows"];
			
			if (shadows)
			{
				CGContextSaveGState(context);
				
				for (NSDictionary *shadowDict in shadows)
				{
					[self setShadowInContext:context fromDictionary:shadowDict];
					
					// draw once per shadow
					[oneRun drawInContext:context];
				}
				
				CGContextRestoreGState(context);
			}
			else
			{
				DTTextAttachment *attachment = oneRun.attachment;
				
				if (attachment)
				{
					if (drawImages)
					{
						if (attachment.contentType == DTTextAttachmentTypeImage)
						{
							UIImage *image = (id)attachment.contents;
							
							CGPoint origin = oneRun.frame.origin;
							origin.y = self.frame.size.height - origin.y - oneRun.ascent;
							CGRect flippedRect = CGRectMake(roundf(origin.x), roundf(origin.y), attachment.displaySize.width, attachment.displaySize.height);
							
							CGContextDrawImage(context, flippedRect, image.CGImage);
						}
					}
				}
				else
				{
					// regular text
					[oneRun drawInContext:context];
				}
			}
		}
	}
	
	
	if (_textFrame)
	{
		CFRelease(_textFrame);
	}
	
	CGContextRestoreGState(context);
}

// assume we want to draw images statically
- (void)drawInContext:(CGContextRef)context
{
	[self drawInContext:context drawImages:YES];
}


- (NSRange)visibleStringRange
{
	if (!_textFrame)
	{
		return NSMakeRange(0, 0);
	}
	
	CFRange range = CTFrameGetVisibleStringRange(_textFrame);
	
	return NSMakeRange(range.location, range.length);
}

- (NSArray *)textAttachments
{
	if (!_textAttachments)
	{
		NSMutableArray *tmpAttachments = [NSMutableArray array];
		
		for (DTCoreTextLayoutLine *oneLine in self.lines)
		{
			for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
			{
				DTTextAttachment *attachment = [oneRun attachment];
				
				if (attachment)
				{
					[tmpAttachments addObject:attachment];
				}
			}
		}
		
		_textAttachments = [[NSArray alloc] initWithArray:tmpAttachments];
	}

	
	return _textAttachments;
}

- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate
{
	return [[self textAttachments] filteredArrayUsingPredicate:predicate];
}

#pragma mark Calculations
- (NSArray *)stringIndices {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.lines count]];
	for (DTCoreTextLayoutLine *oneLine in self.lines) {
		[array addObjectsFromArray:[oneLine stringIndices]];
	}
	return array;
}

- (NSInteger)lineIndexForGlyphIndex:(NSInteger)index
{
	NSInteger retIndex = 0;
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		NSInteger count = [oneLine numberOfGlyphs];
		if (index >= count)
		{
			index -= count;
		}
		else 
		{
			return retIndex;
		}
		
		retIndex++;
	}
	
	return retIndex;
}

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		NSInteger count = [oneLine numberOfGlyphs];
		if (index >= count)
		{
			index -= count;
		}
		else 
		{
			return [oneLine frameOfGlyphAtIndex:index];
		}
	}
	
	return CGRectNull;
}

- (CGRect)frame
{
	if (_frame.size.height == CGFLOAT_OPEN_HEIGHT && !_lines)
	{
		[self buildLines]; // corrects frame if open-ended
	}
	
	if (![self.lines count])
	{
		return CGRectZero;
	}
	
	return _frame;
	//	
	//    // actual frame is spanned between first and last lines
	//    DTCoreTextLayoutLine *firstLine = [self.lines objectAtIndex:0];
	//    DTCoreTextLayoutLine *lastLine = [self.lines lastObject];
	//    
	//    CGPoint origin = CGPointMake(roundf(firstLine.frame.origin.x), roundf(firstLine.frame.origin.y));
	//    CGSize size = CGSizeMake(_frame.size.width, roundf(CGRectGetMaxY(lastLine.frame) - firstLine.frame.origin.y + 1));
	//    
	//    return (CGRect){origin, size};
}

- (DTCoreTextLayoutLine *)lineContainingIndex:(NSUInteger)index
{
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		if (NSLocationInRange(index, [oneLine stringRange]))
		{
			return oneLine;
		}
	}
	
	return nil;
}

#if 0 // apparently unused
- (NSArray *)linesInParagraphAtIndex:(NSUInteger)index
{
	NSArray *paragraphRanges = self.paragraphRanges;
	
	NSAssert(index < [paragraphRanges count], @"index parameter out of range");
	
	NSRange range = [[paragraphRanges objectAtIndex:index] rangeValue];
	
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	// find lines that are in this range
	
	BOOL insideParagraph = NO;
	
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		if (NSLocationInRange([oneLine stringRange].location, range))
		{
			insideParagraph = YES;
			[tmpArray addObject:oneLine];
		}
		else
		{
			if (insideParagraph)
			{
				// that means we left the range
				
				break;
			}
		}
	}
	
	// return array only if there is something in it
	if ([tmpArray count])
	{
		return tmpArray;
	}
	else
	{
		return nil;
	}
}
#endif

#pragma mark Paragraphs
- (NSUInteger)paragraphIndexContainingStringIndex:(NSUInteger)stringIndex
{
	for (NSValue *oneValue in self.paragraphRanges)
	{
		NSRange range = [oneValue rangeValue];
		
		if (NSLocationInRange(stringIndex, range))
		{
			return [self.paragraphRanges indexOfObject:oneValue];
		}
	}
	
	return NSNotFound;
}

- (NSRange)paragraphRangeContainingStringRange:(NSRange)stringRange
{
	NSUInteger firstParagraphIndex = [self paragraphIndexContainingStringIndex:stringRange.location];
	NSUInteger lastParagraphIndex;
	
	if (stringRange.length)
	{
		lastParagraphIndex = [self paragraphIndexContainingStringIndex:NSMaxRange(stringRange)-1];
	}
	else
	{
		// range is in a single position, i.e. last paragraph has to be same as first
		lastParagraphIndex = firstParagraphIndex;
	}
	
	return NSMakeRange(firstParagraphIndex, lastParagraphIndex - firstParagraphIndex + 1);
}

#pragma mark Corrections
- (void)correctAttachmentHeights
{
	CGFloat downShiftSoFar = 0;
	
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		CGFloat lineShift = 0;
		if ([oneLine correctAttachmentHeights:&lineShift])
		{
			downShiftSoFar += lineShift;
		}
		
		if (downShiftSoFar>0)
		{
			// shift the frame baseline down for the total shift so far
			CGPoint origin = oneLine.baselineOrigin;
			origin.y += downShiftSoFar;
			oneLine.baselineOrigin = origin;
			
			// increase the ascent by the extend needed for this lines attachments
			oneLine.ascent += lineShift;
		}
	}
}


// a bug in CoreText shifts the last line of paragraphs slightly down
- (void)correctLineOrigins
{
	DTCoreTextLayoutLine *previousLine = nil;
	
	CGPoint previousLineOrigin = CGPointZero;

	if (![self.lines count])
	{
		return;
	}
	
	previousLineOrigin = [[self.lines objectAtIndex:0] baselineOrigin];
	
	for (DTCoreTextLayoutLine *currentLine in self.lines)
	{
		CGPoint currentOrigin;
		
		if (previousLine)
		{
			currentOrigin.y = previousLineOrigin.y + previousLine.descent + currentLine.ascent + currentLine.leading + [previousLine paragraphSpacing];
			
			currentOrigin.x = currentLine.baselineOrigin.x;
			
			previousLineOrigin = currentOrigin;
			
			currentOrigin.y = roundf(currentOrigin.y);
			//	origin.x = roundf(origin.x);
			
			currentLine.baselineOrigin = currentOrigin;
		}
		
		previousLine = currentLine;
	}
}

#pragma mark Properties
- (NSAttributedString *)attributedStringFragment
{
	return _attributedStringFragment;
}

// builds an array 
- (NSArray *)paragraphRanges
{
	if (!_paragraphRanges)
	{
		NSString *plainString = [[self attributedStringFragment] string];
		
		NSArray *paragraphs = [plainString componentsSeparatedByString:@"\n"];
		NSRange range = NSMakeRange(0, 0);
		NSMutableArray *tmpArray = [NSMutableArray array];
		
		for (NSString *oneString in paragraphs)
		{
			range.length = [oneString length]+1;
			
			NSValue *value = [NSValue valueWithRange:range];
			[tmpArray addObject:value];
			
			range.location += range.length;
		}
		
		// prevent counting a paragraph after a final newline
		if ([plainString hasSuffix:@"\n"])
		{
			[tmpArray removeLastObject];
		}
		
		_paragraphRanges = [tmpArray copy];
	}
	
	return _paragraphRanges;
}

@synthesize frame = _frame;
@synthesize lines = _lines;
@synthesize paragraphRanges = _paragraphRanges;
@synthesize tag;

@end
