//
//  DTCoreTextGlyphRun.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreTextGlyphRun.h"
#import "DTCoreTextLayoutLine.h"
#import "DTTextAttachment.h"
#import "DTCoreTextConstants.h"
#import "DTCoreTextParagraphStyle.h"
#import "DTCoreTextFunctions.h"
#import "NSDictionary+DTCoreText.h"
#import "DTWeakSupport.h"
#import "DTLog.h"

@implementation DTCoreTextGlyphRun
{
	CTRunRef _run;
	CGRect _frame;
	
	CGFloat _offset; // x distance from line origin 
	CGFloat _ascent;
	CGFloat _descent;
	CGFloat _leading;
	CGFloat _width;
	
	BOOL _writingDirectionIsRightToLeft;
	BOOL _isTrailingWhitespace;
	
	NSInteger _numberOfGlyphs;
	
	const CGPoint *_glyphPositionPoints;
	
	DT_WEAK_VARIABLE DTCoreTextLayoutLine *_line;	// retain cycle, since these objects are retained by the _line
	DT_WEAK_VARIABLE NSDictionary *_attributes; // weak because it is owned by _run IVAR
	NSArray *_stringIndices;
	
	DTTextAttachment *_attachment;
	BOOL _hyperlink;
	
	BOOL _didCheckForAttachmentInAttributes;
	BOOL _didCheckForHyperlinkInAttributes;
	BOOL _didCalculateMetrics;
	BOOL _didDetermineTrailingWhitespace;
}

- (id)initWithRun:(CTRunRef)run layoutLine:(DTCoreTextLayoutLine *)layoutLine offset:(CGFloat)offset
{
	self = [super init];
	
	if (self)
	{
		_run = run;
		CFRetain(_run);
		
		_offset = offset;
		_line = layoutLine;
	}
	
	return self;
}

- (void)dealloc
{
	if (_run)
	{
		CFRelease(_run);
	}
}

#ifndef COVERAGE 
// exclude method from coverage testing

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ glyphs=%ld %@>", [self class], (long)[self numberOfGlyphs], NSStringFromCGRect(_frame)];
}

#endif

#pragma mark - Drawing

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

- (void)drawDecorationInContext:(CGContextRef)context
{
	// get the scaling factor of the current translation matrix
	CGAffineTransform ctm = CGContextGetCTM(context);
	CGFloat contentScale = MAX(ctm.a, -ctm.d); // needed for  rounding operations
	
	if (contentScale<1 || contentScale>2)
	{
		contentScale = 2;
	}
	
	CGFloat smallestPixelWidth = 1.0f/contentScale;
	
	DTColor *backgroundColor = [self.attributes backgroundColor];
	
	// -------------- Line-Out, Underline, Background-Color
	BOOL drawStrikeOut = [[_attributes objectForKey:DTStrikeOutAttribute] boolValue];
	BOOL drawUnderline = [[_attributes objectForKey:(id)kCTUnderlineStyleAttributeName] boolValue];
	
	if (drawStrikeOut||drawUnderline||backgroundColor)
	{
		// calculate area covered by non-whitespace
		CGRect lineFrame = _line.frame;
		
		// LTR line frames include trailing whitespace in width
		// we need to subtract it so that we don't highlight/underline it
		if (!_line.writingDirectionIsRightToLeft)
		{
			lineFrame.size.width -= _line.trailingWhitespaceWidth;
		}
		
		// exclude trailing whitespace so that we don't underline too much
		CGRect runStrokeBounds = CGRectIntersection(lineFrame, self.frame);
		
		NSInteger superscriptStyle = [[_attributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];
		
		switch (superscriptStyle)
		{
			case 1:
			{
				runStrokeBounds.origin.y -= _ascent * 0.47f;
				break;
			}
			case -1:
			{
				runStrokeBounds.origin.y += _ascent * 0.25f;
				break;
			}
			default:
				break;
		}
		
		if (backgroundColor)
		{
			CGRect backgroundColorRect = CGRectIntegral(CGRectMake(runStrokeBounds.origin.x, lineFrame.origin.y, runStrokeBounds.size.width, lineFrame.size.height));
			
			CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
			CGContextFillRect(context, backgroundColorRect);
		}
		
		if (drawStrikeOut || drawUnderline)
		{
			BOOL didDrawSomething = NO;
			
			CGContextSaveGState(context);
			
			CTFontRef usedFont = (__bridge CTFontRef)([_attributes objectForKey:(id)kCTFontAttributeName]);
			
			CGFloat fontUnderlineThickness;
			
			if (usedFont)
			{
				fontUnderlineThickness = CTFontGetUnderlineThickness(usedFont) * smallestPixelWidth;
			}
			else
			{
				fontUnderlineThickness = smallestPixelWidth;
			}
			
			CGFloat usedUnderlineThickness = DTCeilWithContentScale(fontUnderlineThickness, contentScale);
			
			CGContextSetLineWidth(context, usedUnderlineThickness);
			
			if (drawStrikeOut)
			{
				CGFloat y;
				
				if (usedFont)
				{
					CGFloat strokePosition = CTFontGetXHeight(usedFont)/(CGFloat)2.0;
					y = DTRoundWithContentScale(runStrokeBounds.origin.y + _ascent - strokePosition, contentScale);
				}
				else
				{
					y = DTRoundWithContentScale((runStrokeBounds.origin.y + self.frame.size.height/2.0f + 1), contentScale);
				}
				
				if ((int)(usedUnderlineThickness/smallestPixelWidth)%2) // odd line width
				{
					y += smallestPixelWidth/2.0f; // shift down half a pixel to avoid aliasing
				}
				
				CGContextMoveToPoint(context, runStrokeBounds.origin.x, y);
				CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, y);
				
				didDrawSomething = YES;
			}
			
			// only draw underlines if Core Text didn't draw them yet
			if (drawUnderline && !DTCoreTextDrawsUnderlinesWithGlyphs())
			{
				CGFloat y;
				
				// use lowest underline position of all glyph runs in same line
				CGFloat underlinePosition = [_line underlineOffset];
				
				y = DTRoundWithContentScale(_line.baselineOrigin.y + underlinePosition - fontUnderlineThickness/2.0f, contentScale);
				
				if ((int)(usedUnderlineThickness/smallestPixelWidth)%2) // odd line width
				{
					y += smallestPixelWidth/2.0f; // shift down half a pixel to avoid aliasing
				}
				
				CGContextMoveToPoint(context, runStrokeBounds.origin.x, y);
				CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, y);
				
				didDrawSomething = YES;
			}
			
			if (didDrawSomething)
			{
				CGContextStrokePath(context);
			}
			
			CGContextRestoreGState(context); // restore antialiasing
		}
	}
}

