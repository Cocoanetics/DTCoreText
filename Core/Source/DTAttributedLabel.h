//
//  DTAttributedLabel.h
//  DTCoreText
//
//  Created by Brian Kenny on 1/17/13.
//  Copyright (c) 2013 Cocoanetics.com. All rights reserved.
//

#import "DTAttributedTextContentView.h"

/**
 Rich Text replacement for UILabel.
 */

@interface DTAttributedLabel : DTAttributedTextContentView

/**
 The number of lines to display in the receiver
 */
@property(nonatomic, assign) NSInteger numberOfLines;

/**
 The line break mode of the receiver
 */
@property(nonatomic, assign) NSLineBreakMode lineBreakMode;

/**
 The string to append to the visible string in case a trunction occurs
 */
@property(nonatomic, strong) NSAttributedString *truncationString;

@end
