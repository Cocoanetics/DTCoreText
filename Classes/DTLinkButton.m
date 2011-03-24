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
    self = [super initWithFrame:frame];
	if (self)
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightNotification:) name:@"DTLinkButtonDidHighlight" object:nil];
	}
	
	
	return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    
    // notify other parts of the same link
    if (_guid)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:highlighted], @"Highlighted", _guid, @"GUID", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DTLinkButtonDidHighlight" object:self userInfo:userInfo];
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[_url release];
    [_guid release];
	
	[super dealloc];
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
    
    if ([guid isEqualToString:_guid])
    {
        BOOL highlighted = [[userInfo objectForKey:@"Highlighted"] boolValue];
        [super setHighlighted:highlighted];
    }
}


#pragma mark Properties

@synthesize url = _url;
@synthesize guid = _guid;

@end
