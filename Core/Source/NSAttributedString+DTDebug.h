//
//  NSAttributedString+DTDebug.h
//  DTCoreText
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The *DTDebug* category contains methods for debugging and dumping attributed strings
 */
@interface NSAttributedString (DTDebug)

- (void)dumpRangesOfAttribute:(id)attribute;

@end
