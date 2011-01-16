//
//  DTAttributedTextView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextView.h"
#import "DTAttributedTextContentView.h"

@implementation DTAttributedTextView

- (void)layoutSubviews
{
	self.backgroundColor = [UIColor whiteColor];
	self.contentView; // Trigger adding if not happened
}


- (void)dealloc 
{
	[contentView release];
    [super dealloc];
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

- (void)setString:(NSAttributedString *)string
{
	self.contentView.string = string;
	self.contentSize = contentView.bounds.size;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *hitView = [super hitTest:point withEvent:event];
	NSLog(@"%@", hitView);
	return hitView;
}


@synthesize string;
@synthesize contentView;


@synthesize textDelegate;

@end
