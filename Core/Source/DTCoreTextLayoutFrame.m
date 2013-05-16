//
//  DTCoreTextLayoutFrame.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"
#import "DTCoreTextLayoutFrame.h"
#import "DTVersion.h"

// global flag that shows debug frames
static BOOL _DTCoreTextLayoutFramesShouldDrawDebugFrames = NO;

@implementation DTCoreTextLayoutFrame
{
	CTFrameRef _textFrame;
	CTFramesetterRef _framesetter;
	
	NSRange _requestedStringRange;
	NSRange _stringRange;
	
	CGFloat _additionalPaddingAtBottom; // when last line in a text block with padding
	
	int _numberLinesFitInFrame;
	DTCoreTextLayoutFrameTextBlockHandler _textBlockHandler;
	
	CGFloat _longestLayoutLineWidth;
}

@synthesize numberOfLines = _numberOfLines;
@synthesize lineBreakMode = _lineBreakMode;
@synthesize truncationString = _truncationString;
@synthesize noLeadingOnFirstLine = _noLeadingOnFirstLine;

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
 Builds the array of lines with the internal typesetter of our framesetter. No need to correct line origins in this case because they are placed correctly in the first place. This version supports text boxes.
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
	} lineMetrics;
	
	typedef struct
	{
		CGFloat paragraphSpacingBefore;
		CGFloat paragraphSpacing;
		CGFloat lineHeightMultiplier;
	} paragraphMetrics;
	
	paragraphMetrics currentParaMetrics = {0,0,0};
	paragraphMetrics previousParaMetrics = {0,0,0};
	
	lineMetrics currentLineMetrics;
	
	DTTextBlock *currentTextBlock = nil;
	DTTextBlock *previousTextBlock = nil;
	BOOL truncateLine;
	
	do 
	{
		while (lineRange.location >= (currentParagraphRange.location+currentParagraphRange.length)) 
		{
			// we are outside of this paragraph, so we go to the next
			[paragraphRanges removeObjectAtIndex:0];
			
			currentParagraphRange = [[paragraphRanges objectAtIndex:0] rangeValue];
		}
		
		BOOL isAtBeginOfParagraph = (currentParagraphRange.location == lineRange.location);
		
		CGFloat headIndent = 0;
		CGFloat tailIndent = 0;
		
		// get the paragraph style at this index
		CTParagraphStyleRef paragraphStyle = (__bridge CTParagraphStyleRef)[_attributedStringFragment attribute:(id)kCTParagraphStyleAttributeName atIndex:lineRange.location effectiveRange:NULL];
		
		currentTextBlock = [[_attributedStringFragment attribute:DTTextBlocksAttribute atIndex:lineRange.location effectiveRange:NULL] lastObject];
		
		if (previousTextBlock != currentTextBlock)
		{
			lineOrigin.y += previousTextBlock.padding.bottom;
			lineOrigin.y += currentTextBlock.padding.top;
			
			previousTextBlock = currentTextBlock;
		}
		
		if (isAtBeginOfParagraph)
		{
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(headIndent), &headIndent);
			
			// save prev paragraph
			previousParaMetrics = currentParaMetrics;
			
			// Save the paragraphSpacingBefore to currentParaMetrics. This should be done after saving previousParaMetrics.
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(currentParaMetrics.paragraphSpacingBefore), &currentParaMetrics.paragraphSpacingBefore);
		}
		else
		{
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(headIndent), &headIndent);
		}
		
		CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierTailIndent, sizeof(tailIndent), &tailIndent);
		
		// add left padding to offset
		lineOrigin.x = _frame.origin.x + headIndent + currentTextBlock.padding.left;
		
		CGFloat availableSpace;
		CGFloat offset = headIndent + currentTextBlock.padding.left;
		
		if (tailIndent<=0)
		{
			// negative tail indent is measured from trailing margin (we assume LTR here)
			availableSpace = _frame.size.width - offset - currentTextBlock.padding.right + tailIndent;
		}
		else
		{
			availableSpace = tailIndent - offset - currentTextBlock.padding.right;
		}
		
		// find how many characters we get into this line
		lineRange.length = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, availableSpace);
		
		if (NSMaxRange(lineRange) > maxIndex)
		{
			// only layout as much as was requested
			lineRange.length = maxIndex - lineRange.location;
		}
		
		if (NSMaxRange(lineRange) == NSMaxRange(currentParagraphRange))
		{
			// at end of paragraph, record the spacing
			CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(currentParaMetrics.paragraphSpacing), &currentParaMetrics.paragraphSpacing);
		}
		
		truncateLine = ((self.numberOfLines>0 && [typesetLines count]+1==self.numberOfLines) ||
						(_numberLinesFitInFrame>0 && _numberLinesFitInFrame==[typesetLines count]+1));
		CTLineRef line;
		if(!truncateLine)
		{
			// create a line to fit
			line = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length));
		}
		else
		{
			// extend the line to the end of the current paragraph
			// if we extend to the entire to the entire text range
			// it is possible to pull lines up from paragraphs below us
			NSRange oldLineRange = lineRange;
			lineRange.length = NSMaxRange(currentParagraphRange)-lineRange.location;
			CTLineRef baseLine = CTTypesetterCreateLine(typesetter, CFRangeMake(lineRange.location, lineRange.length));
			
			// convert lineBreakMode to CoreText type
			CTLineTruncationType truncationType = DTCTLineTruncationTypeFromNSLineBreakMode(self.lineBreakMode);
			
			// prepare truncation string
			NSAttributedString * attribStr = self.truncationString;
			if(attribStr == nil)
			{
				NSRange range;
				int index = oldLineRange.location;
				if (truncationType == kCTLineTruncationEnd)
                {
                    index += (oldLineRange.length > 0 ? oldLineRange.length - 1 : 0);
                }
                else if (truncationType == kCTLineTruncationMiddle)
                {
                    index += (oldLineRange.length > 1 ? (oldLineRange.length/2.0 - 1) : 0);
                }
				NSDictionary * attributes = [_attributedStringFragment attributesAtIndex:index effectiveRange:&range];
				attribStr = [[NSAttributedString alloc] initWithString:@"…" attributes:attributes];
			}
			
			CTLineRef elipsisLineRef = CTLineCreateWithAttributedString((__bridge  CFAttributedStringRef)(attribStr));
			
			// create the truncated line
			line = CTLineCreateTruncatedLine(baseLine, availableSpace, truncationType, elipsisLineRef);
			
			// clean up
			CFRelease(baseLine);
			CFRelease(elipsisLineRef);
		}
		
		// we need all metrics so get the at once
		currentLineMetrics.width = (CGFloat)CTLineGetTypographicBounds(line, &currentLineMetrics.ascent, &currentLineMetrics.descent, &currentLineMetrics.leading);
		
		// get line height in px if it is specified for this line
		CGFloat lineHeight = 0;
		CGFloat minLineHeight = 0;
		CGFloat maxLineHeight = 0;
		
		BOOL usesSyntheticLeading = NO;
		BOOL usesForcedLineHeight = NO;
		
		if (currentLineMetrics.leading == 0.0f)
		{
			// font has no leading, so we fake one (e.g. Helvetica)
			CGFloat tmpHeight = currentLineMetrics.ascent + currentLineMetrics.descent;
			currentLineMetrics.leading = ceilf(0.2f * tmpHeight);
			
			if (currentLineMetrics.leading>20)
			{
				// we have a large image increasing the ascender too much for this calc to work
				currentLineMetrics.leading = 0;
			}
			
			usesSyntheticLeading = YES;
		}
		else
		{
			// make sure that we don't have less than 10% of line height as leading
			currentLineMetrics.leading = ceilf(MAX((currentLineMetrics.ascent + currentLineMetrics.descent)*0.1f, currentLineMetrics.leading));
		}
		
		if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minLineHeight), &minLineHeight))
		{
			if (lineHeight<minLineHeight)
			{
				usesForcedLineHeight = YES;
				lineHeight = minLineHeight;
			}
		}
		
		// get the correct baseline origin
		if (previousLine)
		{
			if (lineHeight==0)
			{
				lineHeight = currentLineMetrics.descent + currentLineMetrics.ascent;
			}
			
			if (isAtBeginOfParagraph)
			{
				lineOrigin.y += previousParaMetrics.paragraphSpacing;
				lineOrigin.y += currentParaMetrics.paragraphSpacingBefore;
			}
			
			if (usesSyntheticLeading)
			{
				lineHeight += currentLineMetrics.leading;
			}
		}
		else 
		{
			// on the first line the maximum line height is the ascender of an attachment if there is any
			
			__block CGFloat maxAttachmentAscender = 0;
			__block BOOL lineHasAttachments = NO;
			[_attributedStringFragment enumerateAttribute:NSAttachmentAttributeName inRange:lineRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(DTTextAttachment *attachment, NSRange range, BOOL *stop) {
				if (attachment)
				{
					CGFloat attachmentAscender = [attachment ascentForLayout];
					
					if (attachmentAscender>maxAttachmentAscender)
					{
						maxAttachmentAscender = attachmentAscender;
						lineHasAttachments = YES;
					}
				}
			}];
			
			if (lineHasAttachments && currentLineMetrics.ascent <= maxAttachmentAscender)
			{
				// an attachment could have a lesser ascent than the surrounding text
				lineHeight = maxAttachmentAscender;
			}
			else
			{
				/*
				 NOTE: CoreText does weird tricks for the first lines of a layout frame
				 I don't know why, but somehow it is always shifting the first line slightly higher.
				 These values seem to work ok.
				 */
				
				if (lineHeight>0)
				{
					lineHeight -= currentLineMetrics.descent;
				}
				else
				{
					lineHeight = currentLineMetrics.ascent + currentLineMetrics.leading - currentLineMetrics.descent/2.0f;
				}
				
				// leading is included in the lineHeight
				if(_noLeadingOnFirstLine == NO)
					lineHeight += currentLineMetrics.leading;
			}
		}
		
		if (isAtBeginOfParagraph)
		{
			lineOrigin.y += currentParaMetrics.paragraphSpacingBefore;
		}
		
		if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(currentParaMetrics.lineHeightMultiplier), &currentParaMetrics.lineHeightMultiplier))
		{
			if (currentParaMetrics.lineHeightMultiplier>0.0f)
			{
				lineHeight *= currentParaMetrics.lineHeightMultiplier;
			}
		}
		
		if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maxLineHeight), &maxLineHeight))
		{
			if (maxLineHeight>0 && lineHeight>maxLineHeight)
			{
				usesForcedLineHeight = YES;
				lineHeight = maxLineHeight;
			}
		}
		
		lineOrigin.y += lineHeight;
		
		// adjust lineOrigin based on paragraph text alignment
		CTTextAlignment textAlignment;
		
		if (!CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment))
		{
			textAlignment = kCTNaturalTextAlignment;
		}

		// determine writing direction
		BOOL isRTL = NO;
		CTWritingDirection baseWritingDirection;
		if (CTParagraphStyleGetValueForSpecifier(paragraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(baseWritingDirection), &baseWritingDirection))
		{
			isRTL = (baseWritingDirection == kCTWritingDirectionRightToLeft);
		} else {
			baseWritingDirection = kCTWritingDirectionNatural;
		}
		
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
				if (baseWritingDirection != kCTWritingDirectionRightToLeft)
				{
					break;
				}
				
				// right alignment falls through
			}
				
			case kCTRightTextAlignment:
			{
				lineOrigin.x = _frame.origin.x + offset + (CGFloat)CTLineGetPenOffsetForFlush(line, 1.0, availableSpace);
				
				break;
			}
				
			case kCTCenterTextAlignment:
			{
				lineOrigin.x = _frame.origin.x + offset + (CGFloat)CTLineGetPenOffsetForFlush(line, 0.5, availableSpace);
				
				break;
			}
				
			case kCTJustifiedTextAlignment:
			{
				BOOL isAtEndOfParagraph    = (currentParagraphRange.location+currentParagraphRange.length <= lineRange.location+lineRange.length ||
					[[_attributedStringFragment string] characterAtIndex:lineRange.location+lineRange.length-1]==0x2028);

				// only justify if not last line, not <br>, and if the line width is longer than 60% of the frame
				// avoids over-stretching
				if( !isAtEndOfParagraph && (currentLineMetrics.width > 0.60 * _frame.size.width) ) 
				{
					// create a justified line and replace the current one with it
					CTLineRef justifiedLine = CTLineCreateJustifiedLine(line, 1.0f, availableSpace);
					CFRelease(line);
					line = justifiedLine;
				}
				
				if (isRTL)
				{
					// align line with right margin
					lineOrigin.x = _frame.origin.x + offset + (CGFloat)CTLineGetPenOffsetForFlush(line, 1.0, availableSpace);
				}
				else
				{
					// align line with left margin
					lineOrigin.x = _frame.origin.x + offset;
				}
				
				break;
			}
		}
		
		// wrap it
		DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:line];
		CFRelease(line);
		
		newLine.writingDirectionIsRightToLeft = isRTL;
		
		// prevent overlap of a line with small font size with line before it
		if (previousLine && !usesForcedLineHeight)
		{
			// only if there IS a line before it AND the line height is not fixed
			CGFloat previousLineBottom = CGRectGetMaxY(previousLine.frame);
			
			if (lineOrigin.y - newLine.ascent < previousLineBottom)
			{
				// move baseline origin down far enough
				lineOrigin.y = previousLineBottom + newLine.ascent;
			}
		}
		
		// baseline origin is rounded
		lineOrigin.y = ceilf(lineOrigin.y);
		
		newLine.baselineOrigin = lineOrigin;
		
		// abort layout if we left the configured frame
		CGFloat lineBottom = lineOrigin.y + currentLineMetrics.descent;
		
		if (lineBottom>maxY)
		{
			if ([typesetLines count] && self.lineBreakMode)
			{
				_numberLinesFitInFrame = [typesetLines count];
				[self _buildLinesWithTypesetter];
				return;
			}
			else
			{
				// doesn't fit any more
				break;
			}
		}
		
		[typesetLines addObject:newLine];
		fittingLength += lineRange.length;
		
		lineRange.location += lineRange.length;
		previousLine = newLine;
	}
	while (lineRange.location < maxIndex && !truncateLine);
	
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
		// need to add bottom padding if in text block
		_additionalPaddingAtBottom = currentTextBlock.padding.bottom;
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
		
		DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:(__bridge CTLineRef)oneLine];
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
	
	//[self _buildLinesWithStandardFramesetter];
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
	
	CGFloat minY = CGRectGetMinY(rect);
	CGFloat maxY = CGRectGetMaxY(rect);
	
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		CGRect lineFrame = oneLine.frame;
		
		// lines before the rect
		if (CGRectGetMaxY(lineFrame)<minY)
		{
			// skip
			continue;
		}
		
		// line is after the rect
		if (lineFrame.origin.y > maxY)
		{
			break;
		}

		// CGRectIntersectsRect returns false if the frame has 0 width, which
		// lines that consist only of line-breaks have. Set the min-width
		// to one to work-around.
		lineFrame.size.width = lineFrame.size.width>1?lineFrame.size.width:1;
		
		if (CGRectIntersectsRect(rect, lineFrame))
		{
			[tmpArray addObject:oneLine];
		}
	}
	
	return tmpArray;
}

