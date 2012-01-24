//
//  DTHTMLParser.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/18/12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTHTMLParser;

@protocol DTHTMLParserDelegate <NSObject>

@optional
- (void)parserDidStartDocument:(DTHTMLParser *)parser;
- (void)parserDidEndDocument:(DTHTMLParser *)parser;
- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict;
- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName;
- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string;
- (void)parser:(DTHTMLParser *)parser foundComment:(NSString *)comment;
- (void)parser:(DTHTMLParser *)parser parseErrorOccurred:(NSError *)parseError;

@end


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
 
 @param An object that is the new delegate. It is not retained. The delegate must conform to the `DTHTMLParserDelegate` Protocol protocol.
 
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
