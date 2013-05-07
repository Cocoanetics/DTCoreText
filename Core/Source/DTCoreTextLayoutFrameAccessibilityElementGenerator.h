//
//  DTCoreTextLayoutFrameAccessibilityElementGenerator.h
//  DTCoreText
//
//  Created by Austen Green on 3/13/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTAccessibilityElement.h"

@class DTCoreTextLayoutFrame, DTTextAttachment;

typedef UIView *(^DTAttachmentViewProvider)(DTTextAttachment *textAttachment);

@interface DTCoreTextLayoutFrameAccessibilityElementGenerator : NSObject

// Contains DTAccessibilityElement objects
- (NSArray *)accessibilityElementsForLayoutFrame:(DTCoreTextLayoutFrame *)frame view:(UIView *)view attachmentViewProvider:(DTAttachmentViewProvider)block;

@end
