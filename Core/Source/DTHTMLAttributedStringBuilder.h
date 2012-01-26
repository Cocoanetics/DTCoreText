//
//  DTHTMLDocument.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.01.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DTHTMLParser.h"


typedef void(^DTHTMLAttributedStringBuilderElementDidStartCallback)(NSString *elementName, NSDictionary *attributeDict);

@interface DTHTMLAttributedStringBuilder : NSObject <DTHTMLParserDelegate>

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;

- (BOOL)buildString;

- (NSAttributedString *)generatedAttributedString;

@end
