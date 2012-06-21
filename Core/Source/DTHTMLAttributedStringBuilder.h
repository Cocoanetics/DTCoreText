//
//  DTHTMLAttributedStringBuilder.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLParser.h"

@class DTHTMLElement;

typedef void(^DTHTMLAttributedStringBuilderWillFlushCallback)(DTHTMLElement *);


/**
 Class for building an `NSAttributedString` from an HTML document.
 */
@interface DTHTMLAttributedStringBuilder : NSObject <DTHTMLParserDelegate>

/**
 @name Creating an Attributed String Builder
 */

/**
 Initializes and returns a new `NSAttributedString` object from the HTML contained in the given object and base URL.
 @param data The data in HTML format from which to create the attributed string.
 @param options Specifies how the document should be loaded. Contains values described in “Option keys for importing documents.” 
 @param docAttributes Currently not in used.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)docAttributes;


/**
 @name Generating Attributed Strings
 */

/**
  Creates the attributed string when called the first time.
 @returns An `NSAttributedString` representing the HTML document passed in the initializer.
 */
- (NSAttributedString *)generatedAttributedString;


/**
 This block is called before the element is written to the output attributed string
 */
@property (nonatomic, copy) DTHTMLAttributedStringBuilderWillFlushCallback willFlushCallback;

@end
