//
//  DTAccessibilityElement.h
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 A UIAccessibilityElement subclass that automatically converts its local accessibilityFrame to screen coordinates.
 */
@interface DTAccessibilityElement : UIAccessibilityElement
/**
 The frame for the accessibility element in terms of the receiver's superview.
 */
@property (nonatomic, assign) CGRect localCoordinateAccessibilityFrame;

/**
 The point for activating accessibility events in terms of the receiver's superview.
 */
@property (nonatomic, assign) CGPoint localCoordinateAccessibilityActivationPoint;

/**
 The designated initializer.  This class should be initialized with a UIView as its accessibility container.
 @param parentView The logical superview for the onscreen element the receiver represents.
 @returns Returns an initialized DTAccessibilityElement */

- (id)initWithParentView:(UIView *)parentView;

@end
