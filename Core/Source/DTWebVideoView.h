//
//  DTWebVideoView.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTTextAttachment;
@class DTWebVideoView;

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
 */
@interface DTWebVideoView : UIView <UIWebViewDelegate>

/**
 The delegate of the video view
 */
@property (nonatomic, assign) id <DTWebVideoViewDelegate> delegate; 	// subtle simulator bug - use assign not __unsafe_unretained

/**
 The text attachment representing an embedded video.
 */
@property (nonatomic, strong) DTTextAttachment *attachment;

@end
