//
//  DTAttributedTextView.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DTAttributedTextView.h"
#import "DTCoreText.h"
#import "DTBlockFunctions.h"

#import <DTFoundation/DTTiledLayerWithoutFade.h>


@interface DTAttributedTextView ()

- (void)_setup;

@end



@implementation DTAttributedTextView
{
	UIView *_backgroundView;

	// these are pass-through, i.e. store until the content view is created
	DT_WEAK_VARIABLE id textDelegate;
	NSAttributedString *_attributedString;
	
	BOOL _shouldDrawLinks;
	BOOL _shouldDrawImages;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
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

- (void)layoutSubviews
{
	(void)[self attributedTextContentView];
	
	// layout custom subviews for visible area
	[_attributedTextContentView layoutSubviewsInRect:self.bounds];
  
  [super layoutSubviews];
}

- (void)awakeFromNib
{
	[super awakeFromNib];
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
	self.clipsToBounds = YES;
	
	// defaults
	_shouldDrawLinks = YES;
	_shouldDrawImages = YES;
}

// override class e.g. for mutable content view
- (Class)classForContentView
{
	return [DTAttributedTextContentView class];
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
	[self setContentOffset:CGPointMake(0, scrollPos) animated:animated];
}

- (void)relayoutText
{
	DTBlockPerformSyncIfOnMainThreadElseAsync(^{
		
		// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
		_attributedTextContentView.layouter=nil;
		
		// here we're layouting the entire string, might be more efficient to only relayout the paragraphs that contain these attachments
		[_attributedTextContentView relayoutText];
		
		// layout custom subviews for visible area
		[self setNeedsLayout];
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
		CGRect optimalFrame = [[userInfo objectForKey:@"OptimalFrame"] CGRectValue];
		
		CGRect frame = UIEdgeInsetsInsetRect(self.bounds, self.contentInset);
		
		// ignore possibly delayed layout notification for a different width
		if (optimalFrame.size.width == frame.size.width)
		{
			_attributedTextContentView.frame = optimalFrame;
			self.contentSize = [_attributedTextContentView intrinsicContentSize];
		}
	});
}

#pragma mark Properties
- (DTAttributedTextContentView *)attributedTextContentView
{
	if (!_attributedTextContentView)
	{
		// subclasses can specify a DTAttributedTextContentView subclass instead
		Class classToUse = [self classForContentView];
		
		CGRect frame = UIEdgeInsetsInsetRect(self.bounds, self.contentInset);
		
		if (frame.size.width<=0 || frame.size.height<=0)
		{
			frame = CGRectZero;
		}
		
		// make sure we always have a tiled layer
		Class previousLayerClass = nil;
		
		// for DTAttributedTextContentView subclasses we force a tiled layer
		if ([classToUse isSubclassOfClass:[DTAttributedTextContentView class]])
		{
			Class layerClass = [DTAttributedTextContentView layerClass];
			
			if (![layerClass isSubclassOfClass:[CATiledLayer class]])
			{
				[DTAttributedTextContentView setLayerClass:[DTTiledLayerWithoutFade class]];
				previousLayerClass = layerClass;
			}
		}
		
		_attributedTextContentView = [[classToUse alloc] initWithFrame:frame];
		
		// restore previous layer class if we changed the layer class for the content view
		if (previousLayerClass)
		{
			[DTAttributedTextContentView setLayerClass:previousLayerClass];
		}
		
		_attributedTextContentView.userInteractionEnabled = YES;
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewDidLayout:) name:DTAttributedTextContentViewDidFinishLayoutNotification object:_attributedTextContentView];

		// temporary frame to specify the width
		_attributedTextContentView.frame = frame;
		
		// set text we previously got, this also triggers a relayout
		_attributedTextContentView.attributedString = _attributedString;

		// this causes a relayout and the resulting notification will allow us to set the final frame
		
		[self addSubview:_attributedTextContentView];
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

- (void)setContentInset:(UIEdgeInsets)contentInset
{
	if (!UIEdgeInsetsEqualToEdgeInsets(self.contentInset, contentInset))
	{
		[super setContentInset:contentInset];
		
		// height does not matter, that will be determined anyhow
		CGRect contentFrame = CGRectMake(0, 0, self.frame.size.width - self.contentInset.left - self.contentInset.right, _attributedTextContentView.frame.size.height);
		
		_attributedTextContentView.frame = contentFrame;
	}
}

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

- (void)setAttributedString:(NSAttributedString *)string
{
	_attributedString = string;

	// might need layout for visible custom views
	[self setNeedsLayout];

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

- (void)setTextDelegate:(id<DTAttributedTextContentViewDelegate>)aTextDelegate
{
	// store unsafe pointer to delegate because we might not have a contentView yet
	textDelegate = aTextDelegate;
	
	// set it if possible, otherwise it will be set in contentView lazy property
	_attributedTextContentView.delegate = aTextDelegate;
}

- (id<DTAttributedTextContentViewDelegate>)textDelegate
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
