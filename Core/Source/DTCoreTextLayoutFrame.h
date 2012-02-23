//
//  DTCoreTextLayoutFrame.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//


#import <CoreText/CoreText.h>

@class DTCoreTextLayoutLine;


// the value to use if the height is unknown
#define CGFLOAT_OPEN_HEIGHT 16777215.0f


@class DTCoreTextLayouter;

/**
 This class represents a single frame of text and basically wraps CTFrame. It provides an array of text lines that fit in the given rectangle.
 
 Both styles of layouting are supported: open ended (suitable for scroll views) and limited to a given rectangle. To use the open-ended style specify `CGFLOAT_OPEN_HEIGHT` for the <frame> height when creating a layout frame.
 
 The array of lines is built lazily the first time it is accessed or - for open-ended frames - when the frame property is being queried.
 */
@interface DTCoreTextLayoutFrame : NSObject 
{
	CGRect _frame;

	NSArray *_lines;
	NSArray *_paragraphRanges;

	NSArray *_textAttachments;
	NSAttributedString *_attributedStringFragment;
}


/**
 @name Creating Layout Frames
 */


/**
 Creates a Layout Frame with the given frame using the attributed string loaded into the layouter.
 
 @param frame The rectangle specifying origin and size of available for text. Specify `CGFLOAT_OPEN_HEIGHT` to not limit the height.
 @param layouter A reference to the layouter for this text box.
 */
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter;


/**
 Creates a Layout Frame with the given frame using the attributed string loaded into the layouter.
 
 @param frame The rectangle specifying origin and size of available for text. Specify `CGFLOAT_OPEN_HEIGHT` to not limit the height.
 @param layouter A reference to the layouter for the receiver. Note: The layouter owns the attributed string.
 @param range The range within the attributed string to layout into the receiver.
 */
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter range:(NSRange)range;


/**
 @name Getting Information
 */


/**
 The string range that is visible i.e. fits into the given rectangle. For open-ended frames this is typically the entire string. For frame-contrained layout frames it is the substring that fits.
  */
- (NSRange)visibleStringRange;


/**
 This is a copy of the attributed string owned by the layouter of the receiver.
*/
- (NSAttributedString *)attributedStringFragment;


/**
 An array that maps glyphs with string indices.
 */
- (NSArray *)stringIndices;


/**
 The frame rectangle for the layout frame.
 */
 @property (nonatomic, assign, readonly) CGRect frame;


/**
 @name Drawing
 */


/**
 Draws the entire layout frame into the given graphics context.
 
 @param context A graphics context to draw into
 @param drawImages Whether images should be draw together with the text. If you specify `NO` then space is left blank where images would go and you have to add your own views to display these images.
 */
- (void)drawInContext:(CGContextRef)context drawImages:(BOOL)drawImages;


/**
 @name Working with Glyphs
 */


/**
 Retrieves the index of the text line that contains the given glyph index.
 
 @param index The index of the glyph
 @returns The index of the line containing this glyph
 */
- (NSInteger)lineIndexForGlyphIndex:(NSInteger)index;


/**
 Retrieves the frame of the glyph at the given glyph index.
 
 @param index The index of the glyph
 @returns The frame of this glyph
 */
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;


/**
 @name Working with Text Lines
 */


/**
 The text lines that belong to the receiver.
 */
@property (nonatomic, strong, readonly) NSArray *lines;


/**
 The text lines that are visible inside the given rectangle. Also incomplete lines are included.
 
 @param rect The rectangle
 @returns An array, sorted from top to bottom, of lines at least partially visible
 */
- (NSArray *)linesVisibleInRect:(CGRect)rect; 


/**
 The text lines that are visible inside the given rectangle. Only fully visible lines are included.
 
 @param rect The rectangle
 @returns An array, sorted from top to bottom, of lines fully visible
 */
- (NSArray *)linesContainedInRect:(CGRect)rect;


/**
 The layout line that contains the given string index.
 
 @param index The string index
 @returns The layout line that this index belongs to
 */
- (DTCoreTextLayoutLine *)lineContainingIndex:(NSUInteger)index;


/**
 @name Text Attachments
 */


/**
 The array of all <DTTextAttachment> instances that belong to the receiver.
 @returns All text attachments of the receiver.
 */
- (NSArray *)textAttachments;


/**
 The array of all DTTextAttachment instances that belong to the receiver which also match the specified predicate.
 
 @param predicate A predicate that uses properties of <DTTextAttachment> to reduce the returned array
 @returns A filtered array of text attachments.
 */
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate;


/** 
 @name Getting Paragraph Info
 */


/** 
 Finding which paragraph a given string index belongs to.
 
 @param stringIndex The index in the string to look for
 @returns The index of the paragraph, numbered from 0
 */
- (NSUInteger)paragraphIndexContainingStringIndex:(NSUInteger)stringIndex;


/** 
 Determines the paragraph range (of paragraph indexes) that encompass the entire given string Range.
 
 @param stringRange The string range for which the paragraph range is sought for
 @returns The range of paragraphs that fully enclose the string range
 */
- (NSRange)paragraphRangeContainingStringRange:(NSRange)stringRange;


/**
 The text lines that belong to the specified paragraph.
 
 @param index The index of the paragraph
 @returns An array, sorted from top to bottom, of lines in this paragraph
 */
- (NSArray *)linesInParagraphAtIndex:(NSUInteger)index;


/**
 An array of `NSRange` values encapsulated in `NSValue` instances. Each range is the string range contained in the corresponding paragraph.
*/
@property (nonatomic, strong, readonly) NSArray *paragraphRanges;


/**
 @name Debugging
 */


/**
 Switches on the debug drawing mode where individual glph runs, baselines, et ceter get individually marked.
 
 @param debugFrames if the debug drawing should occur
 */
+ (void)setShouldDrawDebugFrames:(BOOL)debugFrames;

@end
