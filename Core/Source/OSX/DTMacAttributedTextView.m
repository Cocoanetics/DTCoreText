//
//  DTAttributedTextView.m
//  DTCoreText
//
//  Created by Michael Markowski on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DTMacAttributedTextView.h"
#import "DTCoreText.h"
//#import "DTTiledLayerWithoutFade.h"
#import "DTBlockFunctions.h"

@interface DTMacAttributedTextView ()

- (void)_setup;

@end

#define DT_MACPORT_FEATURE_BACKGROUNDVIEW_IMPLEMENTED 0

@implementation DTMacAttributedTextView
{
	NSView *_backgroundView;
	
	// these are pass-through, i.e. store until the content view is created
	DT_WEAK_VARIABLE id textDelegate;
	NSAttributedString *_attributedString;
	
	BOOL _shouldDrawLinks;
	BOOL _shouldDrawImages;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	self.backgroundColor = [DTColor clearColor];
	[self setDrawsBackground:NO];
	
	if (self)
	{
		[self _setup];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layout
{
	[super layout];
	
	[self attributedTextContentView];
	
	// layout custom subviews for visible area
	[_attributedTextContentView layoutSubviewsInRect:self.bounds];
}

- (void)awakeFromNib
{
	[self _setup];
}

// default
- (void)_setup
{
	if (self.backgroundColor)
	{
		CGFloat alpha = [self.backgroundColor alphaComponent];
		
		if (alpha < 1.0)
		{
			self.opaque = NO;
		}
		else
		{
			self.opaque = YES;
		}
	}
	else
	{
		self.backgroundColor = [DTColor whiteColor];
		self.opaque = YES;
	}
	
	self.autoresizesSubviews = NO;
//	self.clipsToBounds = YES; //TODO mm
	
	// defaults
	_shouldDrawLinks = YES;
	_shouldDrawImages = YES;
}

// override class e.g. for mutable content view
- (Class)classForContentView
{
	return [DTMacAttributedTextContentView class];
}

#pragma mark External Methods
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated
{
	NSRange range = [self.attributedTextContentView.attributedString rangeOfAnchorNamed:anchorName];
	
	if (range.location != NSNotFound)
	{
		[self scrollRangeToVisible:range animated:animated];
	}
}

- (void)scrollRangeToVisible:(NSRange)range animated:(BOOL)animated
{
	// get the line of the first index of the anchor range
	DTCoreTextLayoutLine *line = [self.attributedTextContentView.layoutFrame lineContainingIndex:range.location];
	
	// make sure we don't scroll too far
	CGFloat maxScrollPos = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + self.contentInset.top;
	CGFloat scrollPos = MIN(line.frame.origin.y, maxScrollPos);
	
	// scroll
	// TODO mm - animations
	[self scrollPoint:CGPointMake(0, scrollPos)];
	// maybe     [[self.scrollView contentView] scrollToPoint:CGPointMake(0, scrollPos)]; ?
}

- (void)relayoutText
{
	DTBlockPerformSyncIfOnMainThreadElseAsync(^{
		
		// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
		_attributedTextContentView.layouter=nil;
		
		// here we're layouting the entire string, might be more efficient to only relayout the paragraphs that contain these attachments
		[_attributedTextContentView relayoutText];
		
		// layout custom subviews for visible area
		[self setNeedsLayout:YES];
	});
}

#pragma mark - Working with a Cursor

- (NSInteger)closestCursorIndexToPoint:(CGPoint)point
{
	// the point is in the coordinate system of the receiver, need to convert into those of the content view first
	CGPoint pointInContentView = [self.attributedTextContentView convertPoint:point fromView:self];
	
	return [self.attributedTextContentView closestCursorIndexToPoint:pointInContentView];
}

- (CGRect)cursorRectAtIndex:(NSInteger)index
{
	CGRect rectInContentView = [self.attributedTextContentView cursorRectAtIndex:index];
	
	// the point is in the coordinate system of the content view, need to convert into those of the receiver first
	CGRect rect = [self.attributedTextContentView convertRect:rectInContentView toView:self];
	
	return rect;
}

#pragma mark Notifications
- (void)contentViewDidLayout:(NSNotification *)notification
{
	DTBlockPerformSyncIfOnMainThreadElseAsync(^{
		
		NSDictionary *userInfo = [notification userInfo];
		CGRect optimalFrame = [[userInfo objectForKey:@"OptimalFrame"] rectValue];
		
		CGRect frame = DTEdgeInsetsInsetRect(self.bounds, self.contentInset);
		
		// ignore possibly delayed layout notification for a different width
		if (optimalFrame.size.width == frame.size.width)
		{
			CGRect contentFrame = optimalFrame;
			contentFrame.size = [_attributedTextContentView intrinsicContentSize];
			[_attributedTextContentView setFrame:contentFrame];
		}
	});
}

#pragma mark Properties
- (DTMacAttributedTextContentView *)attributedTextContentView
{
	if (!_attributedTextContentView)
	{
		// subclasses can specify a DTAttributedTextContentView subclass instead
		Class classToUse = [self classForContentView];

		CGRect frame = DTEdgeInsetsInsetRect(self.bounds, self.contentInset);
		
		if (frame.size.width<=0 || frame.size.height<=0)
		{
			frame = CGRectZero;
		}
		
#if DT_MACPORT_FEATURE_LAYERCLASS_IMPLEMENTED
		// make sure we always have a tiled layer
		Class previousLayerClass = nil;

		// for DTAttributedTextContentView subclasses we force a tiled layer
		if ([classToUse isSubclassOfClass:[DTMacAttributedTextContentView class]])
		{
			Class layerClass = [DTMacAttributedTextContentView layerClass];
			
			if (![layerClass isSubclassOfClass:[CATiledLayer class]])
			{
				[DTMacAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];
				previousLayerClass = layerClass;
			}
		}
#endif
		
		_attributedTextContentView = [[classToUse alloc] initWithFrame:self.bounds];
		_attributedTextContentView.wantsLayer = self.wantsLayer;
		
#if DT_MACPORT_FEATURE_LAYERCLASS_IMPLEMENTED
		// restore previous layer class if we changed the layer class for the content view
		if (previousLayerClass)
		{
			[DTMacAttributedTextContentView setLayerClass:previousLayerClass];
		}
#endif
		_attributedTextContentView.backgroundColor = self.backgroundColor;
		_attributedTextContentView.shouldLayoutCustomSubviews = NO; // we call layout when scrolling
		
		// adjust opaqueness based on background color alpha
		CGFloat alpha = [self.backgroundColor alphaComponent];
		
		if (alpha < 1.0)
		{
			_attributedTextContentView.opaque = NO;
		}
		else
		{
			_attributedTextContentView.opaque = YES;
		}
		
		// set text delegate if it was set before instantiation of content view
		_attributedTextContentView.delegate = textDelegate;
		
		// pass on setting
		_attributedTextContentView.shouldDrawLinks = _shouldDrawLinks;
		
		// notification that tells us about the actual size of the content view
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewDidLayout:) name:DTMacAttributedTextContentViewDidFinishLayoutNotification object:_attributedTextContentView];
		
		// temporary frame to specify the width
		_attributedTextContentView.frame = frame;
		
		// set text we previously got, this also triggers a relayout
		_attributedTextContentView.attributedString = _attributedString;
		
		// this causes a relayout and the resulting notification will allow us to set the final frame
		
		[self setDocumentView:_attributedTextContentView];
	}
	
	return _attributedTextContentView;
}

