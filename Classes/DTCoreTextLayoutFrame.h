//
//  DTCoreTextLayoutFrame.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>


@class DTCoreTextLayouter;

@interface DTCoreTextLayoutFrame : NSObject 
{
	CGRect _frame;
	CTFrameRef _textFrame;
	DTCoreTextLayouter *_layouter;
	
	NSArray *_lines;
}

- (id)initWithFrame:(CGRect)frame layouter:(DTCoreTextLayouter *)layouter;

- (CGPathRef)path;
- (void)drawInContext:(CGContextRef)context;

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, assign, readonly) DTCoreTextLayouter *layouter;

@property (nonatomic, retain, readonly) NSArray *lines;


@end
