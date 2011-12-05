//
//  DTWebVideoView.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTWebVideoView.h"
#import "DTTextAttachment.h"


@interface DTWebVideoView ()

- (void)disableScrolling;

@end


@implementation DTWebVideoView
{
	DTTextAttachment *_attachment;
	
	__unsafe_unretained id <DTWebVideoViewDelegate> _delegate;
	
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
	// only allow the embed request
	if ([[[request URL] absoluteString] hasPrefix:@"http://www.youtube.com/embed/"])
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
	}
	
	switch (attachment.contentType) 
	{
		case DTTextAttachmentTypeIframe:
		{
			NSURLRequest *request = [NSURLRequest requestWithURL:attachment.contentURL];
			[_webView loadRequest:request];
			break;
		}
			
		default:
			break;
	}
}

@synthesize delegate = _delegate;
@synthesize attachment = _attachment;

@end