- (void)setBackgroundColor:(DTColor *)newColor
{
	if ([newColor alphaComponent]<1.0)
	{
		super.backgroundColor = newColor;
		_attributedTextContentView.backgroundColor = [DTColor clearColor];
		self.opaque = NO;
	}
	else
	{
		super.backgroundColor = newColor;
		
		if (_attributedTextContentView.opaque)
		{
			_attributedTextContentView.backgroundColor = newColor;
		}
	}
}


- (void)setContentInset:(DTEdgeInsets)contentInset
{
	if (!DTEdgeInsetsEqualToEdgeInsets(self.contentInset, contentInset))
	{
		
		// height does not matter, that will be determined anyhow
		CGRect contentFrame = CGRectMake(0, 0, self.frame.size.width - self.contentInset.left - self.contentInset.right, _attributedTextContentView.frame.size.height);
		
		_attributedTextContentView.frame = contentFrame;
	}
}

#if DT_MACPORT_FEATURE_BACKGROUNDVIEW_IMPLEMENTED
- (UIView *)backgroundView
{
	if (!_backgroundView)
	{
		_backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		_backgroundView.backgroundColor	= [DTColor whiteColor];
		
		// default is no interaction because background should have no interaction
		_backgroundView.userInteractionEnabled = NO;
		
		[self insertSubview:_backgroundView belowSubview:self.attributedTextContentView];
		
		// make content transparent so that we see the background
		_attributedTextContentView.backgroundColor = [DTColor clearColor];
		_attributedTextContentView.opaque = NO;
	}
	
	return _backgroundView;
}

