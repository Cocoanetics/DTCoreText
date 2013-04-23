//
//  DTHTMLElementA.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 21.03.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTHTMLElement.h"

/**
 Specialized subclass of <DTHTMLElement> that represents a hyperlink.
 */
@interface DTAnchorHTMLElement : DTHTMLElement

/**
 Foreground text color of the receiver when highlighted
 */
@property (nonatomic, strong) DTColor *highlightedTextColor;

@end
