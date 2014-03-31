//
//  PathUtils.m
//  DTCoreText
//
//  Created by Michael Markowski on 12/16/13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTPathUtils.h"

@implementation DTPathUtils

CGRect clipRectToPath(CGRect rect, CGPathRef path)
{
	// TODO: Optimize by allocating a single buffer large enough for our largest rectangle and reusing it.
	// TODO: Optimize by reusing the CGBitmapContext
	
	size_t width = floorf(rect.size.width);
	size_t height = floorf(rect.size.height);
	uint8_t *bits = calloc(width * height, sizeof(*bits));
	CGContextRef bitmapContext = CGBitmapContextCreate(bits, width, height, sizeof(*bits) * 8, width, NULL, kCGImageAlphaOnly);
	CGContextSetShouldAntialias(bitmapContext, NO);
	
	CGContextTranslateCTM(bitmapContext, -rect.origin.x, -rect.origin.y);
	CGContextAddPath(bitmapContext, path);
	CGContextFillPath(bitmapContext);
	
	BOOL foundStart = NO;
	NSRange range = NSMakeRange(0, 0);
	NSUInteger x = 0;
	for (; x < width; ++x)
	{
		BOOL isGoodColumn = YES;
		for (NSUInteger y = 0; y < height; ++y)
		{
			if (bits[y * width + x] < 128)
			{
				isGoodColumn = NO;
				break;
			}
		}
        
		if (isGoodColumn && ! foundStart)
		{
			foundStart = YES;
			range.location = x;
		}
		else if (!isGoodColumn && foundStart)
		{
			break;
		}
	}
	if (foundStart)
	{
		range.length = x - range.location - 1;	// X is 1 past the last full-height column
	}
	
	CGContextRelease(bitmapContext);
	free(bits);
	
	CGRect clipRect = CGRectMake(rect.origin.x + range.location, rect.origin.y, range.length, rect.size.height);
	return clipRect;
}

- (CFArrayRef)copyRectangularPathsForPath:(CGPathRef)path height:(CGFloat)height
{
	CFMutableArrayRef paths = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    
	// First, check if we're a rectangle. If so, we can skip the hard parts.
	CGRect rect;
	if (CGPathIsRect(path, &rect))
	{
		CFArrayAppendValue(paths, path);
	}
	else
	{
		// Build up the boxes one line at a time. If two boxes have the same width and offset, then merge them.
		CGRect boundingBox = CGPathGetPathBoundingBox(path);
		CGRect frameRect = CGRectZero;

#if TARGET_OS_IPHONE
		CGContextRef context = UIGraphicsGetCurrentContext();
#else
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
		
		for (CGFloat y = CGRectGetMaxY(boundingBox) - height; y > height; y -= height)
		{
			CGRect lineRect = CGRectMake(CGRectGetMinX(boundingBox), y, CGRectGetWidth(boundingBox), height);
			CGContextAddRect(context, lineRect);
			
			lineRect = CGRectIntegral(clipRectToPath(lineRect, path));		// Do the math with full precision so we don't drift, but do final render on pixel boundaries.
			CGContextAddRect(context, lineRect);
            
			if (! CGRectIsEmpty(lineRect))
			{
				if (CGRectIsEmpty(frameRect))
				{
					frameRect = lineRect;
				}
				else if (frameRect.origin.x == lineRect.origin.x && frameRect.size.width == lineRect.size.width)
				{
					frameRect = CGRectMake(lineRect.origin.x, lineRect.origin.y, lineRect.size.width, CGRectGetMaxY(frameRect) - CGRectGetMinY(lineRect));
				}
				else
				{
					CGMutablePathRef framePath = CGPathCreateMutable();
					CGPathAddRect(framePath, NULL, frameRect);
					CFArrayAppendValue(paths, framePath);
                    
					CFRelease(framePath);
					frameRect = lineRect;
				}
			}
		}
		
		if (! CGRectIsEmpty(frameRect))
		{
			CGMutablePathRef framePath = CGPathCreateMutable();
			CGPathAddRect(framePath, NULL, frameRect);
			CFArrayAppendValue(paths, framePath);
			CFRelease(framePath);
		}
	}
    
	return paths;
}
@end
