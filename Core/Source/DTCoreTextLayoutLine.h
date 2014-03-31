//
//  DTCoreTextLayoutLine.h
//  DTCoreText
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
@class DTCoreTextParagraphStyle;
@class DTTextBlock;

/**
 This class represents one layouted line and contains a number of glyph runs.
 */
@interface DTCoreTextLayoutLine : NSObject
{
	// IVAR required by DTRichTextEditor, used in category
		NSInteger _stringLocationOffset; // offset to modify internal string location to get actual location
}

/**
 @name Creating Layout Lines
 */

/**
 Creates a layout line from a given `CTLine`
 @param line The Core Text line to wrap
 @returns A prepared layout line
 */
- (id)initWithLine:(CTLineRef)line;

/**
 Creates a layout line from a given `CTLine`
 @param line The Core Text line to wrap
 @param stringLocationOffset Offset to modify internal string location to get actual location
 @returns A prepared layout line
 */

- (id)initWithLine:(CTLineRef)line stringLocationOffset:(NSInteger)stringLocationOffset;

/**
 @name Drawing Layout Lines
 */

/**
 Draws the receiver in a given graphics context
 @param context The graphics context to draw into
 */
- (void)drawInContext:(CGContextRef)context;

/**
 Creates a `CGPath` containing the shapes of all glyphs in the line
 */
- (CGPathRef)newPathWithGlyphs;

/**
 @name Getting Information about Layout Lines
 */

/**
 The range in the original string that is represented by the receiver
 @returns The string strange
 */
- (NSRange)stringRange;

/**
 The number of glyphs the receiver consists of
 @returns the number of glyphs
 */
- (NSInteger)numberOfGlyphs;

/**
 Determines the frame of a specific glyph
 @param index The index of the glyph
 @return The frame of the glyph
 */
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;

/**
 Retrieves the glyphRuns with a given range
 @param range The range
 @returns An array of glyph runs
 */
- (NSArray *)glyphRunsWithRange:(NSRange)range;

/**
 The frame of a number of glyphs with a given range
 @param range The range
 @returns The rectangle containing the result
 */
- (CGRect)frameOfGlyphsWithRange:(NSRange)range;

/**
 The bounds of an image encompassing the entire run.
 @param context The graphics context used for the measurement
 @returns The rectangle containing the result
 */
- (CGRect)imageBoundsInContext:(CGContextRef)context;

/**
 The string indices of the receiver
 @returns An array of string indices
 */
- (NSArray *)stringIndices;

/**
 Determins the graphical offset for a given string index
 @param index The string index
 @returns The offset
 */
- (CGFloat)offsetForStringIndex:(NSInteger)index;

/**
 Determines the string index that is closest to a given point
 @param position The position to determine the string index for
 @returns The string index
 */
- (NSInteger)stringIndexForPosition:(CGPoint)position;

/**
 The frame of the receiver relative to the layout frame
 */
@property (nonatomic, assign) CGRect frame;

/**
 The glyph runs that the line contains.
 */
@property (nonatomic, readonly) NSArray *glyphRuns;

/**
 The ascent (height above the baseline) of the receiver
 */
@property (nonatomic, assign) CGFloat ascent; // needs to be modifyable

/**
 The descent (height below the baseline) of the receiver
 */
@property (nonatomic, readonly) CGFloat descent;

/**
 The leading (additional space above the ascent) of the receiver
 */
@property (nonatomic, readonly) CGFloat leading;

/**
 The width of the traling whitespace of the receiver
 */
@property (nonatomic, readonly) CGFloat trailingWhitespaceWidth;

/**
 The offset for the underline in positive points measured from the baseline. This is the maximum underline value of the fonts of all glyph runs of the receiver.
 */
@property (nonatomic, readonly) CGFloat underlineOffset;

/**
 The line height of the line. This is determined by getting the maximum font size of all glyph runs of the receiver.
 */
@property (nonatomic, readonly) CGFloat lineHeight;

/**
 The paragraph style of the paragraph this line belongs to. All lines in a paragraph are supposed to have the same paragraph style, so this takes the paragraph style of the first glyph run
 */
@property (nonatomic, readonly) DTCoreTextParagraphStyle *paragraphStyle;

/**
 The text blocks that the receiver belongs to.
 */
@property (nonatomic, readonly) NSArray *textBlocks;

/**
 The text attachments occuring in glyph runs of the receiver.
 */
@property (nonatomic, readonly) NSArray *attachments;

/**
 The baseline origin of the receiver
 */
@property (nonatomic, assign) CGPoint baselineOrigin;

/**
 `YES` if the writing direction is Right-to-Left, otherwise `NO`
 */
@property (nonatomic, assign) BOOL writingDirectionIsRightToLeft;

/**
 The offset to modify internal string location to get actual location
*/

@property (nonatomic, readonly) NSInteger stringLocationOffset;

/**
 Method to efficiently determine if the receiver is a horizontal rule.
 
 Note: This is used to shortcut drawing of text lines and to allow a horizontal rule line have an "endlessly wide" width so that it gets picked up by [DTCoreTextLayoutFrame linesVisibleInRect:].
 */
- (BOOL)isHorizontalRule;


/**
 @name Creating Variants
 */

/**
 Creates a version of the receiver that is justified to the given width.
 
 @param justificationFactor Full or partial justification. When set to `1.0` or greater, full justification is performed. If this parameter is set to less than `1.0`, varying degrees of partial justification are performed. If it is set to `0` or less, no justification is performed.
 @param justificationWidth The width to which the resultant line is justified. If justificationWidth is less than the actual width of the line, then negative justification is performed (that is, glyphs are squeezed together).
 */
- (DTCoreTextLayoutLine *)justifiedLineWithFactor:(CGFloat)justificationFactor justificationWidth:(CGFloat)justificationWidth;

@end