- (NSArray *)linesContainedInRect:(CGRect)rect
{
	NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:[self.lines count]];
	
	CGFloat minY = CGRectGetMinY(rect);
	CGFloat maxY = CGRectGetMaxY(rect);
	
	for (DTCoreTextLayoutLine *oneLine in self.lines)
	{
		CGRect lineFrame = oneLine.frame;
		
		// lines before the rect
		if (CGRectGetMaxY(lineFrame)<minY)
		{
			// skip
			continue;
		}
		
		// line is after the rect
		if (lineFrame.origin.y > maxY)
		{
			break;
		}
		
		if (CGRectContainsRect(rect, lineFrame))
		{
			[tmpArray addObject:oneLine];
		}
	}
	
	return tmpArray;
}

#pragma mark Drawing

- (void)_setShadowInContext:(CGContextRef)context fromDictionary:(NSDictionary *)dictionary additionalOffset:(CGSize)additionalOffset
{
	DTColor *color = [dictionary objectForKey:@"Color"];
	CGSize offset = [[dictionary objectForKey:@"Offset"] CGSizeValue];
	CGFloat blur = [[dictionary objectForKey:@"Blur"] floatValue];
	
	// add extra offset
	offset.width += additionalOffset.width;
	offset.height += additionalOffset.height;
	
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

- (CGRect)_frameForTextBlock:(DTTextBlock *)textBlock atIndex:(NSUInteger)location
{
	NSRange blockRange = [_attributedStringFragment rangeOfTextBlock:textBlock atIndex:location];
	
	// need to reduce to actually visible string range in layout frame
	blockRange = NSIntersectionRange(blockRange, self.visibleStringRange);
	
	DTCoreTextLayoutLine *firstBlockLine = [self lineContainingIndex:blockRange.location];
	DTCoreTextLayoutLine *lastBlockLine = [self lineContainingIndex:NSMaxRange(blockRange)-1];
	
	CGRect frame;
	frame.origin = firstBlockLine.frame.origin;
	frame.origin.x = _frame.origin.x; // currently all boxes are full with
	frame.origin.y -= textBlock.padding.top;
	
	CGFloat maxWidth = 0;
	
	for (NSUInteger index = blockRange.location; index<NSMaxRange(blockRange);)
	{
		DTCoreTextLayoutLine *oneLine = [self lineContainingIndex:index];
		
		// avoid potential endless loop and log warning because this should never happen
		if (!oneLine)
		{
			NSLog(@"No line found containing index %ld of block range %@. This should never happen, please report that to oliver@cocoanetics.com", (unsigned long)index, NSStringFromRange(blockRange));
			break;
		}
		
		if (maxWidth<oneLine.frame.size.width)
		{
			maxWidth = oneLine.frame.size.width;
		}
		
		index += oneLine.stringRange.length;
	}
	
	frame.size.width = _frame.size.width; // currently all blocks are 100% wide
	frame.size.height = CGRectGetMaxY(lastBlockLine.frame) - frame.origin.y + textBlock.padding.bottom;
	
	return frame;
}

// draws the HR represented by the layout line
- (void)_drawHorizontalRuleFromLine:(DTCoreTextLayoutLine *)line inContext:(CGContextRef)context
{
	// HR has only a single glyph run with a \n, but that has all the attributes
	DTCoreTextGlyphRun *oneRun = [line.glyphRuns lastObject];
	
	NSDictionary *ruleStyle = [oneRun.attributes objectForKey:DTHorizontalRuleStyleAttribute];
	
	if (!ruleStyle)
	{
		return;
	}
	
	DTColor *color = [oneRun.attributes foregroundColor];
	CGContextSetStrokeColorWithColor(context, color.CGColor);
	
	CGRect nrect = self.frame;
	nrect.origin = line.frame.origin;
	nrect.size.height = oneRun.frame.size.height;
	nrect.origin.y = roundf(nrect.origin.y + oneRun.frame.size.height/2.0f)+0.5f;
	
	DTTextBlock *textBlock = [[oneRun.attributes objectForKey:DTTextBlocksAttribute] lastObject];
	
	if (textBlock)
	{
		// apply horizontal padding
		nrect.size.width = _frame.size.width - textBlock.padding.left - textBlock.padding.right;
	}
	
	CGContextMoveToPoint(context, nrect.origin.x, nrect.origin.y);
	CGContextAddLineToPoint(context, nrect.origin.x + nrect.size.width, nrect.origin.y);
	
	CGContextStrokePath(context);
}

- (void)drawInContext:(CGContextRef)context drawImages:(BOOL)drawImages drawLinks:(BOOL)drawLinks
{
	DTCoreTextLayoutFrameDrawingOptions options = DTCoreTextLayoutFrameDrawingDefault;
	
	if (!drawImages)
	{
		options |= DTCoreTextLayoutFrameDrawingOmitAttachments;
	}
	
	if (!drawLinks)
	{
		options |= DTCoreTextLayoutFrameDrawingOmitLinks;
	}
	
	[self drawInContext:context options:options];
}

// sets the text foreground color based on the glyph run and drawing options
- (void)_setForgroundColorInContext:(CGContextRef)context forGlyphRun:(DTCoreTextGlyphRun *)glyphRun options:(DTCoreTextLayoutFrameDrawingOptions)options
{
	DTColor *color = nil;
	
	BOOL needsToSetFillColor = [[glyphRun.attributes objectForKey:(id)kCTForegroundColorFromContextAttributeName] boolValue];
	
	if (glyphRun.isHyperlink)
	{
		if (options & DTCoreTextLayoutFrameDrawingDrawLinksHighlighted)
		{
			color = [glyphRun.attributes objectForKey:DTLinkHighlightColorAttribute];
		}
	}
	
	if (!color)
	{
		// get text color or use black
		color = [glyphRun.attributes foregroundColor];
	}
	
	// set fill for text that uses kCTForegroundColorFromContextAttributeName
	if (needsToSetFillColor)
	{
		CGContextSetFillColorWithColor(context, color.CGColor);
	}
	
	// set stroke for lines
	CGContextSetStrokeColorWithColor(context, color.CGColor);
}

- (void)drawInContext:(CGContextRef)context options:(DTCoreTextLayoutFrameDrawingOptions)options
{
	BOOL drawLinks = !(options & DTCoreTextLayoutFrameDrawingOmitLinks);
	BOOL drawImages = !(options & DTCoreTextLayoutFrameDrawingOmitAttachments);
	
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
		CGContextSaveGState(context);

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
		
		CGContextSetRGBStrokeColor(context, 1, 0, 0, 0.5);
		CGContextStrokeRect(context, rect);
		
		CGContextRestoreGState(context);
	}
	
	NSArray *visibleLines = [self linesVisibleInRect:rect];
	
	if (![visibleLines count])
	{
		return;
	}
	
	
	CGContextSaveGState(context);
	
	// need to push the CG context so that the UI* based colors can be set
	UIGraphicsPushContext(context);
	
	// text block handling
	__block NSMutableSet *handledBlocks = [NSMutableSet set];
	
	// enumerate all text blocks in this range
	[_attributedStringFragment enumerateAttribute:DTTextBlocksAttribute inRange:_stringRange options:0
									   usingBlock:^(NSArray *blockArray, NSRange range, BOOL *stop) {
										   for (DTTextBlock *oneBlock in blockArray)
										   {
											   // make sure we only handle it once
											   if (![handledBlocks containsObject:oneBlock])
											   {
												   CGRect frame = [self _frameForTextBlock:oneBlock atIndex:range.location];
												   
												   BOOL shouldDrawStandardBackground = YES;
												   if (_textBlockHandler)
												   {
													   _textBlockHandler(oneBlock, frame, context, &shouldDrawStandardBackground);
												   }
												   
												   // draw standard background if necessary
												   if (shouldDrawStandardBackground)
												   {
													   if (oneBlock.backgroundColor)
													   {
														   CGColorRef color = [oneBlock.backgroundColor CGColor];
														   CGContextSetFillColorWithColor(context, color);
														   CGContextFillRect(context, frame);
													   }
												   }
												   
												   if (_DTCoreTextLayoutFramesShouldDrawDebugFrames)
												   {
													   CGContextSaveGState(context);
													   
													   // draw line bounds
													   CGContextSetRGBStrokeColor(context, 0.5, 0, 0.5f, 1.0f);
													   CGContextSetLineWidth(context, 2);
													   CGContextStrokeRect(context, CGRectInset(frame, 2, 2));
													   
													   CGContextRestoreGState(context);
												   }
												   
												   [handledBlocks addObject:oneBlock];
											   }
										   }
										   
										   
									   }];

	
	
	for (DTCoreTextLayoutLine *oneLine in visibleLines)
	{
		if ([oneLine isHorizontalRule])
		{
			[self _drawHorizontalRuleFromLine:oneLine inContext:context];
			continue;
		}
		
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
			if (!CGRectIntersectsRect(rect, oneRun.frame))
			{
				continue;
			}
			
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
			
			if (!drawLinks && oneRun.isHyperlink)
			{
				continue;
			}
			
			// don't draw decorations on images
			if (oneRun.attachment)
			{
				continue;
			}
			
			// don't draw background, strikout or underline for trailing white space
			if ([oneRun isTrailingWhitespace])
			{
				continue;
			}
			
			[self _setForgroundColorInContext:context forGlyphRun:oneRun options:options];
			
			[oneRun drawDecorationInContext:context];
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
			if (!CGRectIntersectsRect(rect, oneRun.frame))
			{
				continue;
			}
			
			if (!drawLinks && oneRun.isHyperlink)
			{
				continue;
			}
			
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
			
			DTTextAttachment *attachment = oneRun.attachment;
			
			if (attachment)
			{
				if (drawImages && [attachment conformsToProtocol:@protocol(DTTextAttachmentDrawing)])
				{
					id<DTTextAttachmentDrawing> drawableAttachment = (id<DTTextAttachmentDrawing>)attachment;
					
					// frame might be different due to image vertical alignment
					CGFloat ascender = [attachment ascentForLayout];
					CGFloat descender = [attachment descentForLayout];
					
					CGPoint origin = oneRun.frame.origin;
					origin.y = self.frame.size.height - origin.y - ascender - descender;
					CGRect flippedRect = CGRectMake(roundf(origin.x), roundf(origin.y), attachment.displaySize.width, attachment.displaySize.height);
					
					[drawableAttachment drawInRect:flippedRect context:context];
				}
			}
			else
			{
				NSArray *shadows = [oneRun.attributes objectForKey:DTShadowsAttribute];
				
				if (shadows)
				{
					CGContextSaveGState(context);
					
					NSUInteger numShadows = [shadows count];
					
					if (numShadows == 1)
					{
						// single shadow, we only draw the glyph run with the shadow, no clipping magic
						NSDictionary *singleShadow = [shadows objectAtIndex:0];
						[self _setShadowInContext:context fromDictionary:singleShadow additionalOffset:CGSizeZero];
						
						[oneRun drawInContext:context];
					}
					else // multiple shadows, we shift the text away and then draw a single glyph run over it
					{
						// get the run bounds, Core Text has bottom left 0,0 so we flip it
						CGRect runBoundsFlipped = oneRun.frame;
						runBoundsFlipped.origin.y = self.frame.size.height - runBoundsFlipped.origin.y - runBoundsFlipped.size.height;
						
						// assume that shadows would never be more than 100 pixels away from glyph run frame or outside of frame
						CGRect clipRect = CGRectIntersection(CGRectInset(runBoundsFlipped, -100, -100), self.frame);
						
						// clip to the rect
						CGContextAddRect(context, clipRect);
						CGContextClipToRect(context, clipRect);
						
						// Move the text outside of the clip rect so that only the shadow is visisble
						CGContextSetTextPosition(context, textPosition.x + clipRect.size.width, textPosition.y);
						
						// draw each shadow
						[shadows enumerateObjectsUsingBlock:^(NSDictionary *shadowDict, NSUInteger idx, BOOL *stop) {
							BOOL isLastShadow = (idx == (numShadows-1));
							
							if (isLastShadow)
							{
								// last shadow draws the original text
								[self _setShadowInContext:context fromDictionary:shadowDict additionalOffset:CGSizeZero];
								
								// ... so we put text position back
								CGContextSetTextPosition(context, textPosition.x, textPosition.y);
							}
							else
							{
								[self _setShadowInContext:context fromDictionary:shadowDict additionalOffset:CGSizeMake(-clipRect.size.width, 0)];
							}
							
							[oneRun drawInContext:context];
						}];
					}
					
					CGContextRestoreGState(context);
				}
				else // no shadows
				{
					[self _setForgroundColorInContext:context forGlyphRun:oneRun options:options];

					[oneRun drawInContext:context];
				}
			}
		}
	}
	
	if (_textFrame)
	{
		CFRelease(_textFrame);
	}
	
	UIGraphicsPopContext();
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
	
	// need to build lines to know range
	if (!_lines)
	{
		[self _buildLines];
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
	if (!_lines)
	{
		[self _buildLines];
	}
	
	if (![self.lines count])
	{
		return CGRectZero;
	}
	
	if (_frame.size.height == CGFLOAT_OPEN_HEIGHT)
	{
		// actual frame is spanned between first and last lines
		DTCoreTextLayoutLine *lastLine = [_lines lastObject];
	
		_frame.size.height = ceilf((CGRectGetMaxY(lastLine.frame) - _frame.origin.y + 1.5f + _additionalPaddingAtBottom));
	}
	
	return _frame;
}

