//
//  DTAttributedTextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextView.h"
#import "DTCoreText.h"

@interface DTAttributedTextView ()

- (void)setup;

@end



@implementation DTAttributedTextView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		[self setup];
	}
	
	return self;
}

- (void)dealloc 
{
	contentView.delegate = nil;
	[contentView removeObserver:self forKeyPath:@"frame"];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self contentView];
	
	// layout custom subviews for visible area
	[contentView layoutSubviewsInRect:self.bounds];
}

- (void)awakeFromNib
{
	[self setup];
}

// default
- (void)setup
{
	if (!self.backgroundColor)
	{
		self.backgroundColor = [DTColor whiteColor];
		self.opaque = YES;
		return;
	}
	
	CGFloat alpha = [self.backgroundColor alphaComponent];
	
	if (alpha < 1.0)
	{
		self.opaque = NO;
		self.contentView.opaque = NO;
	}
	else 
	{
		self.opaque = YES;
		self.contentView.opaque = YES;
	}
	
	self.autoresizesSubviews = YES;
	self.clipsToBounds = YES;
}

// override class e.g. for mutable content view
- (Class)classForContentView
{
	return [DTAttributedTextContentView class];
}

#pragma mark External Methods
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated
{
	NSRange range = [self.contentView.attributedString rangeOfAnchorNamed:anchorName];
	
	if (range.length != NSNotFound)
	{
		// get the line of the first index of the anchor range
		DTCoreTextLayoutLine *line = [self.contentView.layoutFrame lineContainingIndex:range.location];
		
		// make sure we don't scroll too far
		CGFloat maxScrollPos = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + self.contentInset.top;
		CGFloat scrollPos = MIN(line.frame.origin.y, maxScrollPos);
		
		// scroll
		[self setContentOffset:CGPointMake(0, scrollPos) animated:animated];
	}
}

#pragma mark Notifications
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == contentView && [keyPath isEqualToString:@"frame"])
	{
		CGRect newFrame = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];
		self.contentSize = newFrame.size;
	}
}

#pragma mark Properties
- (DTAttributedTextContentView *)contentView
{
	if (!contentView)
	{
		// subclasses can specify a DTAttributedTextContentView subclass instead
		Class classToUse = [self classForContentView];
		
		contentView = [[classToUse alloc] initWithFrame:self.bounds];
		contentView.userInteractionEnabled = YES;
		contentView.backgroundColor = self.backgroundColor;
		contentView.shouldLayoutCustomSubviews = NO; // we call layout when scrolling
		
		// we want to know if the frame changes so that we can adjust the scrollview content size
		[contentView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
		
		[self addSubview:contentView];
	}		
	
	return contentView;
}

- (void)setBackgroundColor:(DTColor *)newColor
{
	if ([newColor alphaComponent]<1.0)
	{
		super.backgroundColor = newColor;
		contentView.backgroundColor = [DTColor clearColor];
		self.opaque = NO;
	}
	else 
	{
		super.backgroundColor = newColor;
		
		if (contentView.opaque)
		{
			contentView.backgroundColor = newColor;
		}
	}
}

- (UIView *)backgroundView
{
	if (!backgroundView)
	{
		backgroundView = [[UIView alloc] initWithFrame:self.bounds];
		backgroundView.backgroundColor	= [DTColor whiteColor];
		
		// default is no interaction because background should have no interaction
		backgroundView.userInteractionEnabled = NO;

		[self insertSubview:backgroundView belowSubview:self.contentView];
		
		// make content transparent so that we see the background
		contentView.backgroundColor = [DTColor clearColor];
		contentView.opaque = NO;
	}		
	
	return backgroundView;
}

- (void)setBackgroundView:(UIView *)newBackgroundView
{
	if (backgroundView != newBackgroundView)
	{
		[backgroundView removeFromSuperview];
		backgroundView = newBackgroundView;
		
		[self insertSubview:backgroundView belowSubview:self.contentView];
		
		if (backgroundView)
		{
			// make content transparent so that we see the background
			contentView.backgroundColor = [DTColor clearColor];
			contentView.opaque = NO;
		}
		else 
		{
			contentView.backgroundColor = [DTColor whiteColor];
			contentView.opaque = YES;
		}
	}
}

- (void)setAttributedString:(NSAttributedString *)string
{
	self.contentView.attributedString = string;
	
	// might need layout for visible custom views
	[self setNeedsLayout];

	// adjust content size right away
	self.contentSize = self.contentView.frame.size;
}

- (NSAttributedString *)attributedString
{
	return self.contentView.attributedString;
}


- (void)setFrame:(CGRect)frame
{
	if (!CGRectEqualToRect(self.frame, frame))
	{
		if (self.frame.size.width != frame.size.width)
		{
			contentView.frame = CGRectMake(0,0,frame.size.width, frame.size.height);
		}
		[super setFrame:frame];
	}
}

- (void)setTextDelegate:(id<DTAttributedTextContentViewDelegate>)aTextDelegate
{
	self.contentView.delegate = aTextDelegate;
}

- (id<DTAttributedTextContentViewDelegate>)textDelegate
{
	return contentView.delegate;
}

@synthesize attributedString;
@synthesize contentView;
@synthesize textDelegate;

@end
