//
//  DemoWebVideoView.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoWebVideoView.h"
#import "DTIframeTextAttachment.h"

@interface DemoWebVideoView ()

- (void)disableScrolling;

@end


@implementation DemoWebVideoView
{
	DTTextAttachment *_attachment;
	
	DT_WEAK_VARIABLE id <DemoWebVideoViewDelegate> _delegate;
	
	WKWebView *_webView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.userInteractionEnabled = YES;
		
		_webView = [[WKWebView alloc] initWithFrame:self.bounds];
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_webView];
		
		[self disableScrolling];
		
		_webView.navigationDelegate = self;
    }
    return self;
}

- (void)dealloc
{
	_webView.navigationDelegate = nil;
	
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

#pragma mark WKWebViewDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	NSURLRequest *request = navigationAction.request;

	// allow the embed request for YouTube
	if (NSNotFound != [[[request URL] absoluteString] rangeOfString:@"www.youtube.com/embed/"].location)
	{
		decisionHandler(WKNavigationActionPolicyAllow);
		return;
	}

	// allow the embed request for DailyMotion Cloud
	if (NSNotFound != [[[request URL] absoluteString] rangeOfString:@"api.dmcloud.net/player/embed/"].location)
	{
		decisionHandler(WKNavigationActionPolicyAllow);
		return;
	}

	BOOL shouldOpenExternalURL = YES;
	
	if ([_delegate respondsToSelector:@selector(videoView:shouldOpenExternalURL:)])
	{
		shouldOpenExternalURL = [_delegate videoView:self shouldOpenExternalURL:[request URL]];
	}
	
#if !defined(DT_APP_EXTENSIONS)
	if (shouldOpenExternalURL)
	{
		if (@available(iOS 10.0, *)) {
			[[UIApplication sharedApplication] openURL:[request URL] options:@{} completionHandler:nil];
		} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			[[UIApplication sharedApplication] openURL:[request URL]];
#pragma clang diagnostic pop
		}
	}
#endif
	
	decisionHandler(WKNavigationActionPolicyCancel);
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
