//
//  DTAccessibilityViewProxy.m
//  DTCoreText
//
//  Created by Austen Green on 5/6/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAccessibilityViewProxy.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

@implementation DTAccessibilityViewProxy

- (id)initWithTextAttachment:(DTTextAttachment *)textAttachment delegate:(id<DTAccessibilityViewProxyDelegate>)delegate
{
	_textAttachment = textAttachment;
	_delegate = delegate;
	return self;
}

- (UIView *)proxiedView
{
	return [self.delegate viewForTextAttachment:self.textAttachment proxy:self];
}

- (Class)class
{
	Class aClass = [[self proxiedView] class];
	
	if (!aClass)
		aClass = [DTAccessibilityViewProxy class];
	
	return aClass;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
	NSMethodSignature *signature = [UIView instanceMethodSignatureForSelector:sel];
	
	return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	UIView *view = [self proxiedView];
	[invocation invokeWithTarget:view];
}

- (BOOL)isEqual:(id)object
{
	return [[self proxiedView] isEqual:object];
}

- (NSUInteger)hash
{
	return [[self proxiedView] hash];
}

@end

#endif
