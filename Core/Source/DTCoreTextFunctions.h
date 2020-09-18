//
//  DTCoreTextFunctions.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//
#import <CoreText/CoreText.h>

#import "DTCompatibility.h"

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

#import "DTCompatibility.h"

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

/**
 Creates a CTFont from a UIFont
 @param font The `UIFont`
 @returns The matching CTFont
 */
CTFontRef DTCTFontCreateWithUIFont(UIFont *font);
#endif

/**
 Converts an NSLineBreakMode into CoreText line truncation type
 */
CTLineTruncationType DTCTLineTruncationTypeFromNSLineBreakMode(NSLineBreakMode lineBreakMode);

/**
 Rounds the passed value according to the specified content scale.
 
 With contentScale 1 the results are identical to roundf, with Retina content scale 2 the results are multiples of 0.5.
 */
CGFloat DTRoundWithContentScale(CGFloat value, CGFloat contentScale);

/**
 Rounds up the passed value according to the specified content scale.
 
 With contentScale 1 the results are identical to roundf, with Retina content scale 2 the results are multiples of 0.5.
 */
CGFloat DTCeilWithContentScale(CGFloat value, CGFloat contentScale);

/**
 Rounds down the passed value according to the sspecifiedcontent scale.
 
 With contentScale 1 the results are identical to roundf, with Retina content scale 2 the results are multiples of 0.5.
 */
CGFloat DTFloorWithContentScale(CGFloat value, CGFloat contentScale);

#pragma mark - Alignment Conversion

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
/**
 Converts from NSTextAlignment to CTTextAligment
 */
CTTextAlignment DTNSTextAlignmentToCTTextAlignment(NSTextAlignment nsTextAlignment);

/**
 Converts from CTTextAlignment to NSTextAligment
 */
NSTextAlignment DTNSTextAlignmentFromCTTextAlignment(CTTextAlignment ctTextAlignment);
#endif

