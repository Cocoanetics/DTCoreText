//
//  DTLazyImageView.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 5/20/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <DTFoundation/DTWeakSupport.h>
#import "DTAttributedTextContentView.h"

@class DTLazyImageView;

// Notifications
extern NSString * const DTLazyImageViewWillStartDownloadNotification;
extern NSString * const DTLazyImageViewDidFinishDownloadNotification;

/**
 Protocol for delegates of <DTLazyImageView> to inform them about the downloaded image dimensions.
 */
@protocol DTLazyImageViewDelegate <NSObject>
@optional

/**
 Method that informs the delegate about the image size so that it can re-layout text.
 @param lazyImageView The image view
 @param size The image size that is now known
 */
- (void)lazyImageView:(DTLazyImageView *)lazyImageView didChangeImageSize:(CGSize)size;
@end

/**
 This `UIImageView` subclass lazily loads an image from a URL and informs a delegate once the size of the image is known.
 */

@interface DTLazyImageView : UIImageView

/**
 @name Providing Content
 */

/**
 The URL of the remote image
 */
@property (nonatomic, strong) NSURL *url;

/**
 The URL Request that is to be used for downloading the image. If this is left `nil` the a new URL Request will be created
 */
@property (nonatomic, strong) NSMutableURLRequest *urlRequest;

/**
 The DTAttributedTextContentView used to display remote images with DTAttributedTextCell
 */
@property (nonatomic, DT_WEAK_PROPERTY) DTAttributedTextContentView *contentView;

/**
 @name Getting Information
 */

/**
 Set to `YES` to support progressive display of progressive downloads
 */
@property (nonatomic, assign) BOOL shouldShowProgressiveDownload;

/**
 The delegate, conforming to <DTLazyImageViewDelegate>, to inform when the image dimensions were determined
 */
@property (nonatomic, DT_WEAK_PROPERTY) id<DTLazyImageViewDelegate> delegate;


/**
 @name Cancelling Download
*/

/**
 Cancels the image downloading
 */
- (void)cancelLoading;

@end
