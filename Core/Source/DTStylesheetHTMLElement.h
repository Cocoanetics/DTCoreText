//
//  DTHTMLElementStylesheet.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 29.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLElement.h"

@class DTCSSStylesheet;

/**
 This is a specialized subclass of <DTHTMLElement> representing a style block.
 */
@interface DTStylesheetHTMLElement : DTHTMLElement

/**
 Parses the text children and assembles the resulting stylesheet.
 */
- (DTCSSStylesheet *)stylesheet;

@end
