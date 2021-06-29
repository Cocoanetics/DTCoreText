//
//  DTAccessibilityViewProxy.h
//  DTCoreText
//
//  Created by Austen Green on 5/6/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"
#import "DTAccessibilityElement.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import "DTTextAttachment.h"
#import <DTFoundation/DTWeakSupport.h>

@protocol DTAccessibilityViewProxyDelegate;

/**
 UIView proxy for DTAttributedTextContentView custom subviews for text attachments.
 */

@interface DTAccessibilityViewProxy : NSProxy
/**
 The delegate for the proxy
 */
@property (nonatomic, DT_WEAK_PROPERTY, readonly) id<DTAccessibilityViewProxyDelegate> delegate;

/**
 The text attachment represented by the proxy
 */
@property (nonatomic, strong, readonly) DTTextAttachment *textAttachment;

/**
 Creates a text attachment proxy for use with the VoiceOver system.
 @param textAttachment The <DTTextAttachment> that will be represented by a view.
 @param delegate An object conforming to <DTAccessibilityViewProxyDelegate> that will provide a view when needed by the proxy.
 @returns A new proxy object
 */

- (id)initWithTextAttachment:(DTTextAttachment *)textAttachment delegate:(id<DTAccessibilityViewProxyDelegate>)delegate;

@end

/**
 Protocol to provide custom views for accessibility elements representing a DTTextAttachment.
 */
@protocol DTAccessibilityViewProxyDelegate
@required
/**
 Provides a view for an attachment, e.g. an imageView for images
 
 @param attachment The <DTTextAttachment> that the requested view should represent
 @param proxy The frame that the view should use to fit on top of the space reserved for the attachment.
 @returns The sender requesting the view.
 */

- (UIView *)viewForTextAttachment:(DTTextAttachment *)attachment proxy:(DTAccessibilityViewProxy *)proxy;
@end

#endif
