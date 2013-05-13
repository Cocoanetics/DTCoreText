//
//  DTCoreTextParagraphStyle.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 4/14/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

/**
 `DTCoreTextParagraphStyle` encapsulates the paragraph or ruler attributes used by the NSAttributedString classes on iOS. It is a replacement for `NSParagraphStyle` which is not implemented on iOS. 
 
 Since `NSAttributedString` instances use CTParagraphStyle object there are methods to bridge from and to these. Because of this distinction there is no need for a mutable variant of this class.
 */
@interface DTCoreTextParagraphStyle : NSObject <NSCopying>

/**
 @name Creating a DTCoreTextParagraphStyle
 */

/**
 Returns the default paragraph style.
 */
+ (DTCoreTextParagraphStyle *)defaultParagraphStyle;



/**
 @name Bridging to and from CTParagraphStyle
 */

/**
 Create a new paragraph style instance from a `CTParagraphStyle`.
 
 @param ctParagraphStyle the `CTParagraphStyle` from which to copy this new style's attributes.
 */
+ (DTCoreTextParagraphStyle *)paragraphStyleWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle;


/**
 Create a new paragraph style instance from a `CTParagraphStyle`.
 
 @param ctParagraphStyle the `CTParagraphStyle` from which to copy this new style's attributes.
 */
- (id)initWithCTParagraphStyle:(CTParagraphStyleRef)ctParagraphStyle;

/**
 Create a new `CTParagraphStyle` from the receiver for use as attribute in `NSAttributedString`
 
 @returns The `CTParagraphStyle` based on the receiver's attributes.
 */
- (CTParagraphStyleRef)createCTParagraphStyle;

/**
 @name Bridging to and from NSParagraphStyle
 */

#if DTCORETEXT_SUPPORT_NS_ATTRIBUTES
/**
 Create a new paragraph style instance from an `NSParagraphStyle`.
 
 Note: on iOS no tab stops are supported.
 @param paragraphStyle the `NSParagraphStyle` from which to copy this new style's attributes.
 */
+ (DTCoreTextParagraphStyle *)paragraphStyleWithNSParagraphStyle:(NSParagraphStyle *)paragraphStyle;

/**
 Create a new `NSParagraphStyle` from the receiver for use as attribute in `NSAttributedString`. 
 
 Note: This method is requires iOS 6 or greater. This does not support tab stops.
 
 @returns The `NSParagraphStyle` based on the receiver's attributes.
 */
- (NSParagraphStyle *)NSParagraphStyle;
#endif


/**-------------------------------------------------------------------------------------
 @name Accessing Style Information
 ---------------------------------------------------------------------------------------
 */

/**
 The indentation of the first line of the receiver.
 */
@property (nonatomic, assign) CGFloat firstLineHeadIndent;


/**
  The document-wide default tab interval.
 
 The default tab interval in points. Tabs after the last specified in tabStops are placed at integer multiples of this distance (if positive). Default return value is 0.0.
 */
@property (nonatomic, assign) CGFloat defaultTabInterval;


/**
 The distance between the paragraph’s top and the beginning of its text content.
 */
@property (nonatomic, assign) CGFloat paragraphSpacingBefore;


/**
 The space after the end of the paragraph. 
 */
@property (nonatomic, assign) CGFloat paragraphSpacing;


/**
 The line height multiple.
 
 Internally line height multiples get converted into minimum and maximum line height.
 */
@property (nonatomic, assign) CGFloat lineHeightMultiple;


/**
 The minimum height in points that any line in the receiver will occupy, regardless of the font size or size of any attached graphic. This value is always nonnegative.
 */
@property (nonatomic, assign) CGFloat minimumLineHeight;


/**
 The maximum height in points that any line in the receiver will occupy, regardless of the font size or size of any attached graphic. This value is always nonnegative. The default value is 0.
 */
@property (nonatomic, assign) CGFloat maximumLineHeight;


/**
The distance in points from the margin of a text container to the end of lines. 
 
 @note This value is negative if it is to be measured from the trailing margin, positive if measured from the same margin as the headIndent.
 */
@property (nonatomic, assign) CGFloat tailIndent;

/**
 The distance in points from the leading margin of a text container to the beginning of lines other than the first. This value is always nonnegative.
 */
@property (nonatomic, assign) CGFloat headIndent;

/**
 The text alignment of the receiver.

 Natural text alignment is realized as left or right alignment depending on the line sweep direction of the first script contained in the paragraph.
 */
@property (nonatomic, assign) CTTextAlignment alignment;


/**
 The base writing direction for the receiver.
 
*/
@property (nonatomic, assign) CTWritingDirection baseWritingDirection;


/**-------------------------------------------------------------------------------------
 @name Setting Tab Stops
 ---------------------------------------------------------------------------------------
 */

/**
 The CTTextTab objects, sorted by location, that define the tab stops for the paragraph style.
 */
@property (nonatomic, copy) NSArray *tabStops;


/**
  Adds a tab stop to the receiver.
 
 @param position the tab stop position
 @param alignment the tab alignment for this tab stop
 */
- (void)addTabStopAtPosition:(CGFloat)position alignment:(CTTextAlignment)alignment;


/**-------------------------------------------------------------------------------------
 @name Interacting with CSS
 ---------------------------------------------------------------------------------------
 */

/**
 Create a representation suitable for CSS.
 
 @returns A string with the receiver's style encoded as CSS.
 */
- (NSString *)cssStyleRepresentation;


/**-------------------------------------------------------------------------------------
 @name Setting Text Lists
 ---------------------------------------------------------------------------------------
 */

/** 
 Text lists containing the paragraph, nested from outermost to innermost, to array.
*/
@property (nonatomic, copy) NSArray *textLists;


/**-------------------------------------------------------------------------------------
 @name Setting Text Blocks
 ---------------------------------------------------------------------------------------
 */

/** 
 Text lists containing the paragraph, nested from outermost to innermost, to array.
 */
@property (nonatomic, copy) NSArray *textBlocks;


@end
