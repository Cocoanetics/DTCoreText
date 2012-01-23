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

- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

- (BOOL)parse;
- (void)abortParsing;

- (NSInteger)columnNumber;
- (NSInteger)lineNumber;
- (NSString *)systemID;
- (NSString *)publicID;

@property (nonatomic, readonly, strong) NSError *parserError;
@property (nonatomic, assign) id <DTHTMLParserDelegate> delegate;

@end
