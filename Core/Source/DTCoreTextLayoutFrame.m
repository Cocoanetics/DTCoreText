//
//  DTCoreTextLayoutFrame.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextConstants.h"

#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayouter.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"

#import "DTTextAttachment.h"
#import "UIDevice+DTVersion.h"

#import "NSString+Paragraphs.h"
#import "DTColor+HTML.h"
#import "DTImage+HTML.h"


// global flag that shows debug frames
static BOOL _DTCoreTextLayoutFramesShouldDrawDebugFrames = NO;


// two correction methods used by the deprecated way of layouting to work around Core Text bugs
@interface DTCoreTextLayoutFrame ()

- (void)_correctAttachmentHeights;
- (void)_correctLineOrigins;

@end

@implementation DTCoreTextLayoutFrame
{
	CTFrameRef _textFrame;
    CTFramesetterRef _framesetter;
	
	NSRange _requestedStringRange;
	NSRange _stringRange;
    
    NSInteger tag;
}

// makes a frame for a specific part of the attributed string of the layouter
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter range:(NSRange)range
{
	self = [super init];
	if (self)
	{
		_frame = frame;
		
		_attributedStringFragment = [layouter.attributedString mutableCopy];
		
		// determine correct target range
		_requestedStringRange = range;
		NSUInteger stringLength = [_attributedStringFragment length];
		
		if (_requestedStringRange.location >= stringLength)
		{
			return nil;
		}
		
		if (_requestedStringRange.length==0 || NSMaxRange(_requestedStringRange) > stringLength)
		{
			_requestedStringRange.length = stringLength - _requestedStringRange.location;
		}
		
		CFRange cfRange = CFRangeMake(_requestedStringRange.location, _requestedStringRange.length);
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

#pragma mark Building the Lines
/* 
 Builds the array of lines with the internal typesetter of our framesetter. No need to correct line origins in this case because they are placed correctly in the first place.
 */
- (void)_buildLinesWithTypesetter
{
	// framesetter keeps internal reference, no need to retain
	CTTypesetterRef typesetter = CTFramesetterGetTypesetter(_framesetter);

	NSMutableArray *typesetLines = [NSMutableArray array];
	
	CGPoint lineOrigin = _frame.origin;
	
	DTCoreTextLayoutLine *previousLine = nil;
	
	// need the paragraph ranges to know if a line is at the beginning of paragraph
	NSMutableArray *paragraphRanges = [[self paragraphRanges] mutableCopy];

	NSRange currentParagraphRange = [[paragraphRanges objectAtIndex:0] rangeValue];
	
	// we start out in the requested range, length will be set by the suggested line break function
	NSRange lineRange = _requestedStringRange;
	
	// maximum values for abort of loop
	CGFloat maxY = CGRectGetMaxY(_frame);
	NSUInteger maxIndex = NSMaxRange(_requestedStringRange);
	NSUInteger fittingLength = 0;
	
	typedef struct 
	{
		CGFloat ascent;
		CGFloat descent;
		CGFloat width;
		CGFloat leading;
		CGFloat trailingWhitespaceWidth;
		CGFloat paragraphSpacing;
	} lineMetrics;
	
	lineMetrics currentLineMetrics;
	lineMetrics previousLineMetrics;
	
	do 
	{
		while (lineRange.location >= (currentParagraphRange.location+currentParagraphRange.length)) 
		{
			// we are outside of this paragraph, so we go to the next
			[paragraphRanges removeObjectAtIndex:0];
			
			currentParagraphRange = [[paragraphRanges objectAtIndex:0] rangeValue];
		}
		
		BOOL isAtBeginOfParagraph = (currentParagraphRange.location == lineRange.location);
		
		// get the paragraph style at this index
		CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[_attributedStringFragment attribute:(id)kCTParagraphStyleAttributeName atIndex:lineRange.location effectiveRange:NULL];
		
		CGFloat offset = 0;
		
		if (isAtBeginOfParagraph)
		{
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(offset), &offset);
		}
		else
		{
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(offset), &offset);
		}
		
		lineOrigin.x = offset + _frame.origin.x;
		
		// find how many characters we get into this line
		lineRange.length = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, _frame.size.width - offset);
		
		if (NSMaxRange(lineRange) > maxIndex)
		{
			// only layout as much as was requested
			lineRange.length = maxIndex - lineRange.location;
		}
		
		if (NSMaxRange(lineRange) == NSMaxRange(currentParagraphRange))
		{
			// at end of paragraph, record the spacing
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(currentLineMetrics.paragraphSpacing), &currentLineMetrics.paragraphSpacing);

		}

		// create a line to fit
		CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length));
		
		// we need all metrics so get the at once
		currentLineMetrics.width = CTLineGetTypographicBounds(line, &currentLineMetrics.ascent, &currentLineMetrics.descent, &currentLineMetrics.leading);
		
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
		if (previousLine)
		{
			if (lineHeight==0)
			{
				lineHeight = previousLineMetrics.descent + currentLineMetrics.ascent;
			}
			
			if (isAtBeginOfParagraph)
			{
				lineHeight += previousLineMetrics.paragraphSpacing;
				
//				lineHeight += [previousLine paragraphSpacing:YES];
			}
			lineHeight += currentLineMetrics.leading;
		}
		else 
		{
			if (lineHeight>0)
			{
				if (lineHeight<currentLineMetrics.ascent)
				{
					// special case, we fake it to look like CoreText
					lineHeight -= currentLineMetrics.descent; 
				}
			}
			else 
			{
				lineHeight = currentLineMetrics.ascent;
			}
		}

		lineOrigin.y += lineHeight;
		
		// adjust lineOrigin based on paragraph text alignment
		CTTextAlignment textAlignment;
		CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment);

		
		switch (textAlignment) 
		{
			case kCTLeftTextAlignment:
			{
				lineOrigin.x = _frame.origin.x + offset;
				// nothing to do
				break;
			}
				
			case kCTNaturalTextAlignment:
			{
				// depends on the text direction
				CTWritingDirection baseWritingDirection;
				CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(baseWritingDirection), &baseWritingDirection);
				
				if (baseWritingDirection != kCTWritingDirectionRightToLeft)
				{
					break;
				}
				
				// right alignment falls through
			}
				
			case kCTRightTextAlignment:
			{
				lineOrigin.x = _frame.origin.x + offset + CTLineGetPenOffsetForFlush(line, 1.0, _frame.size.width - offset);

				break;
			}
				
			case kCTCenterTextAlignment:
			{
				lineOrigin.x = _frame.origin.x + offset + CTLineGetPenOffsetForFlush(line, 0.5, _frame.size.width - offset);
				
				break;
			}
				
			case kCTJustifiedTextAlignment:
			{
				// only justify if the line widht is longer than 60% of the frame to avoid over-stretching
				if (currentLineMetrics.width > 0.6 * _frame.size.width)
				{
					// create a justified line and replace the current one with it
					CTLineRef justifiedLine = CTLineCreateJustifiedLine(line, 1.0f, _frame.size.width-offset);
					CFRelease(line);
					line = justifiedLine;
//					
//					newLine = [newLine justifiedLineWithFactor:1.0f justificationWidth:_frame.size.width-offset];
				}
				
				lineOrigin.x = _frame.origin.x + offset;
				
				break;
			}
		}

		CGFloat lineBottom = lineOrigin.y + currentLineMetrics.descent;
		
		// abort layout if we left the configured frame
		if (lineBottom>maxY)
		{
			// doesn't fit any more
			break;
		}

		// wrap it
		DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:line layoutFrame:self];
		CFRelease(line);

		
		newLine.baselineOrigin = lineOrigin;
		
		[typesetLines addObject:newLine];
		fittingLength += lineRange.length;
	
		lineRange.location += lineRange.length;
		
		previousLine = newLine;
		previousLineMetrics = currentLineMetrics;
	} 
	while (lineRange.location < maxIndex);
	
	_lines = typesetLines;
	
	if (![_lines count])
	{
		// no lines fit
		_stringRange = NSMakeRange(0, 0);
		
		return;
	}
	
	// now we know how many characters fit
	_stringRange.location = _requestedStringRange.location;
	_stringRange.length = fittingLength;
	
	// at this point we can correct the frame if it is open-ended
	if (_frame.size.height == CGFLOAT_OPEN_HEIGHT)
	{
		// actual frame is spanned between first and last lines
		DTCoreTextLayoutLine *lastLine = [_lines lastObject];
		
		_frame.size.height = ceilf((CGRectGetMaxY(lastLine.frame) - _frame.origin.y + 1.5f));
	}
}

