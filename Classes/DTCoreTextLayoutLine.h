//
//  DTCoreTextLine.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>

@class DTCoreTextLayoutFrame;

@interface DTCoreTextLayoutLine : NSObject 
{
	CGRect _frame;
	CTLineRef _line;
	DTCoreTextLayoutFrame * _layoutFrame;
	
	CGPoint _baselineOrigin;
	
	CGFloat ascent;
	CGFloat descent;
	CGFloat leading;
	CGFloat width;
	CGFloat trailingWhitespaceWidth;
	
	NSArray *_glyphRuns;
}

- (id)initWithLine:(CTLineRef)line layoutFrame:(DTCoreTextLayoutFrame *)layoutFrame origin:(CGPoint)origin;

- (NSRange)stringRange;
- (NSInteger)numberOfGlyphs;
- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;
- (CGRect)imageBoundsInContext:(CGContextRef)context;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, retain, readonly) NSArray *glyphRuns;

@property (nonatomic, assign, readonly) CGFloat ascent;
@property (nonatomic, assign, readonly) CGFloat descent;
@property (nonatomic, assign, readonly) CGFloat leading;

@property (nonatomic, assign, readonly) CGPoint baselineOrigin;

@end
