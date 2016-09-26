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

/**
 A block that provides accessibility information for the passed text attachments
 */
typedef id(^DTAttachmentViewProvider)(DTTextAttachment *textAttachment);

/**
 Generates an array of objects conforming to the UIAccessibility informal protocol based on a <DTCoreTextLayoutFrame>.
 */
@interface DTCoreTextLayoutFrameAccessibilityElementGenerator : NSObject

/**
 The designated initializer. The DTAttachmentViewProvider block may be used to provide custom subviews in place of a static accessibility element.
 @param frame The <DTCoreTextLayoutFrame> to generate accessibility elements for.
 @param view The logical superview of the elements - the view that owns the local coordinate system for drawing the frame.
 @param block A callback block which takes a <DTTextAttachment> object and returns an object that conforms to the UIAccessibility informal protocol.
 @returns Returns an array of objects conforming to the UIAccessibility informal protocol, suitable for presentation for the VoiceOver system.
 */

- (NSArray *)accessibilityElementsForLayoutFrame:(DTCoreTextLayoutFrame *)frame view:(UIView *)view attachmentViewProvider:(DTAttachmentViewProvider)block;

@end
