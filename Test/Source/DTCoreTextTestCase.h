//
//  DTCoreTextTestCase.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 25.09.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoretext.h"


/**
 Specialized test case class for testing DTCoreText issues
 */
@interface DTCoreTextTestCase : XCTestCase

/**
 @name Utilities
 */

/**
 Parse the HTML in the file with the give name
 @param testFileName The name of the test file in the OCTest bundle
 @returns the attributed string, generated with DTCoreText
 */
- (NSAttributedString *)attributedStringFromTestFileName:(NSString *)testFileName;

/**
 Parses the HTML in the given string with the optional options
 @param HTMLString The HTML string to parse with DTCoreText
 @param options The parsing options
 @returns the attributed string, generated with DTCoreText
 */
- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)HTMLString options:(NSDictionary *)options;

@end
