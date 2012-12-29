//
//  DTHTMLElementStylesheet.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 29.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import <DTCoreText/DTCoreText.h>

/**
 This class represents STYLE tags.
 */
@interface DTHTMLElementStylesheet : DTHTMLElement

/**
 Parses the text children and assembles the resulting stylesheet.
 */
- (DTCSSStylesheet *)stylesheet;

@end
