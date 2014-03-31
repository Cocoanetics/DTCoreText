//
//  DTHTMLElementText.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 26.12.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

#import "DTHTMLElement.h"

/**
 Specialized subclass of <DTHTMLElement> that deals with text. It represents a text node. The text inside a DTHTMLElement can consist of any number of such text nodes.
 */

@interface DTTextHTMLElement : DTHTMLElement

/**
 The text content of the element.
 */
@property (nonatomic, strong) NSString *text;

@end
