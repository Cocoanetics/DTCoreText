//
//  DTHTMLWriter.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 23.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

/**
 Class to generate HTML from `NSAttributedString` instances.
 */
@interface DTHTMLWriter : NSObject

/**
 @name Creating an HTML Writer
 */

/**
 Creates a writer with a given `NSAttributedString` as input
 @param attributedString An attributed string
 */
- (id)initWithAttributedString:(NSAttributedString *)attributedString;

/**
 @name Generating HTML
 */

/**
 Generates a HTML representation of the attributed string
 @returns The generated string
 */
- (NSString *)HTMLString;


/**
 Generates a HTML fragment representation of the attributed string including inlined styles and no html or head elements
 @returns The generated string
 */
- (NSString *)HTMLFragment;

/**
 @name Properties
 */

/**
 If specified then all absolute font sizes (px) will be divided by this value. This is useful if you specified a text size multiplicator when converting HTML to the attributed string you are processing.
 */
@property (nonatomic, assign) CGFloat textScale;

/**
 If YES, preserve whitespaces in HTML by using "Apple-converted-space". Default YES.
 */
@property (nonatomic, assign) BOOL useAppleConvertedSpace;

/**
 The attributed string that the writer is processing.
 */
@property (nonatomic, readonly) NSAttributedString *attributedString;


/**
 The HTML element tag name to use for paragraphs. Defaults to @"p".
 */
@property (nonatomic, strong) NSString *paragraphTagName;

@end
