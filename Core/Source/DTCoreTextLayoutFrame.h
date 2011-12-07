//
//  DTCoreTextLayoutFrame.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//


#import <CoreText/CoreText.h>

@class DTCoreTextLayoutLine;


#define CGFLOAT_OPEN_HEIGHT 16777215.0f


@class DTCoreTextLayouter;

@interface DTCoreTextLayoutFrame : NSObject 

+ (void)setShouldDrawDebugFrames:(BOOL)debugFrames;

- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter;
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter range:(NSRange)range;

- (CGPathRef)path;
- (NSRange)visibleStringRange;

- (void)drawInContext:(CGContextRef)context drawImages:(BOOL)drawImages;
- (void)drawInContext:(CGContextRef)context;  // draws images

- (NSInteger)lineIndexForGlyphIndex:(NSInteger)index;
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;

- (NSArray *)linesVisibleInRect:(CGRect)rect; // lines that are intersected, i.e. also incomplete lines
// unused? - (NSArray *)linesContainedInRect:(CGRect)rect; // lines that are fully contained inside of rect
- (DTCoreTextLayoutLine *)lineContainingIndex:(NSUInteger)index; // line that contains the string index

- (NSArray *)stringIndices;

- (NSArray *)textAttachments;
- (NSArray *)textAttachmentsWithPredicate:(NSPredicate *)predicate;

- (void)correctAttachmentHeights;
- (void)correctLineOrigins;

- (NSAttributedString *)attributedStringFragment;

// working with Paragraphs
// unused? - (NSArray *)linesInParagraphAtIndex:(NSUInteger)index;
- (NSUInteger)paragraphIndexContainingStringIndex:(NSUInteger)stringIndex;
- (NSRange)paragraphRangeContainingStringRange:(NSRange)stringRange;

@property (nonatomic, assign, readonly) CGRect frame;

@property (nonatomic, strong, readonly) NSArray *lines;
@property (nonatomic, strong, readonly) NSArray *paragraphRanges;

@property (nonatomic, assign) NSInteger tag;

@end
