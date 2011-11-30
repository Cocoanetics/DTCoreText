//
//  CGUtils.m
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "CGUtils.h"


// deprecated: use bezierPathWithRoundedRect instead

//CGPathRef newPathForRoundedRect(CGRect rect, CGFloat cornerRadius, BOOL roundTopCorners, BOOL roundBottomCorners)
//
//{
//	CGMutablePathRef retPath = CGPathCreateMutable();
//	
//	CGRect innerRect = CGRectInset(rect, cornerRadius, cornerRadius);
//	
//	CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
//	CGFloat outside_right = rect.origin.x + rect.size.width;
//	CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
//	CGFloat outside_bottom = rect.origin.y + rect.size.height;
//	
//	CGFloat inside_top = innerRect.origin.y;
//	CGFloat outside_top = rect.origin.y;
//	CGFloat outside_left = rect.origin.x;
//	
//	
//	if (roundTopCorners)
//	{
//		CGPathMoveToPoint(retPath, NULL, innerRect.origin.x, outside_top);
//		CGPathAddLineToPoint(retPath, NULL, inside_right, outside_top);
//		
//		CGPathAddArcToPoint(retPath, NULL, outside_right, outside_top, outside_right, inside_top, cornerRadius);	
//	}
//	else 
//	{
//		CGPathMoveToPoint(retPath, NULL, outside_left, outside_top);
//		CGPathAddLineToPoint(retPath, NULL, outside_right, outside_top);
//		
//	}
//	
//	if (roundBottomCorners)
//	{
//		CGPathAddLineToPoint(retPath, NULL, outside_right, inside_bottom);
//		CGPathAddArcToPoint(retPath, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, cornerRadius);
//		
//		CGPathAddLineToPoint(retPath, NULL, innerRect.origin.x, outside_bottom);
//		CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, cornerRadius);
//	}
//	else 
//	{
//		CGPathAddLineToPoint(retPath, NULL, outside_right, outside_bottom);
//		CGPathAddLineToPoint(retPath, NULL, outside_left, outside_bottom);
//	}
//	
//	
//	
//	if (roundTopCorners)
//	{
//		CGPathAddLineToPoint(retPath, NULL, outside_left, inside_top);
//		CGPathAddArcToPoint(retPath, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, cornerRadius);
//	}
//	else 
//	{
//		CGPathAddLineToPoint(retPath, NULL, rect.origin.x, outside_top);
//		
//	}
//	
//	
//	CGPathCloseSubpath(retPath);
//	
//	return retPath;
//}

CGSize sizeThatFitsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit)
{
	if (originalSize.width <= sizeToFit.width && originalSize.height <= sizeToFit.height)
	{
		return originalSize;
	}
	
	CGFloat necessaryZoomWidth = sizeToFit.width / originalSize.width;
	CGFloat necessaryZoomHeight = sizeToFit.height / originalSize.height;
	
	CGFloat smallerZoom = MIN(necessaryZoomWidth, necessaryZoomHeight);
	
	CGSize scaledSize = CGSizeMake(roundf(originalSize.width*smallerZoom), roundf(originalSize.height*smallerZoom));
	
	return scaledSize;
}


CGPoint CGRectCenter(CGRect rect)
{
	return (CGPoint){ CGRectGetMidX(rect), CGRectGetMidY(rect) };
}
