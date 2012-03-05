//
//  DTHTMLDocument.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLParser.h"

@class DTHTMLElement;

typedef void(^DTHTMLAttributedStringBuilderWillFlushCallback)(DTHTMLElement *);

/** Build an attributed string. 
 */
@interface DTHTMLAttributedStringBuilder : NSObject <DTHTMLParserDelegate>

/** Initialize an attributedStringBuilder to build an NSAttributedString from HTML data and CSS options. 

 @param data HTML string stored as UTF8-encoded NSData. 
 @param options CSS options to attribute to this string. 
 @param dict Pointer to documentAttributes dictionary; ignored for now. 
 @returns An initialized DTHTMLAttributedStringBuilder with its data and options set. */
- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;

/** Builds an NSAttributedString from HTML data. Polls the options dictionary to specify styles. 

 @returns If the DTHTMLParser successfully parsed this attributed string. */
- (BOOL)buildString;

/** Return the attributed string. 

 @returns An NSAttributedString constructed from the data and options objects stored in this object. */
- (NSAttributedString *)generatedAttributedString;

/** This block is called before the element is written to the output attributed string. 
 */
@property (nonatomic, copy) DTHTMLAttributedStringBuilderWillFlushCallback willFlushCallback;

@end
