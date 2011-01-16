//
//  DTLinkButton.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTLinkButton.h"
#import "CGUtils.h"
#import "UIColor+HTML.h"

@implementation DTLinkButton


- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.userInteractionEnabled = YES;
		self.enabled = YES;
		
		UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
		CGContextRef ctx = UIGraphicsGetCurrentContext();
		
		CGPathRef roundedRectPath = newPathForRoundedRect(self.bounds, 3.0, YES, YES);
		[[UIColor colorWithHTMLName:@"#BBBBBB"] set];
		CGContextAddPath(ctx, roundedRectPath);
		CGContextFillPath(ctx);
		UIImage *background = UIGraphicsGetImageFromCurrentImageContext();
		
		CGPathRelease(roundedRectPath);
		
		[self setBackgroundImage:background forState:UIControlStateHighlighted]; 
		
		UIGraphicsEndImageContext();
	}
	
	
	return self;
}

- (void)dealloc
{
	[_url release];
	
	[super dealloc];
}

@synthesize url = _url;

@end