- (CGPathRef)newPathWithGlyphs
{
	CTFontRef font = (__bridge CTFontRef)[self.attributes objectForKey:(id)kCTFontAttributeName];

	if (!font)
	{
		DTLogError(@"CTFont missing on %@", self);
		return NULL;
	}
	
	const CGGlyph *glyphs = CTRunGetGlyphsPtr(_run);
	const CGPoint *positions = CTRunGetPositionsPtr(_run);
	
	CGMutablePathRef mutablePath = CGPathCreateMutable();
	
	for (NSUInteger i = 0; i < CTRunGetGlyphCount(_run); i++)
	{
		CGGlyph glyph = glyphs[i];
		CGPoint position = positions[i];

		CGAffineTransform glyphTransform = CTRunGetTextMatrix(_run);
		
		glyphTransform = CGAffineTransformScale(glyphTransform, 1, -1);
		
		
		CGPathRef glyphPath = CTFontCreatePathForGlyph(font, glyph, &glyphTransform);
		
		CGAffineTransform posTransform = CGAffineTransformMakeTranslation(position.x, position.y);
		CGPathAddPath(mutablePath, &posTransform, glyphPath);
		
		CGPathRelease(glyphPath);
	}

	return mutablePath;
}

#pragma mark - Calculations
- (void)calculateMetrics
{
	// calculate metrics
	@synchronized(self)
	{
		if (!_didCalculateMetrics)
		{
			_width = (CGFloat)CTRunGetTypographicBounds((CTRunRef)_run, CFRangeMake(0, 0), &_ascent, &_descent, &_leading);
			_didCalculateMetrics = YES;
		}
	}
}

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index
{
	if (!_didCalculateMetrics)
	{
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

		_stringRange = NSMakeRange(range.location + _line.stringLocationOffset, range.length);
	}
	
	return _stringRange;
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

- (BOOL)isTrailingWhitespace
{
	if (_didDetermineTrailingWhitespace)
	{
		return _isTrailingWhitespace;
	}
	
	BOOL isTrailing;
	
	if (_line.writingDirectionIsRightToLeft)
	{
		isTrailing = (self == [[_line glyphRuns] objectAtIndex:0]);
	}
	else
	{
		isTrailing = (self == [[_line glyphRuns] lastObject]);
	}
	
	if (isTrailing)
	{
		if (!_didCalculateMetrics)
		{
			[self calculateMetrics];
		}

		// this is trailing whitespace if it matches the lines's trailing whitespace
		if (_line.trailingWhitespaceWidth >= _width)
		{
			_isTrailingWhitespace = YES;
		}
	}
	
	_didDetermineTrailingWhitespace = YES;
	return _isTrailingWhitespace;
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

- (BOOL)writingDirectionIsRightToLeft
{
	CTRunStatus status = CTRunGetStatus(_run);
	
	return (status & kCTRunStatusRightToLeft)!=0;
}

@synthesize frame = _frame;
@synthesize numberOfGlyphs = _numberOfGlyphs;
@synthesize attributes = _attributes;

@synthesize ascent = _ascent;
@synthesize descent = _descent;
@synthesize leading = _leading;
@synthesize attachment = _attachment;
@synthesize writingDirectionIsRightToLeft = _writingDirectionIsRightToLeft;

@end
