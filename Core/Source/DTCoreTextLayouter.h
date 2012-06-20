//
//  DTCoreTextLayouter.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 1/24/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//



#if TARGET_OS_IPHONE
#import <CoreText/CoreText.h>
#elif TARGET_OS_MAC
#import <ApplicationServices/ApplicationServices.h>
#endif

#import "DTCoreTextLayoutFrame.h"
#import "DTCoreTextLayoutLine.h"
#import "DTCoreTextGlyphRun.h"


@interface DTCoreTextLayouter : NSObject 

- (id)initWithAttributedString:(NSAttributedString *)attributedString;

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToWidth:(CGFloat)width;

- (NSInteger)numberOfFrames;
- (void)addTextFrameWithFrame:(CGRect)frame;

- (DTCoreTextLayoutFrame *)layoutFrameWithRect:(CGRect)frame range:(NSRange)range;

- (DTCoreTextLayoutFrame *)layoutFrameAtIndex:(NSInteger)index;

@property (nonatomic, strong) NSAttributedString *attributedString;

@property (nonatomic, readonly) CTFramesetterRef framesetter;

@end
