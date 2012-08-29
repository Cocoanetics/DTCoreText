//
//  DTLinkButton.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTLinkButton.h"
#import "CGUtils.h"
#import "DTColor+HTML.h"

//#import "DTCoreTextLayoutFrame.h"
//#import "DTCoreTextLayouter.h"
//#import "DTCoreTextGlyphRun.h"
#import "DTCoreText.h"

// constant for notification
NSString *DTLinkButtonDidHighlightNotification = @"DTLinkButtonDidHighlightNotification";


@interface DTLinkButton ()

- (void)highlightNotification:(NSNotification *)notification;

@end


@implementation DTLinkButton
{
	NSURL *_URL;
    NSString *_GUID;
	
	CGSize _minimumHitSize;
	BOOL _showsTouchWhenHighlighted;
	
	// normal text
	NSAttributedString *_attributedString;
	DTCoreTextLayoutLine *_normalLine;
	DTCoreTextGlyphRun *_normalGlyphRun;
	
	// highlighted text
	NSAttributedString *_highlightedAttributedString;
	DTCoreTextLayoutLine *_highlightedLine;
	DTCoreTextGlyphRun *_highlightedGlyphRun;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.userInteractionEnabled = YES;
		self.enabled = YES;
		self.opaque = NO;
		
		_showsTouchWhenHighlighted = YES;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightNotification:) name:DTLinkButtonDidHighlightNotification object:nil];
	}
	
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	
}

#pragma mark Drawing the Link Text

- (DTCoreTextGlyphRun *)_normalGlyphRun
{
	if (!_normalGlyphRun && _attributedString)
	{
		DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_attributedString];
		
		CGRect infiniteRect = CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_OPEN_HEIGHT);
		DTCoreTextLayoutFrame *frame = [[DTCoreTextLayoutFrame alloc] initWithFrame:infiniteRect layouter:layouter];
		
		if (![frame.lines count])
		{
			return nil;
		}
		
		// get the line
		_normalLine = [frame.lines objectAtIndex:0];
		
		if (![_normalLine.glyphRuns count])
		{
			return nil;
		}
		
		// get the glyph run
		_normalGlyphRun	= [_normalLine.glyphRuns objectAtIndex:0];
	}
	
	return _normalGlyphRun;
}

- (DTCoreTextGlyphRun *)_highlightedGlyphRun
{
	if (!_highlightedGlyphRun && _highlightedAttributedString)
	{
		DTCoreTextLayouter *layouter = [[DTCoreTextLayouter alloc] initWithAttributedString:_highlightedAttributedString];
		
		CGRect infiniteRect = CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_OPEN_HEIGHT);
		DTCoreTextLayoutFrame *frame = [[DTCoreTextLayoutFrame alloc] initWithFrame:infiniteRect layouter:layouter];
		
		if (![frame.lines count])
		{
			return nil;
		}
		
		// get the line
		_highlightedLine = [frame.lines objectAtIndex:0];
		
		if (![_highlightedLine.glyphRuns count])
		{
			return nil;
		}
		
		// get the glyph run
		_highlightedGlyphRun	= [_highlightedLine.glyphRuns objectAtIndex:0];
	}
	
	return _highlightedGlyphRun;
}

