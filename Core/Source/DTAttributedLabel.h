//
//  DTAttributedLabel.h
//  DTCoreText
//
//  Created by Brian Kenny on 1/17/13.
//  Copyright (c) 2013 Cocoanetics.com. All rights reserved.
//

#import "DTCompatibility.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH

#import "DTAttributedTextContentView.h"

/**
 A Rich Text replacement for `UILabel`. It inherits from <DTAttributedTextContentView> and as such you can also set the delegate to provide custom subviews i.e. for images or hyperlinks.
 
 Contrary to DTAttributedTextContentView the intrinsicContentSize is only as wide as the text content. To shrink the DTAttributedLabel to that call -sizeToFit.
 */

@interface DTAttributedLabel : DTAttributedTextContentView

/**
 @name Setting Attributes
 */

/**
 The number of lines to display in the receiver
 */
@property(nonatomic, assign) NSInteger numberOfLines;

/**
 The line break mode of the receiver
 */
@property(nonatomic, assign) NSLineBreakMode lineBreakMode;

/**
 The string to append to the visible string in case a truncation occurs
 */
@property(nonatomic, strong) NSAttributedString *truncationString;

@end

#endif
