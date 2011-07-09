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

@interface DTCoreTextLayoutFrame ()

@property (nonatomic, retain) NSArray *lines;

@end


static BOOL _DTCoreTextLayoutFramesShouldDrawDebugFrames = NO;


@implementation DTCoreTextLayoutFrame

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
		
		_layouter = [layouter retain];
		
		
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
			
			
			[_layouter release];
			[self release];
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
		_textFrame = NULL;
	}
	[_lines release];
	[_layouter release];
	
	if (_framesetter)
	{
		CFRelease(_framesetter);
		_framesetter = NULL;
	}
	
	[_textAttachments release];
	
	[super dealloc];
}

- (NSString *)description
{
	return [self.lines description];
}

- (void)buildLines
{
	// get lines
	CFArrayRef lines = CTFrameGetLines(_textFrame);
	
	if (!lines)
	{
		// probably no string set
		return;
	}
	
	CGPoint *origins = malloc(sizeof(CGPoint)*[(NSArray *)lines count]);
	CTFrameGetLineOrigins(_textFrame, CFRangeMake(0, 0), origins);
	
	NSMutableArray *tmpLines = [[NSMutableArray alloc] initWithCapacity:CFArrayGetCount(lines)];;
	
	NSInteger lineIndex = 0;
	
	for (id oneLine in (NSArray *)lines)
	{
		CGPoint lineOrigin = origins[lineIndex];
		lineOrigin.y = _frame.size.height - lineOrigin.y + _frame.origin.y;
		lineOrigin.x += _frame.origin.x;
		
		DTCoreTextLayoutLine *newLine = [[DTCoreTextLayoutLine alloc] initWithLine:(CTLineRef)oneLine layoutFrame:self origin:lineOrigin];
		[tmpLines addObject:newLine];
		[newLine release];
		
		lineIndex++;
	}
	
	_lines = tmpLines;
	
	free(origins);
	
	// at this point we can correct the frame if it is open-ended
	if ([_lines count] && _frame.size.height == CGFLOAT_OPEN_HEIGHT)
	{
		// actual frame is spanned between first and last lines
		DTCoreTextLayoutLine *lastLine = [_lines lastObject];
		
		_frame.size.height = ceilf((CGRectGetMaxY(lastLine.frame) - _frame.origin.y + 1.5));
	}
	
	// --- begin workaround for image squishing bug in iOS < 4.2
	
	DTVersion version = [[UIDevice currentDevice] osVersion];
	
	if (version.major<4 || (version.major==4 && version.minor < 2))
	{
		[self correctAttachmentHeights];
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
	
	if (!_textFrame || !context)
	{
		return;
	}
	
	CFRetain(_textFrame);
	
	[self retain];
	[_layouter retain];
	
	// any of these settings make sense?
	//	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	//	CGContextSetAllowsAntialiasing(context, YES);
	//	CGContextSetShouldAntialias(context, YES);
	//	
	//	CGContextSetAllowsFontSubpixelQuantization(context, YES);
	//	CGContextSetShouldSubpixelQuantizeFonts(context, YES);
	//	
	//	CGContextSetShouldSmoothFonts(context, YES);
	//	CGContextSetAllowsFontSmoothing(context, YES);
	//	
	//	CGContextSetShouldSubpixelPositionFonts(context,YES);
	//	CGContextSetAllowsFontSubpixelPositioning(context, YES);
	
	
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
			CGContextMoveToPoint(context, oneLine.baselineOrigin.x-5.0, oneLine.baselineOrigin.y);
			CGContextAddLineToPoint(context, oneLine.baselineOrigin.x + oneLine.frame.size.width + 5.0, oneLine.baselineOrigin.y);
			CGContextStrokePath(context);
		}
		
		NSInteger runIndex = 0;
		
		for (DTCoreTextGlyphRun *oneRun in oneLine.glyphRuns)
		{
			if (_DTCoreTextLayoutFramesShouldDrawDebugFrames)
			{
				if (runIndex%2)
				{
					CGContextSetRGBFillColor(context, 1, 0, 0, 0.2);
				}
				else 
				{
					CGContextSetRGBFillColor(context, 0, 1, 0, 0.2);
				}
				
				CGContextFillRect(context, oneRun.frame);
				runIndex ++;
			}
			
			
			CGColorRef backgroundColor = (CGColorRef)[oneRun.attributes objectForKey:@"DTBackgroundColor"];
			
			
			NSDictionary *ruleStyle = [oneRun.attributes objectForKey:@"DTHorizontalRuleStyle"];
			
			if (ruleStyle)
			{
				if (backgroundColor)
				{
					CGContextSetStrokeColorWithColor(context, backgroundColor);
				}
				else
				{
					CGContextSetGrayStrokeColor(context, 0, 1.0);
				}
				
				CGRect rect = self.frame;
				rect.origin = oneLine.frame.origin;
				rect.size.height = oneRun.frame.size.height;
				rect.origin.y = roundf(rect.origin.y + oneRun.frame.size.height/2.0)+0.5;
				
				CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
				CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y);
				
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
					CGContextSetStrokeColorWithColor(context, (CGColorRef)color);
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
						runStrokeBounds.origin.y -= oneRun.ascent * 0.47;
						break;
					}	
					case -1:
					{
						runStrokeBounds.origin.y += oneRun.ascent * 0.25;
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
					runStrokeBounds.origin.y = roundf(runStrokeBounds.origin.y + oneRun.frame.size.height/2.0 + 1)+0.5;
					
					CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
					CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
					
					CGContextStrokePath(context);
				}
				
				if (drawUnderline)
				{
					runStrokeBounds.origin.y = roundf(runStrokeBounds.origin.y + oneRun.frame.size.height - oneRun.descent + 1)+0.5;
					
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
					textPosition.y += oneRun.ascent * 0.47;
					break;
				}	
				case -1:
				{
					textPosition.y -= oneRun.ascent * 0.25;
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
	
	[self release];
	[_layouter release];
	
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
	NSMutableArray *array = [NSMutableArray array];
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

#pragma mark Properties
@synthesize frame = _frame;
@synthesize layouter = _layouter;
@synthesize lines = _lines;
@synthesize tag;

@end