- (void)drawTextInContext:(CGContextRef)context highlighted:(BOOL)highlighted
{
	DTCoreTextGlyphRun *glyphRunToDraw = nil;
	
	if (highlighted)
	{
		// use highlighted glyph run
		glyphRunToDraw = [self _highlightedGlyphRun];
	}
	else
	{
		// use normal glyph run
		glyphRunToDraw = [self _normalGlyphRun];
	}
	
	if (!glyphRunToDraw)
	{
		return;
	}
	
	CGContextSaveGState(context);
	
	NSDictionary *runAttributes = glyphRunToDraw.attributes;
	
	// -------------- Line-Out, Underline, Background-Color
	BOOL drawStrikeOut = [[runAttributes objectForKey:DTStrikeOutAttribute] boolValue];
	BOOL drawUnderline = [[runAttributes objectForKey:(id)kCTUnderlineStyleAttributeName] boolValue];
				
	CGColorRef backgroundColor = (__bridge CGColorRef)[runAttributes objectForKey:DTBackgroundColorAttribute];
	
	if (drawStrikeOut||drawUnderline||backgroundColor)
	{
		// get text color or use black
		id color = [runAttributes objectForKey:(id)kCTForegroundColorAttributeName];
		
		if (color)
		{
			CGContextSetStrokeColorWithColor(context, (__bridge CGColorRef)color);
		}
		else
		{
			CGContextSetGrayStrokeColor(context, 0, 1.0);
		}
		
		CGRect runStrokeBounds = UIEdgeInsetsInsetRect(self.bounds, self.contentEdgeInsets);
		
		NSInteger superscriptStyle = [[glyphRunToDraw.attributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];
		
		switch (superscriptStyle)
		{
			case 1:
			{
				runStrokeBounds.origin.y -= glyphRunToDraw.ascent * 0.47f;
				break;
			}
			case -1:
			{
				runStrokeBounds.origin.y += glyphRunToDraw.ascent * 0.25f;
				break;
			}
			default:
				break;
		}
		
		
//		if (lastRunInLine)
//		{
//			runStrokeBounds.size.width -= [oneLine trailingWhitespaceWidth];
//		}
		
		if (backgroundColor)
		{
			CGContextSetFillColorWithColor(context, backgroundColor);
			CGContextFillRect(context, runStrokeBounds);
		}
		
		if (drawStrikeOut)
		{
			runStrokeBounds.origin.y = roundf(runStrokeBounds.origin.y + glyphRunToDraw.frame.size.height/2.0f + 1)+0.5f;
			
			CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
			CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
			
			CGContextStrokePath(context);
		}
		
		if (drawUnderline)
		{
			runStrokeBounds.origin.y = ceilf(runStrokeBounds.origin.y + glyphRunToDraw.frame.size.height - glyphRunToDraw.descent)+0.5f;
			
			CGContextMoveToPoint(context, runStrokeBounds.origin.x, runStrokeBounds.origin.y);
			CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, runStrokeBounds.origin.y);
			
			CGContextStrokePath(context);
		}
	}
	
	// Flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextTranslateCTM(context, 0, -self.bounds.size.height);
	
	CGContextSetTextPosition(context, 0, ceilf(glyphRunToDraw.descent+self.contentEdgeInsets.bottom));

	[glyphRunToDraw drawInContext:context];
	
	CGContextRestoreGState(context);
}

#pragma mark Drawing the Run

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (self.highlighted)
	{
		[self drawTextInContext:ctx highlighted:YES];
		
		if (_showsTouchWhenHighlighted)
		{
			CGRect imageRect = [self contentRectForBounds:self.bounds];
		
			UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:imageRect cornerRadius:3.0f];
			CGContextSetGrayFillColor(ctx, 0.73f, 0.4f);
			[roundedPath fill];
		}
	}
	else
	{
		[self drawTextInContext:ctx highlighted:NO];
	}
}

#pragma mark Utilitiy

- (void)adjustBoundsIfNecessary
{
	CGRect bounds = self.bounds;
	CGFloat widthExtend = 0;
	CGFloat heightExtend = 0;
	
	if (bounds.size.width < _minimumHitSize.width)
	{
		widthExtend = _minimumHitSize.width - bounds.size.width;
		bounds.size.width = _minimumHitSize.width;
	}
	
	if (bounds.size.height < _minimumHitSize.height)
	{
		heightExtend = _minimumHitSize.height - bounds.size.height;
		bounds.size.height = _minimumHitSize.height;
	}
	
	if (widthExtend>0 || heightExtend>0)
	{
		self.contentEdgeInsets = UIEdgeInsetsMake(heightExtend/2.0f, widthExtend/2.0f, heightExtend/2.0f, widthExtend/2.0f);
		self.bounds = bounds;
	}
	else
	{
		self.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
	}
}

#pragma mark Notifications
- (void)highlightNotification:(NSNotification *)notification
{
	if ([notification object] == self)
	{
		// that was me
		return;
	}
	
	NSDictionary *userInfo = [notification userInfo];
	
	NSString *guid = [userInfo objectForKey:@"GUID"];
	
	if ([guid isEqualToString:_GUID])
	{
		BOOL highlighted = [[userInfo objectForKey:@"Highlighted"] boolValue];
		[super setHighlighted:highlighted];
		[self setNeedsDisplay];
	}
}



#pragma mark Properties

- (void)setHighlighted:(BOOL)highlighted
{
	[super setHighlighted:highlighted];
	[self setNeedsDisplay];
	
	
	// notify other parts of the same link
	if (_GUID)
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:highlighted], @"Highlighted", _GUID, @"GUID", nil];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DTLinkButtonDidHighlightNotification object:self userInfo:userInfo];
	}
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	if (CGRectIsEmpty(frame))
	{
		return;
	}
	
	[self adjustBoundsIfNecessary];
}


- (void)setMinimumHitSize:(CGSize)minimumHitSize
{
	if (CGSizeEqualToSize(_minimumHitSize, minimumHitSize))
	{
		return;
	}
	
	_minimumHitSize = minimumHitSize;
	
	[self adjustBoundsIfNecessary];
}

@synthesize URL = _URL;
@synthesize GUID = _GUID;

@synthesize minimumHitSize = _minimumHitSize;
@synthesize showsTouchWhenHighlighted = _showsTouchWhenHighlighted;

@synthesize attributedString = _attributedString;
@synthesize highlightedAttributedString = _highlightedAttributedString;

@end
