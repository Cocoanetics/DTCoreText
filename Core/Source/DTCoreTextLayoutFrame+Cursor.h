//
//  DTCoreTextLayoutFrame+Cursor.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 10.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutFrame.h"

/**
 The **Cursor** category extends DTCoreTextLayoutFrame for working with a caret and determine the string index of touch coordinates.
 */

@interface DTCoreTextLayoutFrame (Cursor)

/**
 Determines the closest string index to a point in the receiver's frame.
 
 This can be used to find the cursor position to position an input caret at.
 @param point The point
 @returns The resulting string index
 */
- (NSInteger)closestCursorIndexToPoint:(CGPoint)point;

/**
 The rectangle to draw a caret for a given index
 @param index The string index for which to determine a cursor frame
 @returns The cursor rectangle
 */
- (CGRect)cursorRectAtIndex:(NSInteger)index;

@end