/**
 DEPRECATED: this was the original way of getting the lines
 */

- (void)_buildLinesWithStandardFramesetter
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
		
		DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:(__bridge CTLineRef)oneLine layoutFrame:self];
		newLine.baselineOrigin = lineOrigin;
		
		[tmpLines addObject:newLine];
		
		lineIndex++;
	}
	free(origins);
	
	_lines = tmpLines;

	// need to get the visible range here
	CFRange fittingRange = CTFrameGetStringRange(_textFrame);
	_stringRange.location = fittingRange.location;
	_stringRange.length = fittingRange.length;
	
	// line origins are wrong on last line of paragraphs
	[self _correctLineOrigins];
	
	// --- begin workaround for image squishing bug in iOS < 4.2
	DTVersion version = [[UIDevice currentDevice] osVersion];
	
	if (version.major<4 || (version.major==4 && version.minor < 2))
	{
		[self _correctAttachmentHeights];
	}
	
	// at this point we can correct the frame if it is open-ended
	if ([_lines count] && _frame.size.height == CGFLOAT_OPEN_HEIGHT)
	{
		// actual frame is spanned between first and last lines
		DTCoreTextLayoutLine *lastLine = [_lines lastObject];
		
		_frame.size.height = ceilf((CGRectGetMaxY(lastLine.frame) - _frame.origin.y + 1.5f));
	}
}

