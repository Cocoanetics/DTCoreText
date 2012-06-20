//
//  DTCoreTextLayoutLine.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//


#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

@class DTCoreTextLayoutFrame;

@interface DTCoreTextLayoutLine : NSObject 
{
	NSInteger _stringLocationOffset; // offset to modify internal string location to get actual location
}

- (id)initWithLine:(CTLineRef)line;

- (NSRange)stringRange;
- (NSInteger)numberOfGlyphs;
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;
- (NSArray *)glyphRunsWithRange:(NSRange)range;
- (CGRect)frameOfGlyphsWithRange:(NSRange)range;
- (CGRect)imageBoundsInContext:(CGContextRef)context;
- (NSArray *)stringIndices;
- (CGFloat)offsetForStringIndex:(NSInteger)index;
- (NSInteger)stringIndexForPosition:(CGPoint)position;


/**
 @name Creating Variants
 */

/**
 Creates a version of the receiver that is justified to the given width.
 
 @param justificationFactor Full or partial justification. When set to `1.0` or greater, full justification is performed. If this parameter is set to less than `1.0`, varying degrees of partial justification are performed. If it is set to `0` or less, no justification is performed.
 @param justificationWidth The width to which the resultant line is justified. If justificationWidth is less than the actual width of the line, then negative justification is performed (that is, glyphs are squeezed together).
 */
- (DTCoreTextLayoutLine *)justifiedLineWithFactor:(CGFloat)justificationFactor justificationWidth:(CGFloat)justificationWidth;



- (void)drawInContext:(CGContextRef)context;


/** Adjust the baselines of all lines in this layout frame to fit the heights of text attachments. 
 
 This is used to work around a CoreText bug that was fixed in iOS 4.2
 
 @returns `YES` if the line needed an adjustment, `NO` if no adjustment was carried out
 */
- (BOOL)correctAttachmentHeights:(CGFloat *)downShift;


@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong, readonly) NSArray *glyphRuns;

@property (nonatomic, assign) CGFloat ascent; // needs to be modifyable
@property (nonatomic, assign, readonly) CGFloat descent;
@property (nonatomic, assign, readonly) CGFloat leading;
@property (nonatomic, assign, readonly) CGFloat trailingWhitespaceWidth;

@property (nonatomic, assign) CGPoint baselineOrigin;

@end