- (CGRect)intrinsicContentFrame
{
	if (!_lines)
	{
		[self _buildLines];
	}
	
	if (![self.lines count])
	{
		return CGRectZero;
	}
	
	DTCoreTextLayoutLine *firstLine = [_lines objectAtIndex:0];
	
	CGRect outerFrame = self.frame;
	
	CGRect frameOverAllLines = firstLine.frame;
	
	// move up to frame origin because first line usually does not go all the ways up
	frameOverAllLines.origin.y = outerFrame.origin.y;
	
	for (DTCoreTextLayoutLine *oneLine in _lines)
	{
		// need to limit frame to outer frame, otherwise HR causes too long lines
		CGRect frame = CGRectIntersection(oneLine.frame, outerFrame);
		
		frameOverAllLines = CGRectUnion(frame, frameOverAllLines);
	}
	
	// extend height same method as frame
	frameOverAllLines.size.height = ceilf(frameOverAllLines.size.height + 1.5f + _additionalPaddingAtBottom);
	
	return CGRectIntegral(frameOverAllLines);
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

// returns YES if the given line is the first in a paragraph
- (BOOL)isLineFirstInParagraph:(DTCoreTextLayoutLine *)line
{
	NSRange lineRange = line.stringRange;
	
	if (lineRange.location == 0)
	{
		return YES;
	}
	
	NSInteger prevLineLastUnicharIndex =lineRange.location - 1;
	unichar prevLineLastUnichar = [[_attributedStringFragment string] characterAtIndex:prevLineLastUnicharIndex];
	
	return [[NSCharacterSet newlineCharacterSet] characterIsMember:prevLineLastUnichar];
}

// returns YES if the given line is the last in a paragraph
- (BOOL)isLineLastInParagraph:(DTCoreTextLayoutLine *)line
{
	NSString *lineString = [[_attributedStringFragment string] substringWithRange:line.stringRange];
	
	if ([lineString hasSuffix:@"\n"])
	{
		return YES;
	}
	
	return NO;
}

// finds the appropriate baseline origin for a line to position it at the correct distance from a previous line
- (CGPoint)baselineOriginToPositionLine:(DTCoreTextLayoutLine *)line afterLine:(DTCoreTextLayoutLine *)previousLine
{
	CGPoint lineOrigin = previousLine.baselineOrigin;
	
	NSInteger lineStartIndex = line.stringRange.location;
	
	CTParagraphStyleRef lineParagraphStyle = (__bridge CTParagraphStyleRef)[_attributedStringFragment
																									attribute:(id)kCTParagraphStyleAttributeName
																									atIndex:lineStartIndex effectiveRange:NULL];
	
	//Meet the first line in this frame
	if (!previousLine)
	{
		// The first line may or may not be the start of paragraph. It depends on the the range passing to
		// - (DTCoreTextLayoutFrame *)layoutFrameWithRect:(CGRect)frame range:(NSRange)range;
		// So Check it in a safe way:
		if ([self isLineFirstInParagraph:line])
		{
			
			CGFloat paraSpacingBefore = 0;
			
			if (CTParagraphStyleGetValueForSpecifier(lineParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(paraSpacingBefore), &paraSpacingBefore))
			{
				lineOrigin.y += paraSpacingBefore;
			}
			
			// preserve own baseline x
			lineOrigin.x = line.baselineOrigin.x;
			
			// origins are rounded
			lineOrigin.y = ceilf(lineOrigin.y);
			
			return lineOrigin;
			
		}
		
	}
	
	// get line height in px if it is specified for this line
	CGFloat lineHeight = 0;
	CGFloat minLineHeight = 0;
	CGFloat maxLineHeight = 0;
	BOOL usesForcedLineHeight = NO;
	
	CGFloat usedLeading = line.leading;
	
	if (usedLeading == 0.0f)
	{
		// font has no leading, so we fake one (e.g. Helvetica)
		CGFloat tmpHeight = line.ascent + line.descent;
		usedLeading = ceilf(0.2f * tmpHeight);
		
		if (usedLeading>20)
		{
			// we have a large image increasing the ascender too much for this calc to work
			usedLeading = 0;
		}
	}
	else
	{
		// make sure that we don't have less than 10% of line height as leading
		usedLeading = ceilf(MAX((line.ascent + line.descent)*0.1f, usedLeading));
	}
	
	if (CTParagraphStyleGetValueForSpecifier(lineParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(minLineHeight), &minLineHeight))
	{
		usesForcedLineHeight = YES;
		
		if (lineHeight<minLineHeight)
		{
			lineHeight = minLineHeight;
		}
	}
	
	// is absolute line height set?
	if (lineHeight==0)
	{
		lineHeight = line.descent + line.ascent + usedLeading;
	}
	
	if ([self isLineLastInParagraph:previousLine])
	{
		// need to get paragraph spacing
		CTParagraphStyleRef previousLineParagraphStyle = (__bridge CTParagraphStyleRef)[_attributedStringFragment
																												  attribute:(id)kCTParagraphStyleAttributeName
																												  atIndex:previousLine.stringRange.location effectiveRange:NULL];
		
		// Paragraph spacings are paragraph styles and should not be multiplied by kCTParagraphStyleSpecifierLineHeightMultiple
		// So directly add them to lineOrigin.y
		CGFloat paraSpacing;
		
		if (CTParagraphStyleGetValueForSpecifier(previousLineParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paraSpacing), &paraSpacing))
		{
			lineOrigin.y += paraSpacing;
		}
		
		CGFloat paraSpacingBefore;
		
		if (CTParagraphStyleGetValueForSpecifier(lineParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(paraSpacingBefore), &paraSpacingBefore))
		{
			lineOrigin.y += paraSpacingBefore;
		}
	}
	
	CGFloat lineHeightMultiplier = 0;
	
	if (CTParagraphStyleGetValueForSpecifier(lineParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(lineHeightMultiplier), &lineHeightMultiplier))
	{
		if (lineHeightMultiplier>0.0f)
		{
			lineHeight *= lineHeightMultiplier;
		}
	}
	
	if (CTParagraphStyleGetValueForSpecifier(lineParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(maxLineHeight), &maxLineHeight))
	{
		if (maxLineHeight>0 && lineHeight>maxLineHeight)
		{
			lineHeight = maxLineHeight;
		}
	}
	
	lineOrigin.y += lineHeight;
	
	// preserve own baseline x
	lineOrigin.x = line.baselineOrigin.x;
	
	// prevent overlap of a line with small font size with line before it
	if (!usesForcedLineHeight)
	{
		// only if there IS a line before it AND the line height is not fixed
		CGFloat previousLineBottom = CGRectGetMaxY(previousLine.frame);
		
		if (lineOrigin.y - line.ascent < previousLineBottom)
		{
			// move baseline origin down far enough
			lineOrigin.y = previousLineBottom + line.ascent;
		}
	}
	
	// origins are rounded
	lineOrigin.y = ceilf(lineOrigin.y);
	
	return lineOrigin;
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

+ (BOOL)shouldDrawDebugFrames
{
	return _DTCoreTextLayoutFramesShouldDrawDebugFrames;
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
		NSUInteger length = [plainString length];
		
		NSRange paragraphRange = [plainString rangeOfParagraphsContainingRange:NSMakeRange(0, 0) parBegIndex:NULL parEndIndex:NULL];

		NSMutableArray *tmpArray = [NSMutableArray array];

		while (paragraphRange.length)
		{
			NSValue *value = [NSValue valueWithRange:paragraphRange];
			[tmpArray addObject:value];
			
			NSUInteger nextParagraphBegin = NSMaxRange(paragraphRange);
			
			if (nextParagraphBegin>=length)
			{
				break;
			}
			
			// next paragraph
			paragraphRange = [plainString rangeOfParagraphsContainingRange:NSMakeRange(nextParagraphBegin, 0) parBegIndex:NULL parEndIndex:NULL];
		}
		
		_paragraphRanges = tmpArray; // no copy for performance
	}
	
	return _paragraphRanges;
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    if( _numberOfLines != numberOfLines )
	 {
		_numberOfLines = numberOfLines;
        // clear lines cache
        _lines = nil;
    }
}

- (void)setLineBreakMode:(NSLineBreakMode)lineBreakMode
{
    if( _lineBreakMode != lineBreakMode )
	 {
        _lineBreakMode = lineBreakMode;
        // clear lines cache
        _lines = nil;
    }
}

- (void)setTruncationString:(NSAttributedString *)truncationString
{
    if( ![_truncationString isEqualToAttributedString:truncationString] )
	 {
        _truncationString = truncationString;
		
        if( self.numberOfLines > 0 )
		  {
            // clear lines cache
            _lines = nil;
        }
    }
}

@synthesize frame = _frame;
@synthesize lines = _lines;
@synthesize paragraphRanges = _paragraphRanges;
@synthesize textBlockHandler = _textBlockHandler;

@end