- (void)_buildLines
{
	// only build lines if frame is legal
	if (_frame.size.width<=0)
	{
		return;
	}

	// note: building line by line with typesetter
	[self _buildLinesWithTypesetter];
	
//	[self _buildLinesWithStandardFramesetter];
}

- (NSArray *)lines
{
	if (!_lines)
	{
		[self _buildLines];
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

#pragma mark Drawing

- (void)_setShadowInContext:(CGContextRef)context fromDictionary:(NSDictionary *)dictionary
{
	DTColor *color = [dictionary objectForKey:@"Color"];
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

		// draw center line
		CGContextMoveToPoint(context, CGRectGetMidX(self.frame), self.frame.origin.y);
		CGContextAddLineToPoint(context, CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame));
		CGContextStrokePath(context);
		
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
			
			
			CGColorRef backgroundColor = (__bridge CGColorRef)[oneRun.attributes objectForKey:DTBackgroundColorAttribute];
			
			
			NSDictionary *ruleStyle = [oneRun.attributes objectForKey:DTHorizontalRuleStyleAttribute];
			
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
			
			BOOL drawStrikeOut = [[oneRun.attributes objectForKey:DTStrikeOutAttribute] boolValue];
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
			
			NSArray *shadows = [oneRun.attributes objectForKey:DTShadowsAttribute];
			
			if (shadows)
			{
				CGContextSaveGState(context);
				
				for (NSDictionary *shadowDict in shadows)
				{
					[self _setShadowInContext:context fromDictionary:shadowDict];
					
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
							DTImage *image = (id)attachment.contents;
							
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

#pragma mark Text Attachments

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

- (NSRange)visibleStringRange
{
	if (!_textFrame)
	{
		return NSMakeRange(0, 0);
	}
	
	return _stringRange;
}

- (NSArray *)stringIndices 
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.lines count]];
	
	for (DTCoreTextLayoutLine *oneLine in self.lines) 
	{
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
		[self _buildLines]; // corrects frame if open-ended
	}
	
	if (![self.lines count])
	{
		return CGRectZero;
	}
	
	return _frame;
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

#pragma mark Debugging
+ (void)setShouldDrawDebugFrames:(BOOL)debugFrames
{
	_DTCoreTextLayoutFramesShouldDrawDebugFrames = debugFrames;
}

#pragma mark Corrections
- (void)_correctAttachmentHeights
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
- (void)_correctLineOrigins
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
			CGFloat lineHeightMultiplier = [previousLine calculatedLineHeightMultiplier];
			// TODO: correct spacing between paragraphs with line height multiplier > 1
			
			CGFloat spaceAfterPreviousLine = [previousLine paragraphSpacing:YES]; // already multiplied
			CGFloat lineHeight = previousLine.descent + currentLine.ascent + currentLine.leading;
			
			if (spaceAfterPreviousLine > 0) {
				// last paragraph, don't use line multiplier on current line values, use space specified
				lineHeight += spaceAfterPreviousLine + previousLine.descent * (lineHeightMultiplier-1.);
			} else {
				// apply multiplier
				lineHeight *= lineHeightMultiplier;
			}
						
			// space the current line baseline lineHeight px from previous line
			currentOrigin.y = roundf(previousLineOrigin.y + lineHeight); 
			currentOrigin.x = currentLine.baselineOrigin.x;
			
			currentLine.baselineOrigin = currentOrigin;
			
			previousLineOrigin = currentOrigin;
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
//@synthesize tag;

@end
