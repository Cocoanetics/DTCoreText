//
//  DTWebVideoView.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 8/5/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



@class DTTextAttachment;
@class DTWebVideoView;

@protocol DTWebVideoViewDelegate <NSObject>

@optional
- (BOOL)videoView:(DTWebVideoView *)videoView shouldOpenExternalURL:(NSURL *)url;

@end


@interface DTWebVideoView : UIView <UIWebViewDelegate>

@property (nonatomic, assign) id <DTWebVideoViewDelegate> delegate; 	// subtle simulator bug - use assign not __unsafe_unretained
@property (nonatomic, strong) DTTextAttachment *attachment;

@end
