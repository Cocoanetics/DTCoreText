//
//  DTWebVideoView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DTTextAttachment;
@class DTWebVideoView;

@protocol DTWebVideoViewDelegate <NSObject>

@optional
- (BOOL)videoView:(DTWebVideoView *)videoView shouldOpenExternalURL:(NSURL *)url;

@end


@interface DTWebVideoView : UIView <UIWebViewDelegate>
{
	DTTextAttachment *_attachment;
	
	id <DTWebVideoViewDelegate> _delegate;
	
	UIWebView *_webView;
}

@property (nonatomic, assign) id <DTWebVideoViewDelegate> delegate;
@property (nonatomic, retain) DTTextAttachment *attachment;



@end
