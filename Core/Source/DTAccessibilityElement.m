//
//  DTAccessibilityElement.m
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTAccessibilityElement.h"

static const CGPoint DTAccessibilityElementNullActivationPoint = {CGFLOAT_MAX, CGFLOAT_MAX};

@interface DTAccessibilityElement()
@property (nonatomic, unsafe_unretained) UIView *parentView;
@end

@implementation DTAccessibilityElement

- (id)initWithParentView:(UIView *)parentView
{
	self = [super initWithAccessibilityContainer:parentView];
	if (self)
	{
		_parentView = parentView;
		_localCoordinateAccessibilityActivationPoint = DTAccessibilityElementNullActivationPoint;
	}
	return self;
}

- (CGRect)accessibilityFrame
{
	CGRect frame = self.localCoordinateAccessibilityFrame;
	frame = [self.parentView.window convertRect:frame fromView:self.parentView];
	return frame;
}

- (CGPoint)accessibilityActivationPoint
{
	CGPoint point = self.localCoordinateAccessibilityActivationPoint;
	if (CGPointEqualToPoint(point, DTAccessibilityElementNullActivationPoint))
	{
		point = [super accessibilityActivationPoint];
	}
	
	point = [self.parentView.window convertPoint:point fromView:self.parentView];
	
	return point;
}

@end
