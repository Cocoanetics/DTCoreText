//
//  DTCSSStylesheet.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 9/5/11.
//  Copyright (c) 2011 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DTHTMLElement;

/**
 This class represents a CSS style sheet used for specifying formatting for certain CSS selectors.
 
 It supports matching styles by class, by id or by tag name. Hierarchy matching is not supported yet.
 */
@interface DTCSSStylesheet : NSObject <NSCopying>


/**
 @name Creating Stylesheets
 */

/**
 Creates the default stylesheet.
 
 This stylesheet is based on the standard styles that Webkit provides for these tags. This stylesheet is loaded from an embedded copy of default.css.
 */
+ (DTCSSStylesheet *)defaultStyleSheet;


/**
 Creates a stylesheet with a given style block
 
 @param css The CSS string for the style block
 */
- (id)initWithStyleBlock:(NSString *)css;


/**
 @name Working with CSS Style Blocks
 */


/**
 Parses a style block string and adds the found style rules to the receiver.
 
 @param css The CSS string for the style block
*/ 
- (void)parseStyleBlock:(NSString *)css;


/**
 Merges styles from given stylesheet into the receiver
 
 @param stylesheet the stylesheet to merge
 */
- (void)mergeStylesheet:(DTCSSStylesheet *)stylesheet;


/**
 @name Accessing Style Information
 */

/**
 Returns a dictionary that contains the merged style for a given element and the applicable style rules from the receiver.
 
 @param element The HTML element.
 @returns The merged style dictionary containing only styles which selector matches the element
 */
- (NSDictionary *)mergedStyleDictionaryForElement:(DTHTMLElement *)element;


/**
 Returns a dictionary of the styles of the receiver
 */
- (NSDictionary *)styles;

@end
