//
//  CGUtils.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/16/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

//see implementation file for note on deprecation
//CGPathRef newPathForRoundedRect(CGRect rect, CGFloat cornerRadius, BOOL roundTopCorners, BOOL roundBottomCorners);

/** Determines the new zoom only computing if the sizeToFit is smaller than the originalSize. The zoom scale is computed by whichever resizing scale along the X or Y is smaller preserving the aspect ratio by respecting the axis with more room. The new size is then computed by multipliying the originalSize by that zoom scale. 
 @return New size that fits the sizeToFit while still preserving the aspect ratio of the originalSize. */
CGSize sizeThatFitsKeepingAspectRatio(CGSize originalSize, CGSize sizeToFit);

/** Convenience method to find the center of a CGRect. Uses CGRectGetMidX and CGRectGetMidY. 
 @return The point which is the center of rect. */
CGPoint CGRectCenter(CGRect rect);
