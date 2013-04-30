//
//  DTAccessibilityElement.m
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAccessibilityElement.h"

@implementation DTAccessibilityElement

- (CGRect)accessibilityFrame
{
	CGRect frame = self.localCoordinateAccessibilityFrame;
	UIView *parent = self.accessibilityContainer;
	NSAssert([parent isKindOfClass:[UIView class]], @"AccessibilityContainer must be a UIView - is actually %@", parent);
	frame = [parent.window convertRect:frame fromView:parent];
	return frame;
}

- (CGPoint)accessibilityActivationPoint
{
	CGPoint point = self.localCoordinateAccessibilityActivationPoint;
	UIView *parent = self.accessibilityContainer;
	NSAssert([parent isKindOfClass:[UIView class]], @"AccessibilityContainer must be a UIView - is actually %@", parent);
	point = [parent.window convertPoint:point fromView:parent];
	return point;
}

@end
