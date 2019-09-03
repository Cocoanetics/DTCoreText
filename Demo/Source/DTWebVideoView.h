//
//  DTWebVideoView.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <DTFoundation/DTWeakSupport.h>

@class DTWebVideoView;
@class DTTextAttachment;

/**
 Protocol for delegates of <DTWebVideoView>
*/
@protocol DTWebVideoViewDelegate <NSObject>

@optional

/**
 Asks the delegate if an external URL may be opened
 @param videoView The web video view
 @param url The external URL that is asked to be opened
 @returns `YES` if the app may be left to open the external URL
 */

- (BOOL)videoView:(DTWebVideoView *)videoView shouldOpenExternalURL:(NSURL *)url;

@end


/**
 The class represents a custom subview for use in <DTAttributedTextContentView> to represent an embedded video.
 
 Embedded videos work by loading the video URL in a UIWebView which iOS then replaces with the built-in media player view. The URL of the embed script depends on the service and needs to be added to the webView:shouldStartLoadWithRequest:navigationType:. You want to allow the URL for the embed script, but disallow all other requests which for example occur if a user taps on the YouTube logo. If you were to allow this type of navigation then the YouTube website would be loaded in the video view. For these scenarios there is the videoView:shouldOpenExternalURL: method in DTWebVideoViewDelegate. If you respond with `YES` (which is default if the method is not implemented) then the URL will be opened in Safari.
 
 To add additional video services please add them in the mentioned location and submit a pull request for the addition.
 */
@interface DTWebVideoView : UIView <UIWebViewDelegate>

/**
 The delegate of the video view
 */
@property (nonatomic, DT_WEAK_PROPERTY) id <DTWebVideoViewDelegate> delegate;

/**
 The text attachment representing an embedded video.
 */
@property (nonatomic, strong) DTTextAttachment *attachment;

@end
