//
//  DTCoreTextGlyphRun.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTCompatibility.h"

#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

@class DTCoreTextLayoutLine;
@class DTTextAttachment;


/**
 This class is an Objective-C wrapper around `CTRun` and represents a glyph run. That is, a number of characters from the original `NSAttributedString` that share the same characteristics and attributes.
 */

@interface DTCoreTextGlyphRun : NSObject 
{
	NSRange _stringRange;
}

/**
 @name Creating Glyph Runs
 */

/**
 Creates a new glyph run from a `CTRun`, belonging to a given layout line and with a given offset from the left line origin.
 @param run The Core Text glyph run to wrap
 @param layoutLine The layout line that this glyph run belongs to
 @param offset The offset from the left line origin to place the glyph run at
 @returns An initialized DTCoreTextGlyphRun
 */
- (id)initWithRun:(CTRunRef)run layoutLine:(DTCoreTextLayoutLine *)layoutLine offset:(CGFloat)offset;

/**
 @name Drawing
 */

/**
 Draws the receiver into the given context with the position that it derives from the layout line it belongs to.
 @see drawDecorationInContext: for drawing the receiver's decoration
 @param context The graphics context to draw into
 */
- (void)drawInContext:(CGContextRef)context;

/**
 Draws the receiver's decoration into the given context with the position that it derives from the layout line it belongs to. Decoration is background highlighting, underline and strike-through.
 @param context The graphics context to draw into
 */
- (void)drawDecorationInContext:(CGContextRef)context;

/**
 Creates a `CGPath` containing the shapes of all glyphs in the receiver
 */
- (CGPathRef)newPathWithGlyphs;

/**
 @name Getting Information
 */

/**
 Determines the frame of a specific glyph
 @param index The index of the glyph
 @return The frame of the glyph
 */
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;

/**
 The bounds of an image encompassing the entire run.
 @param context The graphics context used for the measurement
 @returns The rectangle containing the result
 */
- (CGRect)imageBoundsInContext:(CGContextRef)context;

/**
 The string range (of the attributed string) that is represented by the receiver
 @returns The range
 */
- (NSRange)stringRange;

/**
 The string indices of the receiver
 @returns An array of string indices
 */
- (NSArray *)stringIndices;

/**
 The frame rectangle of the glyph run, relative to the layout frame coordinate system
 */
@property (nonatomic, readonly) CGRect frame;

/**
 The number of glyphs that the receiver is made up of
 */
@property (nonatomic, readonly) NSInteger numberOfGlyphs;

/**
 The Core Text attributes that are shared by all glyphs of the receiver
 */
@property (nonatomic, readonly) NSDictionary *attributes;

/**
 Returns `YES` if the receiver is part of a hyperlink, `NO` otherwise
 */
@property (nonatomic, assign, readonly, getter=isHyperlink) BOOL hyperlink;

/**
 Returns `YES` if the receiver represents trailing whitespace in a line.
 
 This can be used to avoid drawing of background color, strikeout or underline for empty trailing white space glyph runs.
 */
- (BOOL)isTrailingWhitespace;

/**
 The ascent (height above the baseline) of the receiver
 */
@property (nonatomic, readonly) CGFloat ascent;

/**
 The descent (height below the baseline) of the receiver
 */
@property (nonatomic, readonly) CGFloat descent;

/**
 The leading (additional space above the ascent) of the receiver
 */
@property (nonatomic, readonly) CGFloat leading;

/**
 The width of the receiver
 */
@property (nonatomic, readonly) CGFloat width;

/**
 `YES` if the writing direction is Right-to-Left, otherwise `NO`
 */
@property (nonatomic, readonly) BOOL writingDirectionIsRightToLeft;

/**
 The text attachment of the receiver, or `nil` if there is none
 */
@property (nonatomic, readonly) DTTextAttachment *attachment;


@end
