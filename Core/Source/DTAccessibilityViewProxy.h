//
//  DTAccessibilityViewProxy.h
//  DTCoreText
//
//  Created by Austen Green on 5/6/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTTextAttachment.h"

@protocol DTAccessibilityViewProxyDelegate;

@interface DTAccessibilityViewProxy : NSProxy
@property (nonatomic, unsafe_unretained) id<DTAccessibilityViewProxyDelegate> delegate;
@property (nonatomic, strong) DTTextAttachment *textAttachment;

- (id)initWithTextAttachment:(DTTextAttachment *)textAttachment delegate:(id<DTAccessibilityViewProxyDelegate>)delegate;

@end

@protocol DTAccessibilityViewProxyDelegate
- (UIView *)viewForTextAttachment:(DTTextAttachment *)textAttachment proxy:(DTAccessibilityViewProxy *)proxy;
@end