//
//  DTCoreTextGlyphRun.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



#import <CoreText/CoreText.h>

@class DTCoreTextLayoutLine;
@class DTTextAttachment;

@interface DTCoreTextGlyphRun : NSObject 
{
	CTRunRef _run;
	
	CGRect _frame;
	
	CGFloat _offset; // x distance from line origin 
	CGFloat ascent;
	CGFloat descent;
	CGFloat leading;
	CGFloat width;
	
	NSInteger numberOfGlyphs;
	
	const CGPoint *glyphPositionPoints;
	BOOL needToFreeGlyphPositionPoints;
	
	__unsafe_unretained DTCoreTextLayoutLine *_line;	// retain cycle, since these objects are retained by the _line
	__unsafe_unretained NSDictionary *attributes;
    NSArray *stringIndices;
	
	DTTextAttachment *_attachment;
	BOOL _didCheckForAttachmentInAttributes;
	BOOL _didCalculateMetrics;
	
	NSRange _stringRange;
}

- (id)initWithRun:(CTRunRef)run layoutLine:(DTCoreTextLayoutLine *)layoutLine offset:(CGFloat)offset;

- (CGRect)frameOfGlyphAtIndex:(NSInteger)index;
- (CGRect)imageBoundsInContext:(CGContextRef)context;
- (NSRange)stringRange;
- (NSArray *)stringIndices;

- (void)drawInContext:(CGContextRef)context;

- (void)fixMetricsFromAttachment;

@property (nonatomic, assign, readonly) CGRect frame;
@property (nonatomic, assign, readonly) NSInteger numberOfGlyphs;
@property (nonatomic, assign, readonly) NSDictionary *attributes;	// subtle simulator bug - use assign not __unsafe_unretained

@property (nonatomic, assign, readonly) CGFloat ascent;
@property (nonatomic, assign, readonly) CGFloat descent;
@property (nonatomic, assign, readonly) CGFloat leading;
@property (nonatomic, assign, readonly) CGFloat width;

@property (nonatomic, strong) DTTextAttachment *attachment;

@end
