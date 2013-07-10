//
//  DTCoreTextLayoutFrame+Cursor.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 10.07.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreTextLayoutFrame+Cursor.h"
#import "DTCoreTextLayoutLine.h"

@implementation DTCoreTextLayoutFrame (Cursor)

- (NSInteger)closestCursorIndexToPoint:(CGPoint)point
{
	NSArray *lines = self.lines;
	
	if (![lines count])
	{
		return NSNotFound;
	}
	
	DTCoreTextLayoutLine *firstLine = [lines objectAtIndex:0];
	if (point.y < CGRectGetMinY(firstLine.frame))
	{
		return 0;
	}
	
	DTCoreTextLayoutLine *lastLine = [lines lastObject];
	if (point.y > CGRectGetMaxY(lastLine.frame))
	{
        NSRange stringRange = [self visibleStringRange];
        
        if (stringRange.length)
        {
            return NSMaxRange([self visibleStringRange])-1;
        }
	}
	
	// find closest line
	DTCoreTextLayoutLine *closestLine = nil;
	CGFloat closestDistance = CGFLOAT_MAX;
	
	for (DTCoreTextLayoutLine *oneLine in lines)
	{
		// line contains point
		if (CGRectGetMinY(oneLine.frame) <= point.y && CGRectGetMaxY(oneLine.frame) >= point.y)
		{
			closestLine = oneLine;
			break;
		}
		
		CGFloat top = CGRectGetMinY(oneLine.frame);
		CGFloat bottom = CGRectGetMaxY(oneLine.frame);
		
		CGFloat distance = CGFLOAT_MAX;
		
		if (top > point.y)
		{
			distance = top - point.y;
		}
		else if (bottom < point.y)
		{
			distance = point.y - bottom;
		}
		
		if (distance < closestDistance)
		{
			closestLine = oneLine;
			closestDistance = distance;
		}
	}
	
	if (!closestLine)
	{
		return NSNotFound;
	}
	
	NSInteger closestIndex = [closestLine stringIndexForPosition:point];
	
	NSInteger maxIndex = NSMaxRange([closestLine stringRange])-1;
	
	if (closestIndex > maxIndex)
	{
		closestIndex = maxIndex;
	}
	
	if (closestIndex>=0)
	{
		return closestIndex;
	}
	
	return NSNotFound;
}

- (CGRect)cursorRectAtIndex:(NSInteger)index
{
	DTCoreTextLayoutLine *line = [self lineContainingIndex:index];
	
	if (!line)
	{
		return CGRectZero;
	}
	
	CGFloat offset = [line offsetForStringIndex:index];
	
	CGRect rect = line.frame;
	rect.size.width = 3.0;
	rect.origin.x += offset;
	
	return rect;
}

@end
