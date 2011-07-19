//
//  DTAttributedTextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextView.h"
#import "DTAttributedTextContentView.h"

#import "UIColor+HTML.h"

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
	[contentView removeObserver:self forKeyPath:@"frame"];
	[contentView release];
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if (!contentView)
	{
		[self addSubview:self.contentView];
	}
	
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
		self.backgroundColor = [UIColor whiteColor];
		self.opaque = YES;
		return;
	}
	
	CGFloat alpha = [self.backgroundColor alpha];
	
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
		contentView = [[DTAttributedTextContentView alloc] initWithFrame:self.bounds];
		contentView.userInteractionEnabled = YES;
		contentView.backgroundColor = self.backgroundColor;
		contentView.shouldLayoutCustomSubviews = NO; // we call layout when scrolling
		
		// we want to know if the frame changes so that we can adjust the scrollview content size
		[contentView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
		
		[self addSubview:contentView];
	}		
	
	return contentView;
}

- (void)setBackgroundColor:(UIColor *)newColor
{
	if ([newColor alpha]<1.0)
	{
		super.backgroundColor = newColor;
		contentView.backgroundColor = [UIColor clearColor];
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
		backgroundView.backgroundColor	= [UIColor whiteColor];
		//backgroundView.userInteractionEnabled = YES;
		//self.userInteractionEnabled = YES;
		[self insertSubview:backgroundView belowSubview:self.contentView];
		
		// make content transparent so that we see the background
		contentView.backgroundColor = [UIColor clearColor];
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
			contentView.backgroundColor = [UIColor clearColor];
			contentView.opaque = NO;
		}
		else 
		{
			contentView.backgroundColor = [UIColor whiteColor];
			contentView.opaque = YES;
		}
	}
}

- (void)setAttributedString:(NSAttributedString *)string
{
	self.contentView.attributedString = string;
	
	// contentView resizes itself after layout
	// self.contentSize is updated through KVO
}

- (NSAttributedString *)attributedString
{
	return self.contentView.attributedString;
}


- (void)setFrame:(CGRect)frame
{
	if (!CGRectEqualToRect(self.frame, frame))
	{
		[self setContentOffset:CGPointZero animated:YES];
		
		if (self.frame.size.width != frame.size.width)
		{
			contentView.frame = CGRectMake(0,0,frame.size.width, frame.size.height);
		}
		
		[super setFrame:frame];
	}
}

- (void)setTextDelegate:(id<DTAttributedTextContentViewDelegate>)textDelegate
{
	self.contentView.delegate = textDelegate;
}

- (id<DTAttributedTextContentViewDelegate>)textDelegate
{
	return contentView.delegate;
}

@synthesize attributedString;
@synthesize contentView;
@synthesize textDelegate;

@end
