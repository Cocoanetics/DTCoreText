//
//  DemoWebVideoView.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DemoWebVideoView.h"

@import DTCoreTextSwift;

@interface DemoWebVideoView ()

- (void)disableScrolling;

@end


@implementation DemoWebVideoView
{
	DTTextAttachment *_attachment;
	
	__weak id <DemoWebVideoViewDelegate> _delegate;
	
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

	// Allow the initial about:blank / loadHTMLString navigation and any
	// iframe-scoped subframe requests. Without this, YouTube's own
	// cookie/consent redirects bounce out to Safari and the embed
	// never loads.
	if (navigationAction.targetFrame != nil && !navigationAction.targetFrame.mainFrame)
	{
		decisionHandler(WKNavigationActionPolicyAllow);
		return;
	}

	NSString *scheme = request.URL.scheme.lowercaseString;
	if ([scheme isEqualToString:@"about"] || request.URL.absoluteString.length == 0)
	{
		decisionHandler(WKNavigationActionPolicyAllow);
		return;
	}

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

	// Only top-level user-initiated link clicks should escape to Safari.
	if (navigationAction.navigationType != WKNavigationTypeLinkActivated)
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
			// Loading the YouTube embed URL as the top-level document in
			// WKWebView makes YouTube's IFrame player report a "Video player
			// configuration error" because it expects to be hosted inside an
			// actual <iframe> in a page. Wrap the URL in a minimal HTML
			// document that embeds it via <iframe> and give the WKWebView a
			// plausible https:// baseURL so referer checks succeed.
			NSString *src = attachment.contentURL.absoluteString ?: @"";
			NSString *html = [NSString stringWithFormat:
				@"<!doctype html><html><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><style>html,body{margin:0;padding:0;background:#000;height:100%%;}iframe{border:0;width:100%%;height:100%%;display:block;}</style></head><body><iframe src=\"%@\" frameborder=\"0\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share\" allowfullscreen></iframe></body></html>",
				src];
			// Use a non-YouTube baseURL so the iframe request carries a
			// legitimate cross-origin Referer; YouTube rejects same-origin
			// embed requests from the bare embed page.
			NSURL *baseURL = [NSURL URLWithString:@"https://cocoanetics.com/"];
			[_webView loadHTMLString:html baseURL:baseURL];
		}
	}
}

@synthesize delegate = _delegate;
@synthesize attachment = _attachment;

@end
