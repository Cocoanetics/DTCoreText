//
//  DTHTMLAttributedStringBuilder.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <DTFoundation/DTHTMLParser.h>

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
 
 Options can be:
 
 - DTMaxImageSize: the maximum CGSize that a text attachment can fill
 - DTDefaultFontFamily: the default font family to use instead of Times New Roman
 - DTDefaultFontName: the default font face to use instead of Times New Roman
 - DTDefaultFontSize: the default font size to use instead of 12
 - DTDefaultTextColor: the default text color
 - DTDefaultLinkColor: the default color for hyperlink text
 - DTDefaultLinkDecoration: the default decoration for hyperlinks
 - DTDefaultLinkHighlightColor: the color to show while the hyperlink is highlighted
 - DTDefaultTextAlignment: the default text alignment for paragraphs
 - DTDefaultLineHeightMultiplier: The multiplier for line heights
 - DTDefaultFirstLineHeadIndent: The default indent for left margin on first line
 - DTDefaultHeadIndent: The default indent for left margin except first line
 - DTDefaultListIndent: The amount by which lists are indented
 - DTDefaultStyleSheet: The default style sheet to use
 - DTUseiOS6Attributes: use iOS 6 attributes for building (UITextView compatible)
 - DTWillFlushBlockCallBack: a block to be executed whenever content is flushed to the output string
 - DTIgnoreInlineStylesOption: All inline style information is being ignored and only style blocks used
 
 @param data The data in HTML format from which to create the attributed string.
 @param options Specifies how the document should be loaded. Contains values described in NSAttributedString(HTML).
 @param docAttributes Currently not in use.
 @returns Returns an initialized object, or `nil` if the data can’t be decoded.
 */
- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary * __autoreleasing*)docAttributes;


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

/**
 Setting this property to `YES` causes the tree of parse nodes to be preserved until the end of the generation process. This allows to output the HTML structure of the document for debugging.
 */
@property (nonatomic, assign) BOOL shouldKeepDocumentNodeTree;

@end
