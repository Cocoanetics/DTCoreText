//
//  DTCoreTextLayoutLine.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//


#import <CoreText/CoreText.h>

@class DTCoreTextLayoutFrame;

@interface DTCoreTextLayoutLine : NSObject 
{
	NSInteger _stringLocationOffset; // offset to modify internal string location to get actual location
}

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame;

- (NSRange)stringRange;
- (NSInteger)numberOfGlyphs;
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;
- (NSArray *)glyphRunsWithRange:(NSRange)range;
- (CGRect)frameOfGlyphsWithRange:(NSRange)range;
- (CGRect)imageBoundsInContext:(CGContextRef)context;
- (NSArray *)stringIndices;
- (CGFloat)offsetForStringIndex:(NSInteger)index;
- (NSInteger)stringIndexForPosition:(CGPoint)position;
- (CGFloat)paragraphSpacing:(BOOL)zeroNonLast;
- (CGFloat)paragraphSpacing;


/**
 @name Creating Variants
 */

/**
 Creates a version of the receiver that is justified to the given width.
 
 @param justificationFactor Full or partial justification. When set to `1.0` or greater, full justification is performed. If this parameter is set to less than `1.0`, varying degrees of partial justification are performed. If it is set to `0` or less, no justification is performed.
 @param justificationWidth The width to which the resultant line is justified. If justificationWidth is less than the actual width of the line, then negative justification is performed (that is, glyphs are squeezed together).
 */
- (DTCoreTextLayoutLine *)justifiedLineWithFactor:(CGFloat)justificationFactor justificationWidth:(CGFloat)justificationWidth;


- (CGFloat)calculatedLineHeightMultiplier;

/** Calculates the leading size which is the space before this current line. 
 
 @returns The leading for this line.
 */
- (CGFloat)calculatedLeading;


/** Calculates the line height for the entire line from going through the paragraph styles and finding minimum and maximum. 
 
 @returns The overall line height for this line or zero if no line height is specified.
 */
- (CGFloat)calculatedLineHeight;

- (void)drawInContext:(CGContextRef)context;


/** Adjust the baselines of all lines in this layout frame to fit the heights of text attachments. 
 
 This is used to work around a CoreText bug that was fixed in iOS 4.2
 
 @returns `YES` if the line needed an adjustment, `NO` if no adjustment was carried out
 */
- (BOOL)correctAttachmentHeights:(CGFloat *)downShift;


// sets the line baseline origin such that it follows the given line
- (CGPoint)baselineOriginToPositionAfterLine:(DTCoreTextLayoutLine *)previousLine;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong, readonly) NSArray *glyphRuns;

@property (nonatomic, assign) CGFloat ascent; // needs to be modifyable
@property (nonatomic, assign, readonly) CGFloat descent;
@property (nonatomic, assign, readonly) CGFloat leading;
@property (nonatomic, assign, readonly) CGFloat trailingWhitespaceWidth;

@property (nonatomic, assign) CGPoint baselineOrigin;

@end
