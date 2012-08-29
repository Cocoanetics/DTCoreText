//
//  DTCoreTextGlyphRun.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/25/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

@class DTCoreTextLayoutLine;
@class DTTextAttachment;

@interface DTCoreTextGlyphRun : NSObject 
{
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
@property (nonatomic, unsafe_unretained, readonly) NSDictionary *attributes;	// subtle simulator bug - use assign not __unsafe_unretained in 4.2
@property (nonatomic, assign, readonly, getter=isHyperlink) BOOL hyperlink;

@property (nonatomic, assign, readonly) CGFloat ascent;
@property (nonatomic, assign, readonly) CGFloat descent;
@property (nonatomic, assign, readonly) CGFloat leading;
@property (nonatomic, assign, readonly) CGFloat width;

@property (nonatomic, strong) DTTextAttachment *attachment;

@end
