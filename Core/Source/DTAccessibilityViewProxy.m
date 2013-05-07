//
//  DTAccessibilityViewProxy.m
//  DTCoreText
//
//  Created by Austen Green on 5/6/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAccessibilityViewProxy.h"

@implementation DTAccessibilityViewProxy

- (id)initWithTextAttachment:(DTTextAttachment *)textAttachment delegate:(id<DTAccessibilityViewProxyDelegate>)delegate
{
	_textAttachment = textAttachment;
	_delegate = delegate;
	return self;
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
	NSMethodSignature *signature = [UIView instanceMethodSignatureForSelector:sel];
	
	return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	UIView *view = [self.delegate viewForTextAttachment:self.textAttachment proxy:self];
	[invocation invokeWithTarget:view];
}

@end
