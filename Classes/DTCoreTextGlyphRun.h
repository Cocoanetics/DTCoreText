//
//  DTCoreTextGlyphRun.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreText/CoreText.h>

@class DTCoreTextLayoutLine;

@interface DTCoreTextGlyphRun : NSObject 
{
	CTRunRef _run;
	
	CGRect _frame;
	CGPoint _baselineOrigin;
	
	CGFloat ascent;
	CGFloat descent;
	CGFloat leading;
	CGFloat width;
	
	NSInteger numberOfGlyphs;
	
	const CGPoint *glyphPositionPoints;
	
	DTCoreTextLayoutLine *_line;
	NSDictionary *attributes;
}

- (id)initWithRun:(CTRunRef)run layoutLine:(DTCoreTextLayoutLine *)layoutLine origin:(CGPoint)origin;

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;
- (CGRect)imageBoundsInContext:(CGContextRef)context;
- (NSRange)stringRange;

- (void)drawInContext:(CGContextRef)context;

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, assign, readonly) NSInteger numberOfGlyphs;
@property (nonatomic, assign, readonly) NSDictionary *attributes;

@property (nonatomic, assign, readonly) CGFloat ascent;
@property (nonatomic, assign, readonly) CGFloat descent;
@property (nonatomic, assign, readonly) CGFloat leading;

@property (nonatomic, assign, readonly) CGPoint baselineOrigin;


@end
