//
//  DTHTMLParser.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/18/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTHTMLParser;
/** The DTHTMLParserDelegate protocol defines the optional methods implemented by delegates of DTHTMLParser objects. 
 */
@protocol DTHTMLParserDelegate <NSObject>

@optional

/**
 Sent by the parser object to the delegate when it begins parsing a document.
 
 @param parser A parser object.
 */
- (void)parserDidStartDocument:(DTHTMLParser *)parser;

/**
 Sent by the parser object to the delegate when it has successfully completed parsing
 
 @param parser A parser object.
 */
- (void)parserDidEndDocument:(DTHTMLParser *)parser;

/**
 Sent by a parser object to its delegate when it encounters a start tag for a given element.
 
 @param parser A parser object.
 @param elementName A string that is the name of an element (in its start tag).
 @param attributeDict A dictionary that contains any attributes associated with the element. Keys are the names of attributes, and values are attribute values.
 */
- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;

/**
 Sent by a parser object to its delegate when it encounters an end tag for a specific element.
 
 @param parser A parser object.
 @param elementName A string that is the name of an element (in its end tag).
 */
- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName;

/**
 Sent by a parser object to provide its delegate with a string representing all or part of the characters of the current element.
 
 The parser object may send the delegate several parser:foundCharacters: messages to report the characters of an element. Because string may be only part of the total character content for the current element, you should append it to the current accumulation of characters until the element changes.
 
 @param parser A parser object.
 @param string A string representing the complete or partial textual content of the current element.
 */
- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string;

/**
 Sent by a parser object to its delegate when it encounters a comment in the HTML.
 
 @param parser A DTHTMLParser object parsing HTML.
 @param comment A string that is a the content of a comment in the XML.
 */
- (void)parser:(DTHTMLParser *)parser foundComment:(NSString *)comment;

/**
 Sent by a parser object to its delegate when it encounters a CDATA block. 
 
 Through this method the parser object passes the contents of the block to its delegate in an NSData object. The CDATA block is character data that is ignored by the parser. The encoding of the character data is UTF-8. To convert the data object to a string object, use the NSString method initWithData:encoding:. Note: CSS style blocks are returned as CDATA.
 
 @param parser A DTHTMLParser object parsing HTML.
 @param CDATABlock A data object containing a block of CDATA.
 */
- (void)parser:(DTHTMLParser *)parser foundCDATA:(NSData *)CDATABlock;

/**
 Sent by a parser object to its delegate when it encounters a fatal error.
 
 When this method is invoked, parsing is stopped. For further information about the error, you can query parseError or you can send the parser a parserError message. You can also send the parser lineNumber and columnNumber messages to further isolate where the error occurred. Typically you implement this method to display information about the error to the user.
 
 @param parser A parser object.
 @param parseError An `NSError` object describing the parsing error that occurred.
 */
- (void)parser:(DTHTMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end

/** Instances of this class parse HTML documents (including DTD declarations) in an event-driven manner. A DTHTMLParser notifies its delegate about the items (elements, attributes, CDATA blocks, comments, and so on) that it encounters as it processes an HTML document. It does not itself do anything with those parsed items except report them. It also reports parsing errors. For convenience, an DTHTMLParser object in the following descriptions is sometimes referred to as a parser object.
 */
@interface DTHTMLParser : NSObject

/**-------------------------------------------------------------------------------------
 @name Initializing a Parser Object
 ---------------------------------------------------------------------------------------
 */

/**
 Initializes the receiver with the HTML contents encapsulated in a given data object.
 
 @param data An `NSData` object containing XML markup.
 @param encoding The encoding used for encoding the HTML data
 @returns An initialized `DTHTMLParser` object or nil if an error occurs. 
 */
- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

/**-------------------------------------------------------------------------------------
 @name Parsing
 ---------------------------------------------------------------------------------------
 */

/**
 Starts the event-driven parsing operation.
 
 If you invoke this method, the delegate, if it implements parser:parseErrorOccurred:, is informed of the cancelled parsing operation.
 
 @returns `YES` if parsing is successful and `NO` in there is an error or if the parsing operation is aborted. 
 */
- (BOOL)parse;

/**
 Stops the parser object.
 
 @see parse
 @see parserError
 */
- (void)abortParsing;

/**
 Sets the receiver’s delegate.
 
 @param delegate An object that is the new delegate. It is not retained. The delegate must conform to the `DTHTMLParserDelegate` Protocol protocol.
 
 @see delegate
 */
- (void)setDelegate:(id <DTHTMLParserDelegate>)delegate;

/**
 Returns the receiver’s delegate.
 
 @see delegate
 */
- (id <DTHTMLParserDelegate>)delegate;

/**
 Returns the column number of the XML document being processed by the receiver.
 
 The column refers to the nesting level of the HTML elements in the document. You may invoke this method once a parsing operation has begun or after an error occurs.
 */
@property (nonatomic, readonly) NSInteger columnNumber;

/**
 Returns the line number of the HTML document being processed by the receiver.
 
 You may invoke this method once a parsing operation has begun or after an error occurs.
 */
@property (nonatomic, readonly) NSInteger lineNumber;

/**
 Returns an `NSError` object from which you can obtain information about a parsing error.
 
 You may invoke this method after a parsing operation abnormally terminates to determine the cause of error.
 */
@property (nonatomic, readonly, strong) NSError *parserError;

/**
 Returns the public identifier of the external entity referenced in the HTML document.
 
 You may invoke this method once a parsing operation has begun or after an error occurs.
 */
@property (nonatomic, readonly) NSString *publicID;

/**
 Returns the system identifier of the external entity referenced in the HTML document.
 
 You may invoke this method once a parsing operation has begun or after an error occurs.
 */
@property (nonatomic, readonly) NSString *systemID;

@end
