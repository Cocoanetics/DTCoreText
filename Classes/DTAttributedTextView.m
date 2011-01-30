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
	if (self = [super initWithFrame:frame])
	{
		[self setup];
	}
	
	return self;
}

- (void)dealloc 
{
	[contentView release];
    [super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.contentView; // Trigger adding if not happened
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

#pragma mark Properties
- (DTAttributedTextContentView *)contentView
{
	if (!contentView)
	{
		contentView = [[DTAttributedTextContentView alloc] initWithFrame:self.bounds];
		contentView.parentView = self;
		contentView.userInteractionEnabled = YES;
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
		contentView.opaque = NO;
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
	
	[self.contentView sizeToFit];
	
	self.contentSize = contentView.bounds.size;
}

- (NSAttributedString *)attributedString
{
	return self.contentView.attributedString;
}


- (void)setFrame:(CGRect)newFrame
{
	if (!CGRectEqualToRect(self.frame, newFrame))
	{
		// TODO: Is there a way to animate content?
		// if this is not here then the content jumps 
		[self setContentOffset:CGPointZero];
		
		CGFloat previousWidth = self.bounds.size.width;
		
		[super setFrame:newFrame];
		
		if (previousWidth!=newFrame.size.width)
		{
			CGSize size = [contentView sizeThatFits:CGSizeMake(newFrame.size.width, 0)];
			
			contentView.frame = CGRectMake(0,0,size.width, size.height);
		}
	
		// always set the content size
		self.contentSize = contentView.bounds.size;

	}
}

/*
 - (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
 {
 UIView *hitView = [super hitTest:point withEvent:event];
 NSLog(@"%@", hitView);
 return hitView;
 }
 */

@synthesize attributedString;
@synthesize contentView;


@synthesize textDelegate;

@end
