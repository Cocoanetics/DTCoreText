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

@interface DTHTMLAttributedStringBuilder : NSObject <DTHTMLParserDelegate>

- (id)initWithHTML:(NSData *)data options:(NSDictionary *)options documentAttributes:(NSDictionary **)dict;

- (BOOL)buildString;

- (NSAttributedString *)generatedAttributedString;


// this block is called before the element is written to the output attributed string
@property (nonatomic, copy) DTHTMLAttributedStringBuilderWillFlushCallback willFlushCallback;

@end
