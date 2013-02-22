//
//  DTLinkButton.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTLinkButton.h"
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
	
	// highlighted text
	NSAttributedString *_highlightedAttributedString;
	DTCoreTextLayoutLine *_highlightedLine;
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

- (DTCoreTextLayoutLine *)_normalLine
{
	if (!_normalLine && _attributedString)
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
	}
	
	return _normalLine;
}

- (DTCoreTextLayoutLine *)_highlightedLine
{
	if (!_highlightedLine && _highlightedAttributedString)
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
	}
	
	return _highlightedLine;
}

- (void)drawTextInContext:(CGContextRef)context highlighted:(BOOL)highlighted
{
	DTCoreTextLayoutLine *lineToDraw = nil;
	
	if (highlighted)
	{
		// use highlighted glyph run
		lineToDraw = [self _highlightedLine];
	}
	else
	{
		// use normal glyph run
		lineToDraw = [self _normalLine];
	}
	
	if (!lineToDraw)
	{
		return;
	}
	
	
	for (DTCoreTextGlyphRun *glyphRunToDraw in lineToDraw.glyphRuns)
	{
		if ([glyphRunToDraw isTrailingWhitespace])
		{
			continue;
		}
		
		CGContextSaveGState(context);
		
		NSDictionary *runAttributes = glyphRunToDraw.attributes;
		
		NSInteger superscriptStyle = [[runAttributes objectForKey:(id)kCTSuperscriptAttributeName] integerValue];

		// -------------- Line-Out, Underline, Background-Color
		BOOL drawStrikeOut = [[runAttributes objectForKey:DTStrikeOutAttribute] boolValue];
		BOOL drawUnderline = [[runAttributes objectForKey:(id)kCTUnderlineStyleAttributeName] boolValue];
		
		CGColorRef backgroundColor = (__bridge CGColorRef)[runAttributes objectForKey:DTBackgroundColorAttribute];
		
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
		if (!backgroundColor&&___useiOS6Attributes)
		{
			// could also be the iOS 6 background color
			DTColor *color = [runAttributes objectForKey:NSBackgroundColorAttributeName];
			backgroundColor = color.CGColor;
		}
#endif
		
		if (drawStrikeOut||drawUnderline||backgroundColor)
		{
			// get text color or use black
			CGColorRef foregroundColor = (__bridge CGColorRef)[runAttributes objectForKey:(id)kCTForegroundColorAttributeName];
			
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_5_1
			// could also be an iOS 6 attribute
			if (!foregroundColor&&___useiOS6Attributes)
			{
				// could also be the iOS 6 background color
				DTColor *color = [runAttributes objectForKey:NSBackgroundColorAttributeName];
				foregroundColor = color.CGColor;
			}
#endif
			
			if (foregroundColor)
			{
				CGContextSetStrokeColorWithColor(context, foregroundColor);
			}
			else
			{
				CGContextSetGrayStrokeColor(context, 0, 1.0);
			}
			
			CGRect runStrokeBounds = UIEdgeInsetsInsetRect(self.bounds, self.contentEdgeInsets);
			runStrokeBounds.origin.x = glyphRunToDraw.frame.origin.x + self.contentEdgeInsets.left;
			runStrokeBounds.size.width = glyphRunToDraw.frame.size.width;
			
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
			
			if (backgroundColor)
			{
				CGContextSetFillColorWithColor(context, backgroundColor);
				CGContextFillRect(context, runStrokeBounds);
			}
			
			if (drawStrikeOut)
			{
				CGFloat y = roundf(runStrokeBounds.origin.y + glyphRunToDraw.frame.size.height/2.0f + 1)+0.5f;
				
				CGContextMoveToPoint(context, runStrokeBounds.origin.x, y);
				CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, y);
				
				CGContextStrokePath(context);
			}
			
			if (drawUnderline)
			{
				CGFloat y = roundf(runStrokeBounds.origin.y + runStrokeBounds.size.height - glyphRunToDraw.descent + 1)+0.5f;
				
				CGContextMoveToPoint(context, runStrokeBounds.origin.x, y);
				CGContextAddLineToPoint(context, runStrokeBounds.origin.x + runStrokeBounds.size.width, y);
				
				CGContextStrokePath(context);
			}
		}
		
		// Flip the coordinate system
		CGContextSetTextMatrix(context, CGAffineTransformIdentity);
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextTranslateCTM(context, 0, -self.bounds.size.height);
		
		CGPoint textPosition = CGPointMake(self.contentEdgeInsets.left, ceilf(glyphRunToDraw.descent+self.contentEdgeInsets.bottom));
		
		switch (superscriptStyle)
		{
			case 1:
			{
				textPosition.y += glyphRunToDraw.ascent * 0.47f;
				break;
			}
			case -1:
			{
				textPosition.y -= glyphRunToDraw.ascent * 0.25f;
				break;
			}
			default:
				break;
		}
		
		CGContextSetTextPosition(context, textPosition.x, textPosition.y);
		
		[glyphRunToDraw drawInContext:context];
		CGContextRestoreGState(context);
	}
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

- (void)_adjustBoundsIfNecessary
{
	CGRect bounds = self.bounds;
	CGFloat widthExtend = 0;
	CGFloat heightExtend = 0;
	
	if (bounds.size.width < _minimumHitSize.width)
	{
		widthExtend = _minimumHitSize.width - bounds.size.width;
	}
	
	if (bounds.size.height < _minimumHitSize.height)
	{
		heightExtend = _minimumHitSize.height - bounds.size.height;
	}
	
	if (widthExtend>0 || heightExtend>0)
	{
		UIEdgeInsets edgeInsets = UIEdgeInsetsMake(ceilf(heightExtend/2.0f), ceilf(widthExtend/2.0f), ceilf(heightExtend/2.0f), ceilf(widthExtend/2.0f));
		
		// extend bounds by the calculated necessary edge insets
		bounds.size.width += edgeInsets.left + edgeInsets.right;
		bounds.size.height += edgeInsets.top + edgeInsets.bottom;

		// apply bounds and insets
		self.bounds = bounds;
		self.contentEdgeInsets = edgeInsets;
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
	
	[self _adjustBoundsIfNecessary];
}


- (void)setMinimumHitSize:(CGSize)minimumHitSize
{
	if (CGSizeEqualToSize(_minimumHitSize, minimumHitSize))
	{
		return;
	}
	
	_minimumHitSize = minimumHitSize;
	
	[self _adjustBoundsIfNecessary];
}

@synthesize URL = _URL;
@synthesize GUID = _GUID;

@synthesize minimumHitSize = _minimumHitSize;
@synthesize showsTouchWhenHighlighted = _showsTouchWhenHighlighted;

@synthesize attributedString = _attributedString;
@synthesize highlightedAttributedString = _highlightedAttributedString;

@end