- (void)setBackgroundView:(UIView *)backgroundView
{
	if (_backgroundView != backgroundView)
	{
		[_backgroundView removeFromSuperview];
		_backgroundView = backgroundView;
		
		if (_attributedTextContentView)
		{
			[self insertSubview:_backgroundView belowSubview:_attributedTextContentView];
		}
		else
		{
			[self addSubview:_backgroundView];
		}
		
		if (_backgroundView)
		{
			// make content transparent so that we see the background
			_attributedTextContentView.backgroundColor = [DTColor clearColor];
			_attributedTextContentView.opaque = NO;
		}
		else
		{
			_attributedTextContentView.backgroundColor = [DTColor whiteColor];
			_attributedTextContentView.opaque = YES;
		}
	}
}
#endif

- (void)setAttributedString:(NSAttributedString *)string
{
	_attributedString = string;
	
	// might need layout for visible custom views
	[self setNeedsLayout:YES];
	
	if (_attributedTextContentView)
	{
		// pass it along if contentView already exists
		_attributedTextContentView.attributedString = string;
		
		// this causes a relayout and the resulting notification will allow us to set the frame and contentSize
	}
}

- (NSAttributedString *)attributedString
{
	return _attributedString;
}

- (void)setFrame:(CGRect)frame
{
	CGRect oldFrame = self.frame;
	
	if (!CGRectEqualToRect(oldFrame, frame))
	{
		[super setFrame:frame]; // need to set own frame first because layout completion needs this updated frame
		
		if (oldFrame.size.width != frame.size.width)
		{
			// height does not matter, that will be determined anyhow
			CGRect contentFrame = CGRectMake(0, 0, frame.size.width - self.contentInset.left - self.contentInset.right, _attributedTextContentView.frame.size.height);
			
			_attributedTextContentView.frame = contentFrame;
		}
	}
}

- (void)setTextDelegate:(id<DTMacAttributedTextContentViewDelegate>)aTextDelegate
{
	// store unsafe pointer to delegate because we might not have a contentView yet
	textDelegate = aTextDelegate;
	
	// set it if possible, otherwise it will be set in contentView lazy property
	_attributedTextContentView.delegate = aTextDelegate;
}

- (id<DTMacAttributedTextContentViewDelegate>)textDelegate
{
	return _attributedTextContentView.delegate;
}

- (void)setShouldDrawLinks:(BOOL)shouldDrawLinks
{
	_shouldDrawLinks = shouldDrawLinks;
	_attributedTextContentView.shouldDrawLinks = _shouldDrawLinks;
}

- (void)setShouldDrawImages:(BOOL)shouldDrawImages
{
	_shouldDrawImages = shouldDrawImages;
	_attributedTextContentView.shouldDrawImages = _shouldDrawImages;
}

@synthesize attributedTextContentView = _attributedTextContentView;
@synthesize attributedString = _attributedString;
@synthesize textDelegate = _textDelegate;

@synthesize shouldDrawLinks = _shouldDrawLinks;

@end
