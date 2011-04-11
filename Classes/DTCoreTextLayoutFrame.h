//
//  DTCoreTextLayoutFrame.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>


#define CGFLOAT_OPEN_HEIGHT 16777215.0f


@class DTCoreTextLayouter;

@interface DTCoreTextLayoutFrame : NSObject 
{
	CGRect _frame;
	CTFrameRef _textFrame;
    CTFramesetterRef _framesetter;
    
	DTCoreTextLayouter *_layouter;
	
	NSArray *_lines;
    NSInteger tag;
}

+ (void)setShouldDrawDebugFrames:(BOOL)debugFrames;

- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter;
- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter range:(NSRange)range;

- (CGPathRef)path;
- (NSRange)visibleStringRange;

- (void)drawInContext:(CGContextRef)context;

- (NSInteger)lineIndexForGlyphIndex:(NSInteger)index;
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;
- (NSArray *)linesVisibleInRect:(CGRect)rect;

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, assign, readonly) DTCoreTextLayouter *layouter;

@property (nonatomic, retain, readonly) NSArray *lines;
@property (nonatomic, assign) NSInteger tag;


@end
