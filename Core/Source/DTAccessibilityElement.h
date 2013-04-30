//
//  DTAccessibilityElement.h
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DTAccessibilityElement : UIAccessibilityElement
@property (nonatomic, assign) CGRect localCoordinateAccessibilityFrame;
@property (nonatomic, assign) CGPoint localCoordinateAccessibilityActivationPoint;
@end
