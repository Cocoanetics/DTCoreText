//
//  DTWebVideoView.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"

@interface DTWebVideoView ()

- (void)disableScrolling;

@end


@implementation DTWebVideoView
{
	DTTextAttachment *_attachment;
	
	DT_WEAK_VARIABLE id <DTWebVideoViewDelegate> _delegate;
	
	UIWebView *_webView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.userInteractionEnabled = YES;
		
		_webView = [[UIWebView alloc] initWithFrame:self.bounds];
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_webView];
		
		[self disableScrolling];
		
		_webView.delegate = self;
		
		if ([_webView respondsToSelector:@selector(setAllowsInlineMediaPlayback:)])
		{
			_webView.allowsInlineMediaPlayback = YES;
		}
    }
    return self;
}

- (void)dealloc
{
	_webView.delegate = nil;
	
}


- (void)disableScrolling
{
	// find scrollview and disable scrolling
	for (UIView *oneView in _webView.subviews)
	{
		if ([oneView isKindOfClass:[UIScrollView class]])
		{
			UIScrollView *scrollView = (id)oneView;
			
			scrollView.scrollEnabled = NO;
			scrollView.bounces = NO;
			
			return;
		}
	}	
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	// allow the embed request for YouTube
	if (NSNotFound != [[[request URL] absoluteString] rangeOfString:@"www.youtube.com/embed/"].location)
	{
		return YES;
	}

	// allow the embed request for DailyMotion Cloud
	if (NSNotFound != [[[request URL] absoluteString] rangeOfString:@"api.dmcloud.net/player/embed/"].location)
	{
		return YES;
	}

	BOOL shouldOpenExternalURL = YES;
	
	if ([_delegate respondsToSelector:@selector(videoView:shouldOpenExternalURL:)])
	{
		shouldOpenExternalURL = [_delegate videoView:self shouldOpenExternalURL:[request URL]];
	}
	
	if (shouldOpenExternalURL)
	{
		[[UIApplication sharedApplication] openURL:[request URL]];
	}
	
	return NO;
}



#pragma mark Properties

- (void)setAttachment:(DTTextAttachment *)attachment
{
	if (_attachment != attachment)
	{
		
		_attachment = attachment;
		
		if ([attachment isKindOfClass:[DTIframeTextAttachment class]])
		{
			NSURLRequest *request = [NSURLRequest requestWithURL:attachment.contentURL];
			[_webView loadRequest:request];
		}
	}
}

@synthesize delegate = _delegate;
@synthesize attachment = _attachment;

@end
