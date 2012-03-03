//
//  NSMutableString+HTML.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 01.02.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//


/**
 Categories needed for modifying mutable strings, as needed for DTCoreText.
 */
@interface NSMutableString (HTML)

/** 
 Removes the trailing whitespace from the receiver. 
 */
- (void)removeTrailingWhitespace;

@end
