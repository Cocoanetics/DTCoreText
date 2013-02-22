//
//  DTCoreTextLayouter.h
//  DTCoreText
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

/**
 This class owns an attributed string and is able to create layoutFrames for certain ranges in this string. Optionally it caches these layout frames.
 */
@interface DTCoreTextLayouter : NSObject 

/**
 @name Creating a Layouter
 */

/**
 Designated Initializer. Creates a new Layouter with an attributed string
 @param attributedString The `NSAttributedString` to layout for
 @returns An initialized layouter
 */
- (id)initWithAttributedString:(NSAttributedString *)attributedString;


/**
 @name Creating Layout Frames
*/

/**
 Creates a layout frame with a given rectangle and string range. The layouter fills the layout frame with as many lines as fit. You can query [DTCoreTextLayoutFrame visibleStringRange] for the range the fits and create another layout frame that continues the text from there to create multiple pages, for example for an e-book.
 @param frame The rectangle to fill with text
 @param range The string range to fill, pass {0,0} for the entire string (as much as fits)
 */
- (DTCoreTextLayoutFrame *)layoutFrameWithRect:(CGRect)frame range:(NSRange)range;

/**
 If set to `YES` then the receiver will cache layout frames generated with layoutFrameWithRect:range: for a given rect
 */
@property (nonatomic, assign) BOOL shouldCacheLayoutFrames;


/**
 @name Getting Information
 */

/**
 The attributed string that the layouter currently owns
 */
@property (nonatomic, strong) NSAttributedString *attributedString;

/**
 The internal framesetter of the receiver
 */
@property (nonatomic, readonly) CTFramesetterRef framesetter;

@end
