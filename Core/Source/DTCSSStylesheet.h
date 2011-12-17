//
//  DTCSSStylesheet.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 9/5/11.
//  Copyright (c) 2011 Drobnik.com. All rights reserved.
//



@class DTHTMLElement;

@interface DTCSSStylesheet : NSObject

- (id)initWithStyleBlock:(NSString *)css;
- (id)initWithStylesheet:(DTCSSStylesheet *)stylesheet;


// adds styles contained in block to sheet
- (void)parseStyleBlock:(NSString *)css;


// returns merged style for a tag
- (NSDictionary *)mergedStyleDictionaryForElement:(DTHTMLElement *)element;

// merge styles from given stylesheet into this stylesheet
- (void)mergeStylesheet:(DTCSSStylesheet *)stylesheet;

@end
