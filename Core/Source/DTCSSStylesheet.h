//
//  DTCSSStylesheet.h
//  CoreTextExtensions
//
//  Created by Oliver Drobnik on 9/5/11.
//  Copyright (c) 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTHTMLElement;

@interface DTCSSStylesheet : NSObject


// stylesheet initialized with default styles
+ (DTCSSStylesheet *)defaultStyleSheet;

- (id)initWithStyleBlock:(NSString *)css;
- (id)initWithStylesheet:(DTCSSStylesheet *)stylesheet;


// adds styles contained in block to sheet
- (void)parseStyleBlock:(NSString *)css;


// returns merged style for a tag
- (NSDictionary *)mergedStyleDictionaryForElement:(DTHTMLElement *)element;

// merge styles from given stylesheet into this stylesheet
- (void)mergeStylesheet:(DTCSSStylesheet *)stylesheet;

// dictionary of styles
- (NSDictionary *)styles;

@end
